open! Core

type t =
  | Dark
  | Light
  | Vscode of { is_dark : bool }
[@@deriving sexp, compare, equal]

val to_string : t -> string
