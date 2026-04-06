open! Core
open! Import
module Logic = Logic
module Config = Bonsai_web_panel_config
module Ui = Ui
module Layout_options = Layout_options

module Default_theme = struct
  module Colors = struct
    let panel_background = "#edeff2"
    let panel_text = "#2f343c"
    let panel_hover = "#d3d8de"
    let panel_border = "#e5e8eb"
    let divider_border = "#d3d8de"
    let tab_separator = "#dce0e5"
    let icon = "#1c2127"
    let divider_static_fg = "#333333"
    let divider_static_bg = "#edeff2"
    let divider_drag_fg = "#edeff2"
    let divider_drag_bg = "#333333"
  end

  let transition_duration = "0.15s"

  let title_attr collapsed =
    let base_style =
      [%css
        {|
          gap: 0.4em;
          background-color: %{Colors.panel_background};
          color: %{Colors.panel_text};
          cursor: pointer;

          &:hover {
            background-color: %{Colors.panel_hover};
          }
        |}]
    in
    (function
      | `Collapsed_vertical | `Expanded ->
        [ base_style
        ; [%css
            {|
              padding: 0 0.4em;
              & .title-text {
                padding: 0.4em 0;
              }
            |}]
        ]
      | `Collapsed_horizontal -> [ base_style; [%css {|padding: 0.4em 0;|}] ])
      collapsed
    |> A.many
  ;;

  let tab_attr ~active ~collapsed =
    let active_style =
      match active with
      | `Active -> [%css {|font-weight: bold;|}]
      | `Inactive -> [%css {|font-weight: normal;|}]
    in
    let not_first_style =
      [%css
        {|
          &:not(:first-of-type) {
            padding: 0 0.4em;
            border-left: 2px solid %{Colors.tab_separator};
            align-self: stretch;
          }
        |}]
    in
    let collapsed_style =
      match collapsed with
      | `Collapsed_vertical | `Collapsed_horizontal -> [%css {|padding: 0 0.4em;|}]
      | `Expanded -> A.empty
    in
    A.many [ active_style; not_first_style; collapsed_style ]
  ;;

  let divider_style ~drag_state =
    let foreground_color, background_color =
      match drag_state with
      | `Static -> `Hex Colors.divider_static_fg, `Hex Colors.divider_static_bg
      | `Drag_in_progress -> `Hex Colors.divider_drag_fg, `Hex Colors.divider_drag_bg
    in
    ( ~border_width:(`Px 1)
    , ~border_color:(`Hex Colors.divider_border)
    , ~foreground_color
    , ~background_color )
  ;;

  let container_attr ~drag_state ~direction:_ ~child_count =
    let padding = if child_count = 1 then "0" else "2px" in
    A.many
      [ (match drag_state with
         | `Drag_in_progress -> A.empty
         | `Static ->
           [%css
             {|
               transition: grid-template-rows %{transition_duration} ease-in-out,
                 grid-template-columns %{transition_duration} ease-in-out;
             |}])
      ; [%css
          {|
            padding: %{padding};
            align-items: stretch;
            gap: 2px;
          |}]
      ]
  ;;

  let tab_badge_attr =
    [%css
      {|
        padding: 4px 0px;
        border-radius: 2px;
      |}]
  ;;

  let divider_attr ~drag_state:_ ~direction:_ = A.empty
end

let default_style =
  { Ui.Style_config.container_attr = Default_theme.container_attr
  ; container_border =
      ( ~width:(Some (`Px 1))
      , ~color:(Some (`Hex Default_theme.Colors.panel_border))
      , ~radius:None )
  ; title_attr = Default_theme.title_attr
  ; divider_style = Default_theme.divider_style
  ; icon_color = `Hex Default_theme.Colors.icon
  ; tab_attr = Default_theme.tab_attr
  ; tab_badge_attr = Default_theme.tab_badge_attr
  ; divider_attr = Default_theme.divider_attr
  }
;;

let component
  ?(style_config = Bonsai.return default_style)
  ?open_config_editor
  ?custom_header
  ~logic
  ~(content : 'a Ui.Content.t)
  (local_ graph)
  =
  Ui.component ?open_config_editor ?custom_header ~style_config ~logic ~content graph
;;

let layout_options_component
  ?presets
  ?style_config
  ?open_config_editor
  ~logic
  (local_ graph)
  =
  Layout_options.component ?presets ?style_config ?open_config_editor ~logic graph
;;
