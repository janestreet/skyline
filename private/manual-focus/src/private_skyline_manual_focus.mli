open! Core
open! Bonsai_web

val component
  :  Bonsai.graph @ local
  -> Vdom.Attr.t Bonsai.t * (focus:unit Effect.t * blur:unit Effect.t) Bonsai.t
