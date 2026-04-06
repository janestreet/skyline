open! Core
open! Bonsai_web

(** A placeholder element that can be used to build a loading indicator skeleton. *)
val component
  :  ?rounded:Css_gen.Length.t
  -> width:Css_gen.Length.t
  -> height:Css_gen.Length.t
  -> unit
  -> Vdom.Node.t

(** A placeholder element that has the correct dimensions to represent regular text. *)
val text : width:Css_gen.Length.t -> Vdom.Node.t
