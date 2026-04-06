open! Core
open! Bonsai_web

module Position : sig
  (** Determines the position of the popover relative to the anchor element. [Auto]
      chooses the placement with the most avialable space, while the other options prefer
      to place the popover at the given position (falling back to a different position if
      the popover would otherwise overflow the page). *)
  type t =
    | Auto
    | Top
    | Bottom
    | Left
    | Right
  [@@deriving sexp_of, equal]
end

module Alignment : sig
  (** Determines how the popover is aligned relative to the anchor element. *)
  type t =
    | Center
    | Start
    | End
  [@@deriving sexp_of, equal]
end

module Width : sig
  (** Determines the width of the popover. [Content] fits the containers content with a
      max width (see implementation), [Fixed width] allows you to choose an arbitrary
      size, and [Max width] allows you to choose an arbitrary max size. *)
  type t =
    | Content
    | Fixed of Css_gen.Length.t
    | Max of Css_gen.Length.t
  [@@deriving sexp_of]
end

type t

val component
  :  ?attrs:Vdom.Attr.t list Bonsai.t
  -> ?state:bool Bonsai.t * (bool -> unit Effect.t) Bonsai.t
  -> ?position:Position.t Bonsai.t
  -> ?alignment:Alignment.t Bonsai.t
  -> ?focus_on_show:bool Bonsai.t
  -> ?close_on_click_outside:bool Bonsai.t
  -> ?width:Width.t Bonsai.t
  -> ?padding:Css_gen.Length.t Bonsai.t
  -> (hide:unit Effect.t Bonsai.t -> Bonsai.graph @ local -> Vdom.Node.t Bonsai.t)
  -> Bonsai.graph @ local
  -> t Bonsai.t

(** An attribute that will attach the popover to a given element. *)
val anchor : t -> Vdom.Attr.t

(** [visible t] is [true] if the popover is visible and false otherwise. *)
val visible : t -> bool

(** [show t] will show the popover. This is a noop if the popover is already visible. *)
val show : t -> unit Effect.t

(** [hide t] will hide the popover. This is a noop if the popover is already hidden. *)
val hide : t -> unit Effect.t

(** Switch between visible / hidden. *)
val toggle : t -> unit Effect.t
