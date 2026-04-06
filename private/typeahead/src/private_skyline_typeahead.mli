open! Core
open! Bonsai_web

module Suggestion_state : sig
  type 'a action =
    | Update of
        { filtered : 'a Iarray.t
        ; limit : int
        }
    | Activate
    | Deactivate
    | Move_to of int
    | Move_up
    | Move_down
    | Select of int
    | Select_current
    | Tab_complete_current
end

type t =
  [ `Idle
  | `Matches of Vdom.Node.t
  | `Empty of Vdom.Node.t
  ]

val suggestion_popover
  :  input_width:float Bonsai.t
  -> Vdom.Node.t Bonsai.t
  -> local_ Bonsai.graph
  -> Vdom.Attr.t Bonsai.t

val component
  :  query:string Bonsai.t
  -> to_string:('a -> string) Bonsai.t
  -> limit:int Bonsai.t
  -> score:('a -> int) Bonsai.t
  -> on_select:('a -> unit Effect.t) Bonsai.t
  -> on_tab_complete:('a -> unit Effect.t) Bonsai.t
  -> suggestion:('a -> Vdom.Node.t) Bonsai.t option
  -> no_matching_suggestions:Vdom.Node.t Bonsai.t
  -> 'a list Bonsai.t
  -> Bonsai.graph @ local
  -> t Bonsai.t * ('a Suggestion_state.action -> unit Effect.t) Bonsai.t
