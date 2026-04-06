open! Core
open! Bonsai_web

type t =
  | Tree
  | List
[@@deriving sexp_of]
