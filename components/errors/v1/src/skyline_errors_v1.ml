open! Core
open! Bonsai.Let_syntax

module Action = struct
  type t =
    | Prepend of Error.t
    | Clear
end

type t =
  { errors : Error.t list
  ; action : Action.t -> unit Bonsai.Effect.t
  }

let component (local_ graph) =
  let apply_action (_ : _ Bonsai.Apply_action_context.t) model = function
    | Action.Prepend e -> e :: model
    | Clear -> []
  in
  let errors, action = Bonsai.state_machine graph ~default_model:[] ~apply_action in
  let%arr errors and action in
  { errors; action }
;;

let collect { action; _ } error = action (Prepend error)

let handle { action; _ } effect =
  match%bind.Bonsai.Effect effect with
  | Ok () -> Bonsai.Effect.return ()
  | Error error -> action (Prepend error)
;;

let clear { action; _ } = action Clear
let errors { errors; _ } = errors
