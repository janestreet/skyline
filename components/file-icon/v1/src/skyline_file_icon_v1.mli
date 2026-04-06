open! Core
open! Bonsai_web

(** Renders a seti icon based on the given filename, e.g. a caml for [.ml] files. *)
val component : ?size:Css_gen.Length.t -> Filename.t -> Vdom.Node.t

(** Return an appropriate Seti icon given some filename. *)
val by_filename : Filename.t -> (Seti_icons.t * Css_gen.Color.t) option
