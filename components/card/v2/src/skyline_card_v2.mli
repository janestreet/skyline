open! Core
open! Bonsai_web

(** Card

    A Card is a generic container for grouping related content on a surface with optional
    elevation (border/shadow) and background color. Use it to visually separate sections
    of an interface and to provide a consistent padded surface for content.

    {2 Usage}

    - Group related content or controls on a shared surface
    - Use [Section.content] to apply standard padding and text sizing that matches the
      card's [~size]
    - Nest cards with [Surface_color.Two] or [Three] when placing cards inside cards

    {b Layout behavior}

    Cards render as block-level elements and, by default, fill the width of their
    container. If you need a narrower card, wrap it in a container that constrains width
    (e.g., with a max-width) and centers it.

    {b Example}

    {[
      {%html|
        <Skyline_card_v2.view ~elevation:%{One} ~size:%{`Md}>
          <Skyline_card_v2.Section.content>
            This is a card section.
          </>
        </>
      |}
    ]} *)

module Elevation : sig
  (** Controls the card's elevation behaviour:
      - [Zero]: No border with no shadow.
      - [One]: Bordered with no shadow.
      - [Two], [Three], [Four]: Bordered with increasing shadow strength. *)
  type t =
    | Zero
    | One
    | Two
    | Three
    | Four
  [@@deriving sexp, equal, enumerate, to_string]
end

module Surface_color : sig
  (** Controls the background of the card

      - [One]: Default background color.
      - [Two]: Alternative background color for nested cards.
      - [Three]: Additional alternative background color for nested cards. *)
  type t =
    | One
    | Two
    | Three
  [@@deriving sexp, equal, enumerate, to_string]
end

(** Opaque module reflecting content that is valid inside a [view]. *)
module Content : sig
  type t
end

(** [view] creates a card component. The card is just a single <div>, with some optional
    elevation and standard padding.

    - [?size] - controls border radius and body padding
    - [?elevation] - elevation level (default [One])
    - [?surface_color] - background color shade (default [One]) *)
val view
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?size:Skyline_size.t
  -> ?elevation:Elevation.t
  -> ?surface_color:Surface_color.t
  -> Content.t list
  -> Vdom.Node.t

module Section : sig
  (** [Section.content] is a wrapper around the contents that sets the padding
      corresponding to the parent's [size] unless [?full_bleed] is set to [true] (it
      defaults to [false]) *)
  val content
    :  ?test_selector:Test_selector.t
    -> ?full_bleed:bool
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Content.t

  (** [Section.text] creates a card section with appropriate padding and text size.

      Internally, [Section.text] combines [Section.content] with a typography element. *)
  val text
    :  ?test_selector:Test_selector.t
    -> ?full_bleed:bool
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Content.t

  (** [Section.title] creates a card section with appropriate padding text size and text
      weight for a title.

      Internally, [Section.title] combines [Section.content] with a typography element and
      a null padding on the bottom to let the next section handle the padding. *)
  val title
    :  ?test_selector:Test_selector.t
    -> ?full_bleed:bool
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Content.t
end

module For_docs : sig
  val ml_filepath : string
end
