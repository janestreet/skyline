open! Core

type t = int Web_worker.Immediate_iarray.t [@@deriving sexp_of]

include
  Web_worker.Immediate_iarray.S
  with type ('elt : immediate) t := t
   and type ('elt : immediate) elt := int
