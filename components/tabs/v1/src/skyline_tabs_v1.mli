open! Core
open! Bonsai_web

module type Tab = sig
  type t [@@deriving equal]

  val icon : t -> Codicons.t
  val label : t -> string
end

type 'tab t

(** Construct a tabs component which can be used to render a list of tabs and retrive the
    currently active tab. *)
val component
  :  (module Tab with type t = 'tab)
  -> ?state:'tab Bonsai.t * ('tab -> unit Effect.t) Bonsai.t
  -> ?notifications:('tab, _) Set.t Bonsai.t
  -> ?secondary:'tab list Bonsai.t
  -> 'tab Nonempty_list.t Bonsai.t
  -> local_ Bonsai.graph
  -> 'tab t Bonsai.t

(** The currently active tab. *)
val current : 'tab t -> 'tab

(** Update the current tab. *)
val change : 'tab t -> 'tab -> unit Effect.t

(** Renders the list of tabs. *)
val view : _ t -> Vdom.Node.t
