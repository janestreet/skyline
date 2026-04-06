open! Core

type t =
  | Dark
  | Light
  | Vscode of { is_dark : bool }
[@@deriving sexp, compare, equal]

let to_string = function
  | Dark -> "dark"
  | Light -> "light"
  | Vscode _ -> "vscode"
;;
