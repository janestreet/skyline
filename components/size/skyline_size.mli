open! Core

type t =
  [ `Xs
  | `Sm
  | `Md
  | `Lg
  ]
[@@deriving sexp, equal ~localize, enumerate, to_string]
