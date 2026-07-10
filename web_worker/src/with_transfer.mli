open! Core

(** Helpers for posting messages to and from web workers (as in
    [Js_of_ocaml.Worker.post_message]) with zero-copy transferrable parts such as
    [Typed_array].

    @see < https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Transferable_objects >
      javascript docs for transferrable objects

    @see < https://developer.mozilla.org/en-US/docs/Web/API/Worker/postMessage#parameters >
      javascript docs for parameters of [postMessage] *)

type ('message, 'transfer) t =
  { message : 'message
  (** The object to deliver to the recipient; this will be in the [data] field in the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/MessageEvent/data} MessageEvent}
      delivered to the recipient. This may be any value or JavaScript object handled by
      the structured clone algorithm, which includes cyclical references. *)
  ; transfer : 'transfer array
  (** A (possibly empty) array of transferable objects to transfer ownership of. The
      ownership of these objects is given to the destination side and they are no longer
      usable on the sending side. These transferable objects are not automatically sent;
      they must be contained in [message]. *)
  }

val singleton : 'message -> ('message, 'message) t

(** Equivalent of [Js_of_ocaml.Worker.post_message] or
    [Js_of_ocaml.Worker.worker##postMessage] based on [post_context].

    See {!Post_context} for more documentation. *)
val post_message : 'message Post_context.t -> ('message, 'transfer) t -> unit

module Packed : sig
  type ('message, 'transfer) unpacked := ('message, 'transfer) t
  type 'message t = Packed : ('message, 'transfer) unpacked -> 'message t [@@unboxed]

  val singleton : 'message -> 'message t
  val post_message : 'message Post_context.t -> 'message t -> unit
end

val pack : ('message, _) t -> 'message Packed.t
