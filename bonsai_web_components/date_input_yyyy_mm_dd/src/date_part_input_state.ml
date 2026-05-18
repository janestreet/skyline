open! Core
open! Bonsai_web

type t =
  { state : [ `Nothing_typed | `Something_typed ]
  ; value : string option
  ; format : string
  ; max_value : int
  }
[@@deriving sexp_of]

module Action = struct
  type t =
    | Focus
    | Reset_value
    | Set_value of string option
    | Increase_by_one
    | Decrease_by_one
    | Append_value of string
end

let initial_state ~format ~max_value =
  { state = `Nothing_typed; value = None; format; max_value }
;;

let apply_action model (action : Action.t) =
  match action with
  | Focus -> { model with state = `Nothing_typed }
  | Reset_value -> { model with value = None }
  | Set_value value -> { model with value }
  | Increase_by_one ->
    (match Option.map ~f:Int.of_string model.value with
     | None -> { model with value = Some "1" }
     | Some value ->
       let new_value = value + 1 in
       let new_value = if new_value > model.max_value then 1 else new_value in
       { model with value = Some (Int.to_string new_value) })
  | Decrease_by_one ->
    (match Option.map ~f:Int.of_string model.value with
     | None -> { model with value = Some (Int.to_string model.max_value) }
     | Some value ->
       let new_value = value - 1 in
       let new_value = if new_value < 1 then model.max_value else new_value in
       { model with value = Some (Int.to_string new_value) })
  | Append_value value ->
    let limit_length value ~length =
      if String.length value > length then String.sub value ~pos:0 ~len:length else value
    in
    let new_value =
      match model.state with
      | `Nothing_typed -> value
      | `Something_typed ->
        let prev_value = Option.value ~default:"" model.value in
        prev_value ^ value |> limit_length ~length:(String.length model.format)
    in
    { model with value = Some new_value; state = `Something_typed }
;;

module For_testing = struct
  let initial_state = initial_state
  let apply_action = apply_action
end

let create ~format ~max_value (local_ graph) =
  Bonsai.actor
    ~default_model:(initial_state ~format ~max_value)
    ~recv:(fun _ctx model (action : Action.t) ->
      let next_model = apply_action model action in
      let next_value = next_model.value in
      next_model, next_value)
    graph
;;

let to_string { value; format; _ } =
  let pad_value value ~length =
    let value_length = String.length value in
    let padding_length = length - value_length in
    let padding = if padding_length > 0 then String.make padding_length '0' else "" in
    padding ^ value
  in
  Option.value_map value ~f:(pad_value ~length:(String.length format)) ~default:format
;;
