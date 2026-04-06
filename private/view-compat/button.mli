open! Core
open! Bonsai_web

val make
  :  attrs:Vdom.Attr.t list
  -> disabled:bool
  -> intent:View.Constants.Intent.t option
  -> tooltip:string option
  -> on_click:unit Effect.t
  -> Vdom.Node.t list
  -> Vdom.Node.t
