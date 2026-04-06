open! Core
open Bonsai_web

module Event : sig
  type t =
    | Toggle_expanded
    | Expand
  [@@deriving sexp_of]
end

module Action : sig
  type 'a t =
    | Toggle_expanded of Bonsai_web_panel_config.Panel_id.t
    | Expand of Bonsai_web_panel_config.Panel_id.t
    | Update_size of
        (panel_id:Bonsai_web_panel_config.Panel_id.t * offset:int * parent_size:int)
    | Change_tab of (panel_id:Bonsai_web_panel_config.Panel_id.t * trigger_collapse:bool)
    | Set_hidden of (panel_id:Bonsai_web_panel_config.Panel_id.t * hidden:bool)
    | Set_title of (panel_id:Bonsai_web_panel_config.Panel_id.t * title:string)
    | Bubble of Event.t
    | Set_content of 'a
    | Update_child_config of (panel_id:Bonsai_web_panel_config.Panel_id.t * action:'a t)
  [@@deriving sexp_of]
end

type 'a t =
  { config : 'a Bonsai_web_panel_config.t
  ; set_config : 'a Bonsai_web_panel_config.t -> unit Effect.t
  ; inject : 'a Action.t -> unit Effect.t
  }
[@@deriving fields ~getters]

val inject_action
  :  'a Bonsai_web_panel_config.t
  -> 'a Action.t
  -> 'a Bonsai_web_panel_config.t

(** Make a panel logic component.

    @param equal Equality for 'a
    @param config
      Initial and override [Config.t] for the panel layout. Updating this will override
      the panel's content *)
val create
  :  ?set_config:('a Bonsai_web_panel_config.t -> unit Effect.t) Bonsai.t
  -> equal:('a -> 'a -> bool)
  -> sexp_of:('a -> Sexp.t)
  -> config:'a Bonsai_web_panel_config.t Bonsai.t
  -> local_ Bonsai.graph
  -> 'a t Bonsai.t

module Child_sizes : sig
  (** A list of sizes for each child, [None] if the child is collapsed. *)
  type size_tuple =
    min_size:Bonsai_web_panel_config.Size.t * size:Bonsai_web_panel_config.Size.t
  [@@deriving sexp, equal]

  type t =
    | Horizontal_fixed of size_tuple option list
    | Vertical_fixed of size_tuple option list
    | Vertical_variable of size_tuple option list
  [@@deriving sexp, equal]

  val of_config : 'a Bonsai_web_panel_config.t Bonsai.t -> t option Bonsai.t
end

module Parent_layout_type : sig
  type t =
    | Fixed
    | Variable
  [@@deriving sexp_of]

  val of_config_exn : 'a Bonsai_web_panel_config.config -> t
end

module Direction : sig
  type t =
    | Horizontal
    | Vertical

  val of_config_exn : 'a Bonsai_web_panel_config.config -> t
end

(** Checks if a divider should be shown at the end (right / bottom) for a specific child *)
val child_has_divider
  :  child_layouts:Bonsai_web_panel_config.Child_layout.t list
  -> parent_layout_type:Parent_layout_type.t
  -> index:int
  -> bool

module For_testing : sig
  val child_sizes
    :  child_layouts:Bonsai_web_panel_config.Child_layout.t list
    -> (min_size:Bonsai_web_panel_config.Size.t * size:Bonsai_web_panel_config.Size.t)
         option
         list
end
