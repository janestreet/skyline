open! Core

type t =
  { stage : [ `Idle | `Cooldown | `Confirm ]
  ; trigger : unit Bonsai.Effect.t
  ; reset : unit Bonsai.Effect.t
  }

(** A guard that can be used to show a confirm action when triggered.

    The component starts out in the [Idle] state. When triggered, it changes to
    [Confirm reset] for a two second period (with a short cooldown phase before to e.g.
    prevent a double click from triggering the confirm state). *)
val component : local_ Bonsai.graph -> t Bonsai.t
