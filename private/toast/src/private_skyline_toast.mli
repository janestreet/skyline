open! Core

type 'a action =
  | Replace of 'a
  | Dismiss

val component
  :  'a Bonsai.t
  -> Bonsai.graph @ local
  -> 'a Bonsai.t * ('a action -> unit Bonsai.Effect.t) Bonsai.t

val position
  : [ `Top_left | `Top_right | `Bottom_left | `Bottom_right ] Bonsai.Dynamic_scope.t
