open! Core
open! Bonsai_web

val component
  :  ?secondary:bool
  -> ?intent:Skyline_theme_v1.Color.t
  -> string
  -> Vdom.Node.t
