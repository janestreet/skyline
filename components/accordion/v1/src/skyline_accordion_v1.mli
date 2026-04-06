open! Core
open! Bonsai_web

type t

(** A single accordion row. [label] is rendered in a region that can be clicked to expand
    the contents. [detail] is renderd off to the side and can contain additional buttons /
    other interactive elements. *)
val component
  :  ?test_selector:Test_selector.t Bonsai.t
  -> ?expanded:
       [ `Expanded | `Collapsed ] Bonsai.t
       * ([ `Expanded | `Collapsed ] -> unit Effect.t) Bonsai.t
  -> ?sticky_title:bool Bonsai.t
  -> ?detail:
       (expanded:[ `Expanded | `Collapsed ] Bonsai.t
        -> local_ Bonsai.graph
        -> Vdom.Node.t Bonsai.t)
  -> label:Vdom.Node.t Bonsai.t
  -> (local_ Bonsai.graph -> [ `Value of Vdom.Node.t | `Loading ] Bonsai.t)
  -> local_ Bonsai.graph
  -> t Bonsai.t

(** Combine a list of accordion rows into a complete accordion. *)
val view : t list -> Vdom.Node.t
