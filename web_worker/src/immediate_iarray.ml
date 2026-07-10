open! Core
open! Js_of_ocaml
include Immediate_iarray_intf

type ('a : immediate) t = Typed_array.int32Array Js.t

let transferrable_buffer (t : _ t) = t##.buffer
let length t = t##.length

let unsafe_get (type a : immediate) (t : a t) i : a =
  let elt = Typed_array.unsafe_get t i in
  (* [Int32.t->int] conversion cannot raise here:
     - If we're running under javascript then this just cannot raise ever; js_of_ocaml
       [int]s are 1:1 with [int32]
     - If we're running under WASM, it's theoretically possible for [Int.of_int32_exn] to
       raise, but in this case we know the input was constructed via [Int.to_int32_exn]
       (see [of_iarray] below) so it's guaranteed to be in range.
  *)
  let elt : int = elt |> Js.to_int32 |> Int.of_int32_exn in
  (* Safe magic: We know that the int [elt] was produced via the reverse cast
     [(Obj.magic : a -> int)] in [of_iarray]; this merely undoes the transformation. *)
  (Obj.magic elt : a)
;;

let to_iarray (type a : immediate) (t : a t) ~f =
  let len = length t in
  if len = 0
  then Iarray.empty
  else (
    let dst = Array.create ~len (f (unsafe_get t 0)) in
    for i = 1 to len - 1 do
      Array.unsafe_set dst i (f (unsafe_get t i))
    done;
    Iarray.unsafe_of_array__promise_no_mutation dst)
;;

let init (type a : immediate) len ~(f : (int -> a) @ local) : a t =
  let dst = new%js Typed_array.int32Array len in
  for i = 0 to len - 1 do
    let elt : a = f i in
    (* Safe magic: [a] is known to be immediate, so the cast cannot fail. *)
    let elt : int = Obj.magic elt in
    (* Int32 conversion cannot raise here: neither js_of_ocaml nor wasm_of_ocaml permits
       integers that wouldn't fit in an [Int32.t]. *)
    let elt = Js.int32 (Int.to_int32_exn elt) in
    Typed_array.set dst i elt
  done;
  dst
;;

let of_iarray (type a : immediate) (indices : a iarray @ local) : a t =
  let len = Iarray.length indices in
  init len ~f:(stack_ fun i ->
    let a : a = (Iarray.unsafe_get indices i : a) in
    a)
  [@nontail]
;;

let sexp_of_t (type a : immediate) sexp_of_a (t : a t) : Sexp.t =
  to_iarray t ~f:Fn.id |> [%sexp_of: a iarray]
;;
