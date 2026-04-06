open! Core
open! Bonsai_web

(** A [Codicon.t] optionally colored with the given intent color. Note that by default the
    codicon will inherit the current text color (in the same way Codicons.svg) does. *)
val component
  :  ?size:Css_gen.Length.t
  -> ?intent:Skyline_theme_v1.Color.t
  -> Codicons.t
  -> Vdom.Node.t

(** The same as [component], except it takes icon as a named argument and unit as a
    positional argument, to match the form expected by ppx html. *)
val component'
  :  ?size:Css_gen.Length.t
  -> ?intent:Skyline_theme_v1.Color.t
  -> icon:Codicons.t
  -> unit
  -> Vdom.Node.t
