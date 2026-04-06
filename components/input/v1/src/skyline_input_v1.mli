open! Core
open! Bonsai_web

module type S = sig
  type 'a t

  (** The input elements view that can be rendered in a UI. *)
  val view : _ t -> Vdom.Node.t

  (** Current value in the input. *)
  val value : 'a t -> 'a

  (** Update the value in the input. *)
  val update : 'a t -> 'a -> unit Effect.t
end

(** A common type implemented by skyline input elements. *)
type 'a t

(** Create a custom input element with the given view and state. *)
val create
  :  Vdom.Node.t Bonsai.t
  -> 'a Bonsai.t
  -> ('a -> unit Effect.t) Bonsai.t
  -> 'a t Bonsai.t

include S with type 'a t := 'a t (** @inline *)
