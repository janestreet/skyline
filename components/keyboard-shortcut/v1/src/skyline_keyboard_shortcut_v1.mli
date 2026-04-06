open! Core
open! Bonsai_web

module Modifier_status : sig
  (** Status of a given shortcut, that can be used to e.g. conditionally draw a label for
      the keyboard shortcut. *)
  type t =
    | Idle
    | Show_indicator
  [@@deriving sexp_of]
end

module Modifier : sig
  type t =
    [ `Alt
    | `Ctrl
    | `Shift
    ]
  [@@deriving sexp_of, compare, equal]

  val to_string : t -> string
end

module Key : sig
  type t =
    [ `A
    | `B
    | `C
    | `D
    | `E
    | `F
    | `G
    | `H
    | `I
    | `J
    | `K
    | `L
    | `M
    | `N
    | `O
    | `P
    | `Q
    | `R
    | `S
    | `T
    | `U
    | `V
    | `W
    | `X
    | `Y
    | `Z
    | `Digit_1
    | `Digit_2
    | `Digit_3
    | `Digit_4
    | `Digit_5
    | `Digit_6
    | `Digit_7
    | `Digit_8
    | `Digit_9
    | `Digit_0
    | `Forward_slash
    | `Period
    | `Arrow_up
    | `Arrow_down
    | `Arrow_left
    | `Arrow_right
    | `Backspace
    | `Enter
    | `Esc
    | `Space
    ]
  [@@deriving sexp_of, compare, equal]

  val to_string : t -> string
end

type t = Modifier.t * Key.t [@@deriving sexp_of, compare, equal]

(** Install a keyboard event listener on the given DOM computation. This computation will
    then act as a "boundary", collecting keybindings collected via [listen] calls inside
    it.

    Most apps will typically have only have the default installed listener boundary at the
    top-level computation, but nesting multiple listeners is possible (e.g. if you want to
    attach keyboard shortcuts like [`Ctrl + `S] to only a single text-input box, you can
    install a keyboard listener on the input box.).

    Listeners that are attached closest (in the DOM tree above the element that triggered
    the keyboard event) take priority when a shortcut matches (i.e. when a shortcut
    matches the event stops bubbling up the DOM tree).

    If multiple matching shortcuts are registered with the same listener, or multiple
    listeners are installed on the same DOM node, all matching shortcuts will be
    triggered. *)
val install_listener_for_computation
  :  (local_ Bonsai.graph -> Vdom.Node.t Bonsai.t)
  -> local_ Bonsai.graph
  -> Vdom.Node.t Bonsai.t

(** Register a keyboard shortcut for a single key only with the current listener installed
    with [install_listener_for_computation]. *)
val register'
  :  ?ignore_modifier:bool Bonsai.t
  -> effect:unit Effect.t Bonsai.t
  -> Key.t Bonsai.t
  -> local_ Bonsai.graph
  -> Modifier_status.t Bonsai.t

(** Register a keyboard shortcut with the current listener installed with
    [install_listener_for_computation]. If the current computation has no active listener,
    this has no effect.

    The returned status indicates if the modifier for the given shortcut is pressed, such
    that e.g. an indicator could be drawn to make the shortcuts more discoverable.

    Shortcuts are only active while their computation is active. This means that you can
    use e.g. [match%sub] to conditionally enable / disable shortcuts. *)
val register
  :  effect:unit Effect.t Bonsai.t
  -> t Bonsai.t
  -> local_ Bonsai.graph
  -> Modifier_status.t Bonsai.t
