open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
module Config = Bonsai_web_panel.Config
module Logic = Bonsai_web_panel.Logic
module Ui = Bonsai_web_panel.Ui

let style_config =
  let title_attr collapsed =
    let base_style =
      [%css
        {|
          background-color: transparent;
          color: inherit;

          font-family: var(--skyline-font-sans);
          font-size: 0.6rem;
          line-height: 1.1rem;
          font-weight: 500;

          gap: 0.4em;
          padding: 0 0.4em;

          text-transform: uppercase;

          cursor: pointer;
        |}]
    in
    let collapsed_style =
      match collapsed with
      | `Expanded -> [%css {|border-bottom: 1px dashed var(--skyline-color-border);|}]
      | `Collapsed_horizontal ->
        [%css
          {|
            border: 0px;
            padding: 0.4em 0;
          |}]
      | `Collapsed_vertical -> [%css {|border: 0px;|}]
    in
    Vdom.Attr.many [ base_style; collapsed_style ]
  in
  let container_border = ~width:None, ~color:None, ~radius:None in
  let container_attr ~drag_state ~direction:_ ~child_count:_ =
    Vdom.Attr.many
      [ (match drag_state with
         | `Drag_in_progress -> Vdom.Attr.empty
         | `Static ->
           (* this is essential for panels to inform the user where the panels go to.
              https://m3.material.io/styles/motion/transitions/transition-patterns#b67cba74-6240-4663-a423-d537b6d21187 *)
           let transition_duration = "0.15s" in
           [%css
             {|
               transition: grid-template-rows %{transition_duration} ease-in-out,
                 grid-template-columns %{transition_duration} ease-in-out;
             |}])
      ; [%css {|align-items: stretch;|}]
      ]
  in
  let icon_color = `Inherit in
  let divider_style ~drag_state =
    let border_width, border_color =
      match drag_state with
      | `Drag_in_progress -> `Px 3, Skyline_theme_v1.accent
      | `Static -> `Px 1, Skyline_theme_v1.border
    in
    let transparent = `Name "transparent" in
    ( ~border_width
    , ~border_color
    , ~foreground_color:transparent
    , ~background_color:transparent )
  in
  let divider_attr ~drag_state ~direction =
    let background_color_hover = "var(--skyline-color-accent)" in
    let _background_color =
      match drag_state with
      | `Drag_in_progress -> background_color_hover
      | `Static -> "var(--skyline-color-background)"
    in
    let width, height =
      match direction with
      | `Horizontal -> "2px", "100%"
      | `Vertical -> "100%", "2px"
    in
    Vdom.Attr.many
      [ [%css
          {|
      transition: background-color 0.15s ease-in-out;
      & svg {
        opacity: 1;
        width: %{width};
        height: %{height};
        &:hover rect {
          fill: %{background_color_hover};
        }
      }

;|}]
      ]
  in
  let tab_attr ~active ~collapsed =
    let active_attr =
      match active, collapsed with
      | `Active, `Expanded ->
        [%css
          {|
            border-bottom: 2px solid var(--skyline-color-accent);
            padding: 0 1.4em;

            &:hover {
              border-bottom: 2px solid var(--skyline-color-border);
            }
        |}]
      | _, `Collapsed_horizontal -> [%css {| padding: 0 0.2em; |}]
      | _, _ ->
        [%css
          {|
          border-bottom: 2px solid transparent;
          padding: 0 1.4em;

          &:hover {
            border-bottom: 2px solid var(--skyline-color-border);
          }
        |}]
    in
    Vdom.Attr.many
      [ [%css
          {|
          transition: border-color 0.1s ease-in-out;

          &:not(:first-of-type) {
            align-self: stretch;
          }
        |}]
      ; active_attr
      ]
  in
  { Bonsai_web_panel.default_style with
    container_attr
  ; container_border
  ; title_attr
  ; icon_color
  ; divider_style
  ; divider_attr
  ; tab_attr
  }
;;

let component ~logic ~content (local_ graph) =
  Bonsai_web_panel.component
    ~style_config:(Bonsai.return style_config)
    ~logic
    ~content
    graph
;;

let stack ~create_stack views (local_ graph) =
  let config =
    let%arr views in
    let size =
      match List.length views with
      | 0 -> Config.Size.percent_of_float 1.
      | view_count -> Config.Size.percent_of_float (1. /. Float.of_int view_count)
    in
    List.mapi views ~f:(fun idx _ ->
      ( Config.create_content idx
      , Config.Child_layout.create ~min_size:(Config.Size.Px 24) size ))
    |> create_stack
  in
  let logic = Logic.create ~equal:[%equal: int] ~sexp_of:[%sexp_of: int] ~config graph in
  let content idx (_graph @ local) =
    let%arr idx and views in
    List.nth views idx |> Option.value ~default:Vdom.Node.none
  in
  component ~logic ~content graph
;;

let columns views graph = stack ~create_stack:Config.create_stack_horizontal views graph
let rows views graph = stack ~create_stack:Config.create_stack_vertical_fixed views graph
