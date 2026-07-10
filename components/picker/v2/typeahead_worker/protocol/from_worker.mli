open! Core

type t =
  | Search_complete of
      { generation : int
      ; indices : Indices.t
      }
[@@deriving sexp_of]

include Web_worker.Transferrable.From_worker with type t := t
