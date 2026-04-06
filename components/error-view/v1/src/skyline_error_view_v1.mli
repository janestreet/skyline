open! Core
open! Bonsai_web

val component
  :  Skyline_errors_v1.t Bonsai.t
  -> Bonsai.graph @ local
  -> Vdom.Node.t option Bonsai.t
