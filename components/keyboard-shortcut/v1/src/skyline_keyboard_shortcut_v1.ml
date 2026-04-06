open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

(* Public re-exports *)
module Modifier_status = Private_skyline_keyboard_shortcut.Modifier_status
module Modifier = Private_skyline_keyboard_shortcut.Modifier
module Key = Private_skyline_keyboard_shortcut.Key

type t = Modifier.t * Key.t [@@deriving sexp_of, compare, equal]

let install_listener_for_computation subtree graph =
  Private_skyline_keyboard_shortcut.install_listener ~mode:`Local subtree graph
;;

let register' ?ignore_modifier ~effect key graph =
  let modifier =
    let%arr ignore_modifier = Bonsai.transpose_opt ignore_modifier
    and key in
    match ignore_modifier with
    | None when [%compare.equal: Key.t] key `Esc -> `Any
    | Some false | None -> `None
    | Some true -> `Any
  in
  Private_skyline_keyboard_shortcut.register_shortcut ~effect ~modifier ~key graph
;;

let register ~effect shortcut graph =
  let%sub modifier, key =
    let%arr modifier, shortcut = shortcut in
    (modifier :> [ `Any | `None | Modifier.t ]), shortcut
  in
  Private_skyline_keyboard_shortcut.register_shortcut ~effect ~modifier ~key graph
;;
