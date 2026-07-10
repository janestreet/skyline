open! Core

type -'a t =
  | From_worker
  | To_worker : ('a, _) Js_of_ocaml.Worker.worker Js_of_ocaml.Js.t -> 'a t
