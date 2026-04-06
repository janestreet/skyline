open! Core
open! Bonsai_web

(** Display text logs in a fixed-width font. The log output box comes with a few user
    controls to copy the text / toggle line wrapping by default. *)
val component
  :  ?test_selector:Test_selector.t
  -> ?initial_line_wrap:bool (** Default: false *)
  -> ?max_height:[ `Px of int ] option (** Default: Some (`Px 400) *)
  -> string Bonsai.t
  -> Bonsai.graph @ local
  -> Vdom.Node.t Bonsai.t
