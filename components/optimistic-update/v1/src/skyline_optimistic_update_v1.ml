open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Pending = struct
  type 'state t =
    { timestamp : Time_ns.Alternate_sexp.t
    ; update : 'state -> 'state
    }
end

module Model = struct
  type 'state t =
    { next_id : int
    ; pending : 'state Pending.t Int.Map.t
    }
end

module Action = struct
  type 'state t =
    | Start of 'state Pending.t
    | Complete of int
end

type 'state t =
  { state : 'state
  ; show_loading : bool
  ; get_current_time : Time_ns.t Effect.t
  ; action : 'state Action.t -> int Effect.t
  }
[@@deriving fields ~getters]

let component
  ?(show_loading_after = Bonsai.return (Time_ns.Span.of_int_ms 300))
  input
  (local_ graph)
  =
  let get_current_time = Bonsai.Clock.get_current_time graph in
  let model, action =
    Bonsai.actor
      ~default_model:{ Model.next_id = 0; pending = Int.Map.empty }
      ~recv:(fun _ctx model action ->
        match (action : _ Action.t) with
        | Start pending ->
          let id = model.next_id in
          let pending = Map.add_exn model.pending ~key:id ~data:pending in
          { next_id = id + 1; pending }, id
        | Complete key ->
          let pending = Map.remove model.pending key in
          (* due to a sadness in the actor0 type signature, we need to return the same
             type from the inject function, so we give back an intended-to-be-ignored
             'key' *)
          { model with pending }, key)
      graph
  in
  let state =
    let%arr input
    and { pending; _ } = model in
    Map.fold pending ~init:input ~f:(fun ~key:_ ~data:{ update; _ } state -> update state)
  in
  let show_loading =
    let oldest_pending =
      let%arr { pending; _ } = model in
      Map.min_elt pending |> Option.map ~f:(fun (_, data) -> data.timestamp)
    in
    match%sub oldest_pending with
    | Some timestamp ->
      let show_loading_after =
        let%arr timestamp and show_loading_after in
        Time_ns.add timestamp show_loading_after
      in
      let edge = Bonsai.Clock.at show_loading_after graph in
      let%arr edge in
      (match edge with
       | Before -> false
       | After -> true)
    | None -> Bonsai.return false
  in
  let%arr state and show_loading and get_current_time and action in
  { state; show_loading; get_current_time; action }
;;

let action { get_current_time; action; _ } ~update effect =
  let%bind.Effect timestamp = get_current_time in
  let%bind.Effect id = action (Start { timestamp; update }) in
  let%bind.Effect output = effect in
  let%bind.Effect _ = action (Complete id) in
  Effect.return output
;;

let poll_is_up_to_date poll (local_ graph) =
  let has_no_inflight_query =
    let%arr { Rpc_effect.Poll_result.Legacy_record.inflight_query; _ } = poll in
    Option.is_none inflight_query
  in
  let upon_query_completed = Bonsai_kernel_wait_effect.upon has_no_inflight_query graph in
  let yoink_poll = Bonsai.peek poll graph in
  let%arr upon_query_completed and yoink_poll in
  match%bind.Effect yoink_poll with
  | Active { inflight_query = None; refresh; _ } -> refresh
  | Active { inflight_query = Some _; _ } -> upon_query_completed
  | Inactive -> Effect.return ()
;;
