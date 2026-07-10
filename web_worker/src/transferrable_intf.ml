open! Core
open Js_of_ocaml

(** Helpers for constructing types that can be sent between web workers via
    {!With_transfer}. *)

module type S = sig
  type t
  type message

  val parse : message -> t
  val serialize : t -> message With_transfer.Packed.t
end

module type From_worker = sig
  include S

  val post_message : t -> unit
end

module type To_worker = sig
  include S

  type 'a response

  val post_message
    :  t
    -> worker:(message, 'a response) Js_of_ocaml.Worker.worker Js_of_ocaml.Js.t
    -> unit
end

module type Transferrable = sig
  module type S = S
  module type From_worker = From_worker
  module type To_worker = To_worker

  (** Convenience wrapper for
      [Binable.to_bigstring m x |> Typed_array.Bigstring.to_arrayBuffer]. *)
  val to_arraybuf : 'a Binable.m -> 'a -> Typed_array.arrayBuffer Js.t

  (** Convenience wrapper for
      [Typed_array.Bigstring.of_arrayBuffer x |> Binable.of_bigstring m]. *)
  val of_arraybuf : 'a Binable.m -> Typed_array.arrayBuffer Js.t -> 'a

  (** Construct a protocol where each message allocates a new bigstring and fills it via
      [to_arraybuf], then transfers the buffer without further copies. The recipient
      copies back to its heap with [of_arraybuf].

      This is generally more performant than structured cloning, but not quite as nice as
      using a type which can be transferred directly without serialization, such as
      {!Immediate_iarray}. *)
  module Of_binable (T : sig
      type t [@@deriving bin_io]
    end) : S with type t := T.t and type message = Typed_array.arrayBuffer Js.t
end
