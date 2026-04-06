open! Core
open! Bonsai_web

(** A checkbox input that can be used to toggle a boolean value. *)

type 'a t = 'a Skyline_input_v1.t

(** The default checkbox input, that can either be checked or unchecked. *)
val component
  :  ?test_selector:Test_selector.t
  -> ?state:bool Bonsai.t * (bool -> unit Effect.t) Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?intent:Skyline_theme_v1.Color.t Bonsai.t
  -> ?label:string Bonsai.t
  -> Bonsai.graph @ local
  -> bool Skyline_input_v1.t Bonsai.t

include Skyline_input_v1.S with type 'a t := 'a t
