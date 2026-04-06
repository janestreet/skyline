open! Core
open! Bonsai_web

type t =
  [ `Idle of unit Effect.t
  | `Copied
  ]

val text : string Bonsai.t -> local_ Bonsai.graph -> t Bonsai.t
val html : string Bonsai.t -> local_ Bonsai.graph -> t Bonsai.t

val link
  :  url:string Bonsai.t
  -> title:string Bonsai.t
  -> local_ Bonsai.graph
  -> t Bonsai.t

val text_effect : string -> unit Effect.t
val html_effect : string -> unit Effect.t
val link_effect : url:string -> title:string -> unit Effect.t

val icon_button
  :  ?test_selector:Test_selector.t
  -> ?tooltip:string Bonsai.t
  -> ?icon:Codicons.t
  -> ?intent:Skyline_theme_v1.Color.t
  -> text:string Bonsai.t
  -> Bonsai.graph @ local
  -> Vdom.Node.t Bonsai.t
