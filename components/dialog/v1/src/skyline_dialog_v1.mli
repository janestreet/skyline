open! Core
open! Bonsai_web

(** Dialog elements, also sometimes called modal elements, are a UI element that presents
    some screen above the page contents, making the page contents inaccessible to the user
    while the dialog is active.

    They are most commonly used for alerts or confirm interactions, but can also be used
    to provide custom content like a command pallet, or form to complete some complex
    action. *)

module Position : sig
  (** Determine where on the screen to position the dialog element. *)
  type t =
    | Top
    | Center
  [@@deriving sexp_of, compare, equal]
end

module Restore_focus_on_close : sig
  type t =
    | No
    | Yes of { prevent_scroll : bool }
  [@@deriving sexp_of, compare, equal]
end

(** Render a modal unconditionally (allowing callers to decide when the modal is open).

    [close] is an effect that should stop displaying this modal.

    Note that the modal might also be dismissed by the users in some way, e.g. by pressing
    [Esc].

    [position] can be used to determine where the modal is placed on screen while visible
    and defaults to [Center].

    [close_on_click_outside] determines if the modal closes when the user clicks outside
    of it and is [false] by default.

    [close_on_esc] determines if the modal closes when the user hits the esc key and is
    [true] by default as defined in Toplayer *)
val component
  :  ?test_selector:Test_selector.t
  -> ?close_on_click_outside:bool Bonsai.t
  -> ?close_on_esc:bool Bonsai.t
  -> ?position:Position.t Bonsai.t
  -> ?padding:Css_gen.Length.t Bonsai.t
  -> ?restore_focus_on_close:Restore_focus_on_close.t Bonsai.t
  -> (local_ Bonsai.graph -> Vdom.Node.t Bonsai.t)
  -> close:unit Effect.t Bonsai.t
  -> local_ Bonsai.graph
  -> unit

(** Render a modal view that can be opened by running the returned effect, and closed by
    running the [close] effect supplied to the modal contents. *)
val effect
  :  ?state:bool Bonsai.t * (bool -> unit Effect.t) Bonsai.t
  -> ?position:Position.t Bonsai.t
  -> ?padding:Css_gen.Length.t Bonsai.t
  -> ?close_on_click_outside:bool Bonsai.t
  -> ?close_on_esc:bool Bonsai.t
  -> ?restore_focus_on_close:Restore_focus_on_close.t Bonsai.t
  -> (close:unit Effect.t Bonsai.t -> local_ Bonsai.graph -> Vdom.Node.t Bonsai.t)
  -> local_ Bonsai.graph
  -> unit Effect.t Bonsai.t

(** Render an alert dialog with the given title and message. *)
val alert
  :  local_ Bonsai.graph
  -> (?intent:Skyline_theme_v1.Color.t
      -> ?button_label:string
      -> title:string
      -> string
      -> unit Effect.t)
       Bonsai.t

(** Render a confirm dialog. If the user dismissed the dialog this returns [false],
    otherwise this returns [true]. *)
val confirm
  :  local_ Bonsai.graph
  -> (?intent:Skyline_theme_v1.Color.t
      -> ?cancel_label:string
      -> ?confirm_label:string
      -> title:string
      -> string
      -> bool Effect.t)
       Bonsai.t
