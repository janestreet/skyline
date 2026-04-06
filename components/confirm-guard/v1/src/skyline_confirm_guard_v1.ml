open! Core
open! Bonsai.Let_syntax

type t =
  { stage : [ `Idle | `Cooldown | `Confirm ]
  ; trigger : unit Bonsai.Effect.t
  ; reset : unit Bonsai.Effect.t
  }

let component (local_ graph) =
  let last_set_time, set_time = Bonsai.state Time_ns.min_value_representable graph in
  let cooldown_until =
    let%arr last_set_time in
    Time_ns.add last_set_time (Time_ns.Span.of_int_ms 200)
  in
  let can_confirm_until =
    let%arr last_set_time in
    Time_ns.add last_set_time (Time_ns.Span.of_int_sec 2)
  in
  let cooldown = Bonsai.Clock.at cooldown_until graph in
  let can_confirm = Bonsai.Clock.at can_confirm_until graph in
  let now = Bonsai.Clock.get_current_time graph in
  let%arr set_time and cooldown and can_confirm and now in
  let stage =
    match cooldown, can_confirm with
    | _, After -> `Idle
    | Before, _ -> `Cooldown
    | After, Before -> `Confirm
  in
  let trigger = Bonsai.Effect.bind now ~f:set_time in
  let reset = set_time Time_ns.min_value_representable in
  { stage; trigger; reset }
;;
