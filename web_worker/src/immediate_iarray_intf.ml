open! Core
open Js_of_ocaml

module type S = sig
  (** This is morally the equivalent of a ['a iarray], but represented internally as
      [Js_of_ocaml.Typed_array.int32Array Js_of_ocaml.Js.t] to allow for zero-copy
      transfer between a web worker and the main client context - see {!Transferrable} in
      this library.

      ['a] is restricted to be [immediate] to ensure it is safe to [Obj.magic] to and from
      [int]. When compiling with vanilla OCaml rather than OxCaml, this restriction may
      not be checked.

      You can always convert back to an iarray if needed, but direct access with
      [unsafe_get] will avoid making copies to the heap. *)
  type ('elt : immediate) t

  type ('elt : immediate) elt

  val length : _ t -> int
  val unsafe_get : 'elt t -> int -> 'elt elt

  (** [t == (to_iarray t ~f:Fn.id |> of_iarray)] *)
  val to_iarray : 'elt t -> f:('elt elt -> 'out) @ local -> 'out iarray

  (** [iarray == (of_iarray iarray |> to_iarray ~f:Fn.id)] *)
  val of_iarray : 'elt elt iarray @ local -> 'elt t

  val init : int -> f:(int -> 'elt elt) @ local -> 'elt t

  (** For use with [With_transfer]. Do not use this to bypass the intended immutability of
      the array.

      After transferring, the local context's backing array is cleared and [t] should no
      longer be used. *)
  val transferrable_buffer : _ t -> Typed_array.arrayBuffer Js.t
end

module type Immediate_iarray = sig
  module type S = S

  type ('elt : immediate) t [@@deriving sexp_of]

  include S with type 'elt elt := 'elt and type 'elt t := 'elt t
end
