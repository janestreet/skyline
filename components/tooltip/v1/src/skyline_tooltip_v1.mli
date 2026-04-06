open! Core
open! Bonsai_web

(** A tooltip is a floating UI that's visually attached to a specific element on the page.
    It is typically used to display additional information on hover.

    Tooltips are generally not interactive. *)

module Position : sig
  (** Determines the position of the tooltip relative to the anchor element. [Auto]
      chooses the placement with the most avialable space, while the other options prefer
      to place the popover at the given position (falling back to a different position if
      the popover would otherwise overflow the page). *)
  type t =
    | Auto
    | Top
    | Bottom
    | Left
    | Right
  [@@deriving sexp_of]
end

module Alignment : sig
  (** Determines how the popover is aligned relative to the anchor element. *)
  type t =
    | Center
    | Start
    | End
  [@@deriving sexp_of]
end

(** A hover tooltip that renders a custom view. The tooltip is visible on hover and is not
    interactive by default. *)
val component
  :  ?position:Position.t
  -> ?alignment:Alignment.t
  -> ?interactive:bool
  -> Vdom.Node.t
  -> Vdom.Attr.t

(** A simple hover tooltip that renders the given text when the element is hovered. *)
val text
  :  ?intent:Skyline_theme_v1.Color.t
  -> ?position:Position.t
  -> ?alignment:Alignment.t
  -> ?size:Skyline_text_v1.Font_size.t
  -> string
  -> Vdom.Attr.t
