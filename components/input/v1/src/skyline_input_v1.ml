open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module type S = sig
  type 'a t

  val view : _ t -> Vdom.Node.t
  val value : 'a t -> 'a
  val update : 'a t -> 'a -> unit Effect.t
end

type 'a t =
  { view : Vdom.Node.t
  ; value : 'a
  ; update : 'a -> unit Effect.t
  }

let create view value update =
  let%arr view and value and update in
  { view; value; update }
;;

let view { view; _ } = view
let value { value; _ } = value
let update { update; _ } new_value = update new_value
