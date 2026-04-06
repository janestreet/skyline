open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

let component ?size ?intent icon = Codicons.svg ?size ?color:intent icon
let component' ?size ?intent ~icon () = component ?size ?intent icon
