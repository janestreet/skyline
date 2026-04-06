open! Core
open! Bonsai_web

(** Similar to [Flex] wrapper helpers, but styled as a card to visually group it's
    contents. *)

(** A basic card that can be used to visually group information. Its children are laid out
    in a row, much like [Flex.row]. *)
val row
  :  ?attrs:Vdom.Attr.t list
  -> ?reverse:bool
  -> ?wrap:Skyline_flex_v1.Wrap.t
  -> ?justify:Skyline_flex_v1.Justify.t
  -> ?align:Skyline_flex_v1.Align.t
  -> ?gap:Css_gen.Length.t
  -> ?padding:Css_gen.Length.t
  -> ?border_radius:Css_gen.Length.t
  -> ?intent:Skyline_theme_v1.Color.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** A basic card that can be used to visually group information. Its children are laid out
    in a column, much like [Flex.column]. *)
val column
  :  ?attrs:Vdom.Attr.t list
  -> ?reverse:bool
  -> ?wrap:Skyline_flex_v1.Wrap.t
  -> ?justify:Skyline_flex_v1.Justify.t
  -> ?align:Skyline_flex_v1.Align.t
  -> ?gap:Css_gen.Length.t
  -> ?padding:Css_gen.Length.t
  -> ?border_radius:Css_gen.Length.t
  -> ?intent:Skyline_theme_v1.Color.t
  -> Vdom.Node.t list
  -> Vdom.Node.t
