open! Core
open! Bonsai.Let_syntax

type 'a action =
  | Replace of 'a
  | Dismiss

type state =
  | Idle : state
  | Active :
      { path_id : string
      ; witness : 'a Type_equal.Id.t
      ; value : 'a
      }
      -> state

(* A global singleton state that can be set / dismissed by multiple components. Only a
   single component can be active at any given time.

   We use this to implement toast popups which we want to be able to trigger from
   different computations, but only one at a time. *)
let singleton = Bonsai.Expert.Var.create Idle

let component (default : 'a Bonsai.t) graph =
  let witness : 'a Type_equal.Id.t = Type_equal.Id.create ~name:"value" sexp_of_opaque in
  let path_id = Bonsai.path_id graph in
  let inject =
    let%arr path_id in
    function
    | Replace value ->
      Bonsai.Effect.of_sync_fun
        (Bonsai.Expert.Var.set singleton)
        (Active { path_id; witness; value })
    | Dismiss ->
      let drop_if_current = function
        | Active active when String.equal active.path_id path_id -> Idle
        | state -> state
      in
      Bonsai.Effect.of_sync_fun (Bonsai.Expert.Var.update ~f:drop_if_current) singleton
  in
  let value =
    let%arr path_id
    and default
    and singleton = Bonsai.Expert.Var.value singleton in
    match singleton with
    | Active active
      when String.equal active.path_id path_id
           && Type_equal.Id.same active.witness witness ->
      let type_equal = Type_equal.Id.same_witness_exn active.witness witness in
      Type_equal.conv type_equal active.value
    | _ -> default
  in
  value, inject
;;

let position =
  Bonsai.Dynamic_scope.create ~name:"skyline-toast-position" ~fallback:`Top_left ()
;;
