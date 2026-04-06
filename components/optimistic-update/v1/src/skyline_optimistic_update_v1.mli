open! Core
open! Bonsai_web

type 'state t

(** An optimistic update will compute a new display state based on any in-flight actions. *)
val component
  :  ?show_loading_after:Time_ns.Span.t Bonsai.t
  -> 'state Bonsai.t
  -> local_ Bonsai.graph
  -> 'state t Bonsai.t

(** The current optimistically updated state. *)
val state : 'state t -> 'state

(** Indicates if the state has been pending for a long time (which means it might be
    appropriate to display a loading indicator). *)
val show_loading : _ t -> bool

(** Perform the given action and update the optimistic state while the action is pending. *)
val action : 'state t -> update:('state -> 'state) -> 'a Effect.t -> 'a Effect.t

(** Wait until a polling rpc is up-to-date. This is useful to wait until receiving a new
    state from a server after a dispatched rpc returns. *)
val poll_is_up_to_date
  :  ('query, 'response) Rpc_effect.Poll_result.Legacy_record.t Bonsai.t
  -> local_ Bonsai.graph
  -> unit Effect.t Bonsai.t
