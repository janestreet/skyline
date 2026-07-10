open! Core
open Js_of_ocaml

(** This is the two-argument form of [postMessage]. It is defined for any javascript
    object which has a single-argument [postMessage] method, in particular:

    1. any [Js_of_ocaml.Worker.worker]
    2. within a dedicated web-worker implementation, [Js_of_ocaml.Js.Unsafe.global]

    See {!Post_context} for more documentation on valid contexts.

    If you're already linking in the {!Browser} library, the same functions are available
    as {!Browser.Dedicated_worker_global_scope.post_message_1} and
    {!Browser.Worker.post_message_1}. *)

class type [-'message, 'transfer] t = object
  method _postMessage :
    message:'message -> transfer:'transfer Js.js_array Js.t -> unit Js.meth
end

(** Convenience wrapper for [t##_postMessage ~message ~transfer:(Js.array transfer)]. *)
val post_message
  :  ('message, 'transfer) #t Js.t
  -> message:'message
  -> transfer:'transfer array
  -> unit

(** Extend the global context with the two-argument form of [postMessage].

    See [Post_context.From_worker] ({!Post_context}) *)
val from_worker : unit -> ('message, 'transfer) t Js.t

class type [-'message, +'response, 'transfer] to_worker = object
  inherit ['message, 'response] Js_of_ocaml.Worker.worker
  inherit ['message, 'transfer] t
end

(** Extend a [Js_of_ocaml.Worker] object with the two-argument form of [postMessage].

    See [Post_context.To_worker] ({!Post_context}) *)
val to_worker
  :  ('message, 'response) #Js_of_ocaml.Worker.worker Js.t
  -> ('message, 'response, 'transfer) to_worker Js.t
