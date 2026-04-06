open! Core
open! Bonsai_web

(** A simple banner component. *)
val component
  :  intent:Skyline_theme_v1.Color.t
  -> icon:Codicons.t
  -> string
  -> Vdom.Node.t

(** The same as [component], except it allows its children to be anything. Note that the
    contents will be in a span. *)
val component'
  :  intent:Skyline_theme_v1.Color.t
  -> icon:Codicons.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** A vertical banner with the ability to specify dropdown actions. *)
val with_actions
  :  dropdown:unit Skyline_context_menu_v1.t Bonsai.t
  -> intent:Skyline_theme_v1.Color.t Bonsai.t
  -> icon:Codicons.t Bonsai.t
  -> string Bonsai.t
  -> local_ Bonsai.graph
  -> Vdom.Node.t Bonsai.t

(** A full width banner element. The banner comes with the option to expand / collapse
    it's contents as well as optional inline actions and a loading state. *)
val collapsible
  :  ?state:
       [ `Expanded | `Collapsed ] Bonsai.t
       * ([ `Expanded | `Collapsed ] -> unit Effect.t) Bonsai.t
  -> ?intent:Skyline_theme_v1.Color.t Bonsai.t
  -> ?actions:(string * unit Effect.t) list Bonsai.t
  -> ?loading:bool Bonsai.t
  -> title:string Bonsai.t
  -> Vdom.Node.t Bonsai.t
  -> local_ Bonsai.graph
  -> Vdom.Node.t Bonsai.t
