open! Core
open! Import

module Style_config : sig
  type t =
    { presets_attr : A.t
    ; panel_attr : A.t
    ; wrapper_attr : A.t
    ; render_icon : [ `Content_config | `Hidden | `Shown ] -> N.t
    }
  [@@deriving fields ~getters]
end

val default_style : Style_config.t

(** A UI for toggling the visibility of individual components and stacks, and for using
    presets. *)
val component
  :  ?style_config:Style_config.t Bonsai.t
  -> ?presets:'a Bonsai_web_panel_config.t String.Map.t Bonsai.t
  -> ?open_config_editor:
       (update:('a -> unit Effect.t) Bonsai.t
        -> 'a Bonsai.t
        -> local_ Bonsai.graph
        -> unit Effect.t Bonsai.t)
  -> logic:'a Logic.t Bonsai.t
  -> local_ Bonsai.graph
  -> N.t Bonsai.t
