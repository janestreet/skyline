open! Core
open Import

(** Style config for the panel. Includes hooks for all the non-functional attributes. *)
module Style_config : sig
  type t =
    { container_attr :
        drag_state:[ `Drag_in_progress | `Static ]
        -> direction:[ `Horizontal | `Vertical ]
        -> child_count:int
        -> Attr.t
    ; container_border :
        width:Css_gen.Length.t option
        * color:Css_gen.Color.t option
        * radius:Css_gen.Length.t option
    ; title_attr : [ `Collapsed_vertical | `Collapsed_horizontal | `Expanded ] -> Attr.t
    ; tab_attr :
        active:[ `Active | `Inactive ]
        -> collapsed:[ `Collapsed_vertical | `Collapsed_horizontal | `Expanded ]
        -> Attr.t
    ; tab_badge_attr : Attr.t
    ; divider_style :
        drag_state:[ `Drag_in_progress | `Static ]
        -> border_width:Css_gen.Length.t
           * border_color:Css_gen.Color.t
           * foreground_color:Css_gen.Color.t
           * background_color:Css_gen.Color.t
    ; divider_attr :
        drag_state:[ `Drag_in_progress | `Static ]
        -> direction:[ `Horizontal | `Vertical ]
        -> Attr.t
    ; icon_color : Css_gen.Color.t
    }
  [@@deriving fields ~getters]
end

module Content : sig
  type 'a t = 'a Bonsai.t -> local_ Bonsai.graph -> Node.t Bonsai.t
end

(** Create a panel using a [Config.t].

    @param open_config_editor
      Provide an easy button to edit content configs, letting users change panel types and
      their settings.
    @param custom_header
      A hook to render a custom element in the header based on the contained panel config
    @param style_config The non-functional style of the panel.
    @param logic A [Logic.t] that holds the state for the panel and how to change it.
    @param content A function that maps a panel type to some content *)
val component
  :  ?open_config_editor:
       (update:('a -> unit Effect.t) Bonsai.t
        -> 'a Bonsai.t
        -> local_ Bonsai.graph
        -> A.t Bonsai.t)
  -> ?custom_header:
       (collapsed:Logic.Direction.t option Bonsai.t
        -> 'a Bonsai.t
        -> local_ Bonsai.graph
        -> N.t Bonsai.t)
  -> style_config:Style_config.t Bonsai.t
  -> logic:'a Logic.t Bonsai.t
  -> content:'a Content.t
  -> local_ Bonsai.graph
  -> Node.t Bonsai.t
