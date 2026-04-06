open! Core
open! Bonsai_web

(** Skyline-themed styles for the Bonsai [Partial_render_table]. *)
val style
  :  ?padding:Css_gen.Length.t
  -> unit
  -> Bonsai_web_ui_partial_render_table_styling.t
