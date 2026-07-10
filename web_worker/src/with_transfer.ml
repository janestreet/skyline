open! Core
open! Js_of_ocaml

type ('message, 'transfer) t =
  { message : 'message
  ; transfer : 'transfer array
  }

let singleton x = { message = x; transfer = [| x |] }

let post_message ctx { message; transfer } =
  match (ctx : 'message Post_context.t) with
  | From_worker ->
    Post_message.post_message (Post_message.from_worker ()) ~message ~transfer
  | To_worker w -> Post_message.post_message (Post_message.to_worker w) ~message ~transfer
;;

module Packed = struct
  type ('message, 'transfer) unpacked = ('message, 'transfer) t
  type 'message t = Packed : ('message, 'transfer) unpacked -> 'message t [@@unboxed]

  let singleton x = Packed (singleton x)
  let post_message ctx (Packed t) = post_message ctx t
end

let pack t : _ Packed.t = Packed t
