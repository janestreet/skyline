(** An input component for fixed-format strings like "YYYY-MM-DD" or "hh:mm". Each segment
    is a separate ["spinbutton"] element supporting typed entry, ArrowUp/Down
    increment/decrement, Backspace/Delete clearing, and ArrowLeft/Right navigation between
    segments. *)

open! Core
open! Bonsai_web
module Keyboard_code = Vdom_keyboard.Keyboard_event.Keyboard_code

module Segment_state : sig
  (** The state of a single segment. Tracks a string value and whether the user has
      started typing (used to decide whether the next keystroke replaces or appends). *)

  type t =
    { state : [ `Nothing_typed | `Something_typed ]
    ; value : string option
    }
  [@@deriving sexp_of]

  module Action : sig
    type t =
      | Start_editing
      | Set_value of (string option -> string option)
      | Append_value of string
  end
end

module Segment_spinbutton : sig
  (** A single segment of a formatted input (e.g. the "HH" part of "HH:MM"). Bundles the
      segment's configuration, state machine, and focus handle. *)

  module Config : sig
    type t [@@deriving sexp_of]

    (** Makes a config for a spinbutton.

        - [placeholder] — Text shown when the segment has no value (e.g. ["HH"], ["MM"]).
          Values are padded or truncated to match the width of the placeholder.
        - [aria_label] — Accessible label for the spinbutton role, e.g. ["hours"],
          ["minutes"].
        - [display] — Prepare an entered value for display. Handles partial inputs — e.g.
          for an ["HH"] field and a string ["3"], padding is applied to produce ["03"].
        - [handle_append_keycode] — Map a keyboard code for an alphanumeric character to a
          string to append to the segment's current value. Return [None] to ignore the
          keystroke.
        - [jump_one_up] — Value when pressing ArrowUp. [None] input means the segment is
          empty.
        - [jump_one_down] — Value when pressing ArrowDown. [None] input means the segment
          is empty.
        - [jump_page_up] — Optionally provides a value when pressing PageUp. [None] input
          means the segment is empty.
        - [jump_page_down] — Optionally provides a value when pressing PageDown. [None]
          input means the segment is empty.
        - [jump_page_top] — Optionally provides a value when pressing Home.
        - [jump_page_bottom] — Optionally provides a value when pressing End. *)
    val make
      :  placeholder:string
      -> aria_label:string
      -> display:(string -> string)
      -> handle_append_keycode:(Keyboard_code.t -> string option)
      -> jump_one_up:(string option -> string)
      -> jump_one_down:(string option -> string)
      -> ?jump_page_up:(string option -> string)
      -> ?jump_page_down:(string option -> string)
      -> ?jump_top:(unit -> string)
      -> ?jump_bottom:(unit -> string)
      -> unit
      -> t

    (** Makes a config for a spinbutton with numeric values.

        - [placeholder] — Text shown when the segment has no value (e.g. ["HH"], ["MM"]).
          Values are padded or truncated to match the width of the placeholder.
        - [aria_label] — Accessible label for the spinbutton role, e.g. ["hours"],
          ["minutes"].
        - [min] — Minimum value allowed for the segment.
        - [max] — Maximum value allowed for the segment.
        - [step] — Amount to increment/decrement when pressing PageUp/PageDown.
        - [default] — Optional value to set when incrementing/decrementing an empty
          segment *)
    val make_numeric
      :  placeholder:string
      -> aria_label:string
      -> min:int
      -> max:int
      -> step:int
      -> ?default:int
      -> unit
      -> t

    module For_testing : sig
      (** Wraps into the inclusive interval [min, max]. [min] and [max] must be both
          nonnegative. *)
      val wrap_inclusive : min:int -> max:int -> int -> int
    end
  end

  type t =
    { state : Segment_state.t
    ; apply_action : Segment_state.Action.t -> string option Effect.t
    ; focus : unit Effect.t
    ; focus_attr : Vdom.Attr.t
    ; config : Config.t
    }
  [@@deriving sexp_of]

  val create : Config.t -> local_ Bonsai.graph -> t Bonsai.t
end

module Content : sig
  type t

  (** A segment spinbutton input. Handles keystroke entry, backspace/delete, ArrowUp/Down
      increment/decrement, and ArrowLeft/Right navigation between segments.

      This element has the ["spinbutton"] ARIA role. *)
  val segment : ?attrs:Vdom.Attr.t list -> segment:Segment_spinbutton.t -> unit -> t

  (** A text delimiter rendered between segments (e.g. [":"] or ["-"]). Does not
      participate in focus navigation. *)
  val delimiter : char:char -> unit -> t
end

module Action_element : sig
  (** An interactive element that participates in focus navigation (e.g. a calendar icon
      button). [on_activate] fires on click and Space keypress. Arrow keys and Escape
      navigate to adjacent segments. *)
  type t

  val content
    :  on_activate:unit Effect.t
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> t
end

module Hidden_element : sig
  (** Arbitrary static vdom content that should be styled as visually hidden (e.g. a
      hidden [<input>]). Does not participate in focus navigation. *)
  type t

  val content : Vdom.Node.t list -> t
end

(** Render a segmented input. The [Content.t list] defines the layout: segments,
    delimiters, and action elements in the order they should appear. Keyboard navigation
    (arrow keys) moves focus between segments and action elements in list order. *)
val view
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?disabled:bool
  -> ?action_element:Action_element.t
  -> ?hidden_element:Hidden_element.t
  -> Content.t list
  -> Vdom.Node.t

module State : sig
  (** Controlled state for a segmented input. Manages bidirectional synchronization
      between the individual spinbutton segment values and a parsed domain value of type
      ['a option].

      When the user types into segments, the domain value is re-derived via [parse]. When
      the external value changes, the segments are updated via [unparse]. *)

  type ('s, 'a) t =
    { spinbuttons : 's
    ; value : 'a option
    }
  [@@deriving sexp_of]

  (** Create controlled state for a segmented input.

      - [spinbuttons] — a single [Bonsai.t] containing the caller's spinbutton structure
        (e.g. a labeled tuple). The caller combines individual spinbutton [Bonsai.t]s into
        one via [let%arr].
      - [parse] — derive a domain value from the resolved spinbuttons. Returns [None] if
        the segments don't form a valid value.
      - [unparse] — given the resolved spinbuttons and a new domain value ([None] to
        clear), produce an effect that sets each spinbutton's value accordingly.
      - [equal] — equality on ['a option], used by the mirror to detect changes.
      - [state] — optional external value/setter pair for controlled mode. If omitted, an
        internal [Bonsai.state_opt] is created. *)
  val create
    :  spinbuttons:'s Bonsai.t
    -> parse:('s -> 'a option)
    -> unparse:('s -> 'a option -> unit Effect.t)
    -> equal:('a option -> 'a option -> bool)
    -> ?state:'a option Bonsai.t * ('a option -> unit Effect.t) Bonsai.t
    -> local_ Bonsai.graph
    -> ('s, 'a) t Bonsai.t
end
