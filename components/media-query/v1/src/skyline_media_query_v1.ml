open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
open Js_of_ocaml

let matches query (local_ _graph) =
  let window : _ Js.t = Js.Unsafe.coerce Dom_html.window in
  let query : _ Js.t = window##matchMedia (Js.string query) in
  let matches = Bonsai.Expert.Var.create (Js.to_bool query##.matches) in
  query##.onchange
  := Js.wrap_callback (fun event ->
       Bonsai.Expert.Var.set matches (Js.to_bool event##.matches));
  Bonsai.Expert.Var.value matches
;;
