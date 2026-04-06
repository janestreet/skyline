open! Core

(** A collection of errors that are collected either explicitly or by [handle]ing effects
    that might fail. *)
type t

(** A component that collects [Error.t]s as they happen e.g. when dispatching RPCs,
    validating user input, etc. *)
val component : local_ Bonsai.graph -> t Bonsai.t

(** [collect t error] adds the given error into the current collection. *)
val collect : t -> Error.t -> unit Bonsai.Effect.t

(** [handle t effect] collects any errors that are returned by the resolved effect. *)
val handle : t -> unit Or_error.t Bonsai.Effect.t -> unit Bonsai.Effect.t

(** [clear t] removes any errors that are currently in the collection, e.g. in response to
    a user dismissing the error message. *)
val clear : t -> unit Bonsai.Effect.t

(** [erros t] is the list of errors that are currently part of this error collection. *)
val errors : t -> Error.t list
