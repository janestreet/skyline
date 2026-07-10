open! Core

type t =
  { new_index : string iarray or_null
  ; query : string
  ; generation : int
  ; max_results : int or_null
  }
[@@deriving sexp_of]

include Web_worker.Transferrable.To_worker with type t := t with type 'a response := 'a
