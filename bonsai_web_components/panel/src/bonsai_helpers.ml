open! Core
open Bonsai
open Bonsai.Let_syntax

let last_value ~equal a b graph =
  let value_a, time_a =
    Bonsai_extra.Value_stability.with_last_modified_time ~equal a graph
  in
  let value_b, time_b =
    Bonsai_extra.Value_stability.with_last_modified_time ~equal b graph
  in
  let%arr value_a and time_a and value_b and time_b in
  if Time_ns.(time_a > time_b) then value_a else value_b
;;

let last_value_update_or_override ~equal ~default_model (local_ graph) =
  let override, set = Bonsai.state_opt graph ~equal in
  let set_override =
    let%arr set in
    fun model -> set (Some model)
  in
  let override =
    let%arr override and default_model in
    match override with
    | Some override -> override
    | None -> default_model
  in
  let value = last_value ~equal default_model override graph in
  Bonsai.both value set_override
;;
