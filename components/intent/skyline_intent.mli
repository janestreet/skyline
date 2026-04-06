open! Core

type t =
  [ `Primary
  | `Secondary
  | `Success
  | `Danger
  | `Warning
  ]
[@@deriving sexp, equal ~localize, enumerate, to_string]
