open! Core
open! Bonsai_web

(** Divider

    Dividers are used to visually separate multiple elements in a UI. There are different
    styles of divider which can be used for items that are either arranged vertically or
    horizontally.

    {b Usage}

    - Hairlines: Use [horizontal] or [vertical] to separate sections of content with a
      thin line.
    - Inline separators: Use [interpunct] or [slash] to separate items in a horizontal
      list of text.

    {b Example}

    {[
      Skyline.Divider.horizontal ()
    ]} *)

(** A horizontal hairline. By default the line has [length=100%], but for some containers
    an explicit length is required.

    - [?attrs] - additional HTML attributes (default [])
    - [?length] - the width of the line (default [100%])

    Hairlines can be used to separate most types of content. *)
val horizontal
  :  ?attrs:Vdom.Attr.t list
  -> ?length:Css_gen.Length.t
  -> unit
  -> Vdom.Node.t

(** A vertical hairline. By default the line has [length=100%], but for some containers an
    explicit length is required.

    - [?attrs] - additional HTML attributes (default [])
    - [?length] - the height of the line (default [100%])

    Hairlines can be used to separate most types of content. *)
val vertical : ?attrs:Vdom.Attr.t list -> ?length:Css_gen.Length.t -> unit -> Vdom.Node.t

(** A centered dot [·] that can e.g. be used in-between textual items in a horizontal
    list.

    To separate elements that are much bigger than a single line of text, a [vertical]
    hairline might be a better choice. *)
val interpunct : Vdom.Node.t

(** A forward slash [/] that can e.g. be used in-between textual items in a path.

    This type of divider should typically only be used to separate text. *)
val slash : Vdom.Node.t

module For_docs : sig
  val ml_filepath : string
end
