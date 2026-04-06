open! Core
open! Bonsai_web

(** Helpers for rendering styled text in a web UI. Skyline provides a range of text sizes
    and styles that can be freely combined and are designed to be visually coherent.

    Text comes in two main variants and four sizes:

    {v
    {table
      {tr {th Text variant}  {th [span]}    {th [heading]} }
      {tr {td Smallest size} {td [Small]}   {td {i N/A}}
      {tr {td }              {td [Regular]} {td [Small]}
      {tr {td }              {td [Large]}   {td [Regular]}
      {tr {td Largest size}  {td {i N/A}}   {td [Large]}
      }
    }
    v}

    Beyond text size, there are also options that control font-family, font-style, text
    color based on [Intent]s, and others. *)

module Font_family : sig
  (** Font family for rendering the text. The default sans-serif font uses ["Inter"] and a
      fixed width / monospaced font is also available. *)
  type t =
    | Sans_serif
    | Monospace
  [@@deriving sexp_of, equal, compare]
end

module Font_style : sig
  (** Font style for rendering the text. *)
  type t =
    | Regular (** Font weight 400 *)
    | Medium_weight
    (** Font weight 500. Somewhat specialized, most uses can stick to [Regular] or [Bold]. *)
    | Bold (** Font weight 700 *)
    | Italic
  [@@deriving sexp_of, equal, compare]
end

module Font_size : sig
  (** Font size for rendering the text.

      How big the text is visually depends on the kind of text being rendered: [heading]s
      are all once size larger than the corresponding [span]s, so [Regular] [heading]s
      will be visually the same as [Large] [span]s. *)
  type t =
    | Small
    | Regular
    | Large
  [@@deriving sexp_of, equal, compare]
end

module Text_decoration : sig
  (** Decorate the text with an underline, strike-through, or overline. *)
  type t =
    | None
    | Underline
    | Line_through
  [@@deriving sexp_of, equal, compare]
end

(** Text for a heading, rendered as HTML [<h{1,2,3}/>] tags. This style of font should be
    used to display page titles, headings for sections, etc.

    A [Small] heading is visually the same size as a [Regular] span. *)
val heading
  :  ?attrs:Vdom.Attr.t list
  -> ?font:Font_family.t
  -> ?style:Font_style.t
  -> ?size:Font_size.t
  -> ?decoration:Text_decoration.t
  -> ?align:Css_gen.text_align
  -> ?intent:Skyline_theme_v1.Color.t
  -> string
  -> Vdom.Node.t

(** The same as [heading], except it allows its children to be anything. *)
val heading'
  :  ?attrs:Vdom.Attr.t list
  -> ?font:Font_family.t
  -> ?style:Font_style.t
  -> ?size:Font_size.t
  -> ?decoration:Text_decoration.t
  -> ?align:Css_gen.text_align
  -> ?intent:Skyline_theme_v1.Color.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** Regular text, rendered as HTML [<span/>] tag. This style of font should be used to
    display any kind of text that is not semantically a heading.

    A [Large] span is visually the same size as a [Regular] heading. *)
val span
  :  ?attrs:Vdom.Attr.t list
  -> ?font:Font_family.t
  -> ?style:Font_style.t
  -> ?size:Font_size.t
  -> ?decoration:Text_decoration.t
  -> ?align:Css_gen.text_align
  -> ?intent:Skyline_theme_v1.Color.t
  -> ?secondary:bool
  -> string
  -> Vdom.Node.t

(** The same as [span], except it allows its children to be anything. *)
val span'
  :  ?attrs:Vdom.Attr.t list
  -> ?font:Font_family.t
  -> ?style:Font_style.t
  -> ?size:Font_size.t
  -> ?decoration:Text_decoration.t
  -> ?align:Css_gen.text_align
  -> ?intent:Skyline_theme_v1.Color.t
  -> ?secondary:bool
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** A link, rendered as an HTML [<a/>] tag, that can be used inline with text. *)
val link
  :  ?attrs:Vdom.Attr.t list
  -> ?font:Font_family.t
  -> ?style:Font_style.t
  -> ?size:Font_size.t
  -> ?decoration:Text_decoration.t
  -> ?align:Css_gen.text_align
  -> ?intent:Skyline_theme_v1.Color.t
  -> ?target:[ `Self | `Blank ]
  -> href:string
  -> string
  -> Vdom.Node.t

(** The same as [link], except it allows its children to be anything. *)
val link'
  :  ?attrs:Vdom.Attr.t list
  -> ?font:Font_family.t
  -> ?style:Font_style.t
  -> ?size:Font_size.t
  -> ?decoration:Text_decoration.t
  -> ?align:Css_gen.text_align
  -> ?intent:Skyline_theme_v1.Color.t
  -> ?target:[ `Self | `Blank ]
  -> href:string
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** A link rendered as an HTML [<a/>] tag that performs an effect instead of having an
    href *)
val link_with_effect
  :  ?attrs:Vdom.Attr.t list
  -> ?font:Font_family.t
  -> ?style:Font_style.t
  -> ?size:Font_size.t
  -> ?decoration:Text_decoration.t
  -> ?align:Css_gen.text_align
  -> ?intent:Skyline_theme_v1.Color.t
  -> on_click:unit Effect.t
  -> string
  -> Vdom.Node.t

(** The same as [link_with_effect], except it allows its children to be anything *)
val link_with_effect'
  :  ?attrs:Vdom.Attr.t list
  -> ?font:Font_family.t
  -> ?style:Font_style.t
  -> ?size:Font_size.t
  -> ?decoration:Text_decoration.t
  -> ?align:Css_gen.text_align
  -> ?intent:Skyline_theme_v1.Color.t
  -> on_click:unit Effect.t
  -> Vdom.Node.t list
  -> Vdom.Node.t
