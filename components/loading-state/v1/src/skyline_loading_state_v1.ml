open! Core
open! Bonsai.Let_syntax

type t = in_flight:int * action:(int -> unit Bonsai.Effect.t)

let component (local_ graph) =
  let in_flight, action =
    Bonsai.state_machine
      graph
      ~equal:[%equal: Int.t]
      ~sexp_of_action:[%sexp_of: Int.t]
      ~default_model:0
      ~apply_action:(fun (_ : _ Bonsai.Apply_action_context.t) -> Int.( + ))
  in
  let%arr in_flight and action in
  ~in_flight, ~action
;;

let handle ((~action, ..) : t) effect =
  let%bind.Bonsai.Effect () = action 1 in
  let%bind.Bonsai.Effect result = effect in
  let%bind.Bonsai.Effect () = action (-1) in
  Bonsai.Effect.return result
;;

let is_loading ((~in_flight, ..) : t) = in_flight > 0
