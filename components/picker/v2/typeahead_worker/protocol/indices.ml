open! Core
open! Js_of_ocaml

type t = int Web_worker.Immediate_iarray.t [@@deriving sexp_of]

let length : t -> _ = Web_worker.Immediate_iarray.length
let unsafe_get : t -> _ = Web_worker.Immediate_iarray.unsafe_get
let to_iarray : t -> _ = Web_worker.Immediate_iarray.to_iarray
let of_iarray : int iarray @ local -> t = Web_worker.Immediate_iarray.of_iarray
let init len ~f : t = Web_worker.Immediate_iarray.init len ~f
let transferrable_buffer : t -> _ = Web_worker.Immediate_iarray.transferrable_buffer
