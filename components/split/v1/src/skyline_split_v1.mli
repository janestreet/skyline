open! Core
open! Bonsai_web

module Size : sig
  (** Defines how much space a single split should take up. *)
  type t

  type length :=
    [ `Px of int
    | `Percent of Percent.t
    ]

  (** Specify the default size of a split. [~min] can be used to prevent the panel from
      shrinking smaller than the given length. *)
  val create : ?min:length -> length -> t
end

module Layout : sig
  (** A split layout. *)
  type t

  (** The most simple layout possible that just shows the given view.

      This can be combined with [nested_...] constructors to produce more complex layouts. *)
  val single : Vdom.Node.t -> t

  (** Construct a layout that shows a given list of views as side-by-side columns. *)
  val columns : (t * Size.t) list -> t

  (** Construct a layout that shows a given list of views as stacked rows. *)
  val rows : (t * Size.t) list -> t
end

(** Render a split layout that has resizable rows and columns.

    Visually, this will draw borders {i between} elements, but add no other decorations.

    A common way to use this would be to wrap it in a [Skyline.Card.column], but it could
    also be combined with other containers like [Skyline_accordion_v1].

    If you need more control over the layout or want to persist user's changes, put views
    in collapsible accordions, use tabs, or give titles to panels, consider using
    [Skyline.Panel]. *)
val component : Layout.t Bonsai.t -> Bonsai.graph @ local -> Vdom.Node.t Bonsai.t

(** [columns views graph] constructs a resizable layout which evenly spaces views left to
    right. *)
val columns : Vdom.Node.t list Bonsai.t -> Bonsai.graph @ local -> Vdom.Node.t Bonsai.t

(** [rows views graph] constructs a resizable layout which evenly spaces views top to
    bottom. *)
val rows : Vdom.Node.t list Bonsai.t -> Bonsai.graph @ local -> Vdom.Node.t Bonsai.t
