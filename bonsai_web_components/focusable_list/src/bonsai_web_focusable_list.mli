(** A focusable list with roving tabindex.

    Roving tabindex means the focusable item has [tabindex="0"] while all other items have
    [tabindex="-1"]. This allows keyboard navigation within the list while maintaining
    proper tab order with elements outside the list.

    The library tracks:
    - Which item is "focusable" (has tabindex=0)
    - Whether the list currently has DOM focus (via focusin/focusout events)

    When the list is non-empty, exactly one item is always focusable. Navigation actions
    like [Next] and [Prev] move both the focusable marker and DOM focus together.

    Programmatic [.focus()] calls only occur when the list has focus - this prevents
    stealing focus when items are removed while the user has tabbed elsewhere. *)

open! Core
open! Bonsai_web

module Action : sig
  type 'id t =
    | Focus of 'id
    | Next
    | Prev
    | First
    | Last
  [@@deriving sexp_of, equal]
end

type 'id t

(** [focusable t] Returns the currently focusable item (the one with tabindex=0), or
    [None] if the list is empty. When the list is non-empty, this always returns [Some]. *)
val focusable : 'id t -> 'id option

(** [has_focus t] Returns whether a row currently has DOM focus. *)
val has_focus : 'id t -> bool

(** [create ids graph] constructs a focusable list state machine.

    - [?wrap_around]: wrap at list boundaries (default [false])
    - [ids]: the array of ids; watched for changes. Behavior is undefined for duplicate
      IDs.

    Returns the state and an inject function for dispatching actions. *)
val create
  :  ?wrap_around:bool Bonsai.t
  -> (module Comparable.S_plain with type t = 'id)
  -> 'id Iarray.t Bonsai.t
  -> local_ Bonsai.graph
  -> 'id t Bonsai.t * ('id Action.t -> 'id option Effect.t) Bonsai.t

(** [item_attr t] returns a function to build per-item attributes.

    Each item receives:
    - [tabindex] (0 if focusable, -1 otherwise)
    - click-to-focus handler
    - DOM ref tracking for programmatic focus *)
val item_attr : 'id t Bonsai.t -> ('id -> Vdom.Attr.t) Bonsai.t

(** [container_attr t] returns an attr that should be placed on the item's container. All
    focusable elements within the container should be managed via [Focusable_list]

    It is responsible for determining if container has focus and should therefore
    programmatically call .focus() on actions like Next/Prev. *)
val container_attr : 'id t -> Vdom.Attr.t

module For_testing : sig
  val ascii_render : 'id t -> ids:'id iarray -> to_string:('id -> string) -> string
end
