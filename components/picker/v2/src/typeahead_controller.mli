open! Core
open Bonsai_web

module Selection_mode : sig
  (** Controls how the controller tracks selection and what payload is delivered to
      [on_select]. *)
  type ('a, 'selection, 'on_select_payload) t =
    | Single_ux :
        { comparator :
            (module Comparator.S with type t = 'a and type comparator_witness = 'cmp)
        }
        -> ('a, 'a option, 'a option) t
    (** Standard behavior. The controller stores the selected item as an ['a option],
        shows that selection in the input, and [on_select] receives the selected item as
        an ['a option]. *)
    | Effect_only : ('a, unit, 'a) t
    (** Stateless "search and act" behavior. The controller does not retain a selected
        item, resets the input after each selection, and [on_select] receives the selected
        item directly as an ['a]. *)
    | Multi_ux :
        { comparator :
            (module Comparator.S with type t = 'a and type comparator_witness = 'cmp)
        }
        -> ('a, 'a list, 'a list) t
    (** Multi-select behavior. The controller stores a list of selected items and toggles
        items on each selection (adding if absent, removing if already selected). The
        popover stays open after each selection so the user can continue picking.
        [on_select] receives the full list after each toggle. *)

  type ('a, 'selection) packed = T : ('a, 'selection, _) t -> ('a, 'selection) packed

  (** Convenience constructor for [Single_ux]. *)
  val single_ux
    :  (module Comparator.S with type t = 'a and type comparator_witness = 'cmp)
    -> ('a, 'a option, 'a option) t

  (** Convenience constructor for [Multi_ux]. *)
  val multi_ux
    :  (module Comparator.S with type t = 'a and type comparator_witness = 'cmp)
    -> ('a, 'a list, 'a list) t
end

(** Stateful controller for typeahead inputs. Owns query state, open/close state, the
    popover, the focusable list, and filtering. Created via [component], consumed by
    [Skyline.Typeahead.Combobox_input.content] and
    [Skyline.Typeahead.Select_input.content]. *)
type ('a, 'selection) t

module Highlighted_splits = Highlighted_splits

(** Creates a typeahead controller.

    - [~selection_mode] - controls how selections are tracked. [Single_ux] saves the
      selected item and updates the input text. [Effect_only] does not save any selection
      and resets the input after each selection. Use [Effect_only] when the selection is
      immediately handled in an effect (e.g. by updating some external state) and the
      component should reset after each selection.
    - [?on_select] - effect run whenever the user selects an item. The payload depends on
      the selection mode; see [Selection_mode] for more information.
    - [?state] - a [(selected, set_selected)] pair. Use this if you need a controlled
      selection state, e.g. if the selection must live outside the component.
    - [?open_state] - a [(is_open, set_is_open)] pair for the popover open/closed state.
      Same controlled/uncontrolled semantics as [?state].
    - [~to_string] - converts items to the text shown in the input after selection and
      when arrowing through suggestions. Also used for the default [render_suggestion].
    - [~data] - source of suggestions, either local or RPC-backed
    - [?render_popover_contents] - wraps the suggestions list inside the combobox and
      select popovers. When omitted, the suggestions list is rendered directly. For the
      combobox-style anchor, the text input that opens the popover lives outside the
      popover and closes it on blur. Any custom interactive content in the popover (e.g.
      toolbar buttons) should set [Attr.on_mousedown] to call [evt##preventDefault];
      otherwise clicking the element will blur the anchor input and close the popover
      before the click handler fires. The select-style anchor's search input is inside the
      popover, so it isn't affected. *)
val component
  :  selection_mode:('a, 'selection, 'on_select_payload) Selection_mode.t
  -> ?state:'selection Bonsai.t * ('selection -> unit Effect.t) Bonsai.t
  -> ?open_state:bool Bonsai.t * (bool -> unit Effect.t) Bonsai.t
  -> ?on_select:('on_select_payload -> unit Effect.t) Bonsai.t
  -> to_string:('a -> string)
  -> data:'a Typeahead_data_source.t
  -> ?render_suggestion:
       ('a -> highlight:(string -> Highlighted_splits.t) -> Vdom.Node.t) Bonsai.t
  -> ?render_popover_contents:(Vdom.Node.t -> Vdom.Node.t) Bonsai.t
  -> Bonsai.graph @ local
  -> ('a, 'selection) t Bonsai.t

(** The current selection and its setter.

    The setter is a pure state update: it does not close the popover or fire [on_select].
    Use this setter for programmatic state writes (e.g. a "clear all" or "set preset"
    button). *)
val state : ('a, 'selection) t -> 'selection * ('selection -> unit Effect.t)

(** Library-private APIs consumed by [Typeahead_combobox_input] and
    [Typeahead_select_input]. *)
module Private : sig
  (** The [to_string] function passed to [component]. Useful for rendering selected items
      in view components. *)
  val to_string : ('a, _) t -> 'a -> string

  (** Remove a single item from a [Multi_ux] selection. Only available for [Multi_ux]
      controllers (enforced by the ['a list] constraint). *)
  val deselect_item : ('a, 'a list) t -> 'a -> unit Effect.t

  (** The selection mode for the controller. *)
  val selection_mode : ('a, 'selection) t -> ('a, 'selection) Selection_mode.packed

  (** For combobox-style anchors where the text input is the anchor. Includes anchor-aware
      autoclose (clicking the anchor does not close the popover) and renders the
      suggestion list. *)
  val for_combobox_anchor : (_, _) t -> Vdom.Attr.t

  (** The input state pair [(value, set_value)] for combobox-style anchors. Pass this as
      [~state] to [Skyline_text_input_v2.Composite.input]. *)
  val combobox_input_state : (_, _) t -> string * (string -> unit Effect.t)

  (** Interaction attrs for combobox-style anchors. Handles keyboard navigation (arrow
      keys, Enter, Escape), click-to-open, and blur-to-close-and-reset. Attach this to the
      text input element inside the anchor (e.g. via [~attrs] on
      [Skyline_text_input_v2.Composite.input]). Does not include value binding or
      on_input; those are provided by {!combobox_input_state}.

      [~on_backspace_when_empty] is the effect to fire when the user presses Backspace
      with an empty input. Callers that want the default "remove the rightmost chip"
      behavior should pass [deselect_last]. Backspace while the input has text always
      falls through to normal text editing.

      [?on_arrow_left_at_start] fires when the user presses ArrowLeft with the cursor at
      the beginning of the text input. It is intended for callers that want to move focus
      into a preceding element (e.g. the rightmost selection chip) when the user tries to
      "walk off the left edge" of the input. *)
  val for_combobox_input
    :  on_backspace_when_empty:unit Effect.t
    -> ?on_arrow_left_at_start:unit Effect.t
    -> (_, _) t
    -> Vdom.Attr.t

  (** Imperatively focus the combobox text input. The focus hook is included in
      [for_combobox_input]. *)
  val focus_combobox_input : (_, _) t -> unit Effect.t

  (** For select-style anchors where a button is the anchor. Renders a search input with a
      hard-coded ["Search..."] placeholder above the suggestion list. Includes
      click-outside autoclose behavior. *)
  val for_select_anchor : (_, _) t -> Vdom.Attr.t

  (** The Bonsai path id for the controller's state. Useful for scoping DOM queries (e.g.
      via data attributes) to a specific controller instance. *)
  val path_id : (_, _) t -> string

  (** Removes the most recent item from the selection. For [Single_ux] this clears the
      selection; for [Multi_ux] it drops the rightmost chip; for [Effect_only] it is
      [Effect.Ignore]. This is the typical value to pass as [~on_backspace_when_empty]. *)
  val deselect_last : (_, _) t -> unit Effect.t
end

module For_testing : sig
  (** The current query string shown in the text input. *)
  val query : (_, _) t -> string

  (** Imperatively open the popover. *)
  val open_ : (_, _) t -> unit Effect.t
end

module For_docs : sig
  val ml_filepath : string
end
