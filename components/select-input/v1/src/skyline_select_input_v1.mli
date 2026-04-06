open! Core
open! Bonsai_web

type 'a t = 'a Skyline_input_v1.t

(** A select input component that allows selecting a given value.

    Initially, the first value is selected. Note that when the set of available options
    changes, the currently selected value is NOT reset.

    You can manually control what happens when the options change, or the default, by
    providing a custom state, and potentially resetting it when the set of inputs changes. *)
val component
  :  ?test_selector:Test_selector.t
  -> ?state:'a Bonsai.t * ('a -> unit Effect.t) Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> to_string:('a -> string)
  -> 'a Nonempty_list.t Bonsai.t
  -> Bonsai.graph @ local
  -> 'a t Bonsai.t

(** The input elements view that can be rendered in a UI. *)
val view : _ t -> Vdom.Node.t

(** Current value in the input. *)
val value : 'a t -> 'a

(** Update the value in the input. *)
val update : 'a t -> 'a -> unit Effect.t
