open! Core
open! Import
module Logic = Logic
module Config = Bonsai_web_panel_config
module Ui = Ui
module Layout_options = Layout_options

(** [default_style] is a "reasonable", fairly minimal [Style_config.t]. You will likely
    want to write your own using this as a base, or pull a [Style_config.t] from your
    styled component library. *)
val default_style : Ui.Style_config.t

(** Create a panel using a [Config.t].

    @param style_config The non-functional style of the panel.
    @param open_config_editor
      If set, provides an easy button to edit content configs, letting users change panel
      types and their settings. The [Attr.t] can be used for styling the button.
    @param custom_header
      A hook to render a custom element in the header based on the contained panel config
    @param logic A [Logic.t] that holds the state for the panel and how to change it.
    @param content A function that maps a panel type to some content *)
val component
  :  ?style_config:Ui.Style_config.t Bonsai.t
  -> ?open_config_editor:
       (update:('a -> unit Effect.t) Bonsai.t
        -> 'a Bonsai.t
        -> local_ Bonsai.graph
        -> A.t Bonsai.t)
  -> ?custom_header:
       (collapsed:Logic.Direction.t option Bonsai.t
        -> 'a Bonsai.t
        -> local_ Bonsai.graph
        -> N.t Bonsai.t)
  -> logic:'a Logic.t Bonsai.t
  -> content:'a Ui.Content.t
  -> local_ Bonsai.graph
  -> N.t Bonsai.t

(** [layout_options_component] gives you a component that allows users to edit a
    [Config.t]. It's intended to be used alongside [component], but isn't required.

    Some changes the user might want to make to a panel aren't easily exposable in the
    base UI. For example, hiding a panel would have to come with a way to unhide it. This
    component exposes hiding/showing panels and presets. In the future, moving panels
    around will probably live here.

    @param presets Layout presets for the panel
    @param style_config The non-functional style of the Layout_options.
    @param open_config_editor
      If set, a button will be rendered for editing content config, which will run
      [open_config_editor] on click. The returned effect could open a modal / popover for
      editing the selected [config], or set some state that controls an external editing
      component.
    @param logic A [Logic.t] that holds the state for the panel and how to change it. *)
val layout_options_component
  :  ?presets:'a Bonsai_web_panel_config.t String.Map.t Bonsai.t
  -> ?style_config:Layout_options.Style_config.t Bonsai.t
  -> ?open_config_editor:
       (update:('a -> unit Effect.t) Bonsai.t
        -> 'a Bonsai.t
        -> local_ Bonsai.graph
        -> unit Effect.t Bonsai.t)
  -> logic:'a Logic.t Bonsai.t
  -> local_ Bonsai.graph
  -> N.t Bonsai.t
