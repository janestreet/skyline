open! Core

type t = start:int * stop:int [@@deriving equal, sexp_of]

val extension : t -> Codemirror.State.Extension.t
