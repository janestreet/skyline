open! Core
open! Bonsai_web

(** [component ~intent ~icon label] renderes a placeholder element that can be used for
    empty states (but that also works e.g. for an error state). *)
val component
  :  ?action:string * unit Effect.t
  -> ?intent:Skyline_theme_v1.Color.t
  -> icon:Codicons.t
  -> string
  -> Vdom.Node.t

(** A specialized placeholder component that displays an error. This is ethically
    equivalent to [component ~intent:Error ~icon:Error (Error.to_string_hum error)]. *)
val error
  :  ?action:string * unit Effect.t
  -> ?intent:Skyline_theme_v1.Color.t
  -> ?icon:Codicons.t
  -> Error.t
  -> Vdom.Node.t
