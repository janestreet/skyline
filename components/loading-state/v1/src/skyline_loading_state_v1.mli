open! Core

type t

(** A loading handler is a component that can be used to determine if some effect is
    currently in-flight (i.e. to display a loading indicator). *)
val component : local_ Bonsai.graph -> t Bonsai.t

(** Handle the effect. While the effect is in-flight [is_loading] will return [true]. *)
val handle : t -> 'a Bonsai.Effect.t -> 'a Bonsai.Effect.t

(** Returns [true] if there are any in-flight effects. *)
val is_loading : t -> bool
