open! Core
open! Import
open Bonsai_web
open Bonsai.Let_syntax

module Style_config = struct
  type t =
    { presets_attr : A.t
    ; panel_attr : A.t
    ; wrapper_attr : A.t
    ; render_icon : [ `Content_config | `Hidden | `Shown ] -> N.t
    }
  [@@deriving fields ~getters]
end

let default_style =
  { Style_config.presets_attr =
      [%css
        {|
          display: flex;
          flex-direction: column;
          align-items: stretch;

          & .title {
            font-weight: bold;
          }

          & div > *:hover {
            cursor: pointer;
            user-select: none;
          }
        |}]
  ; panel_attr = [%css "padding-left: 0.4em;"]
  ; wrapper_attr =
      [%css
        {|
          padding: 0.2em;
          padding-left: 0;
          cursor: pointer;
        |}]
  ; render_icon =
      (function
        | `Content_config -> Codicons.svg ~color:(`Hex "1c2127") Codicons.Gear
        | `Hidden -> Codicons.svg ~color:(`Hex "1c2127") Codicons.Eye_closed
        | `Shown -> Codicons.svg ~color:(`Hex "1c2127") Codicons.Eye)
  }
;;

let child_config_buttons ~open_config_editor ~config ~inject (local_ graph) =
  match%sub config with
  | { Bonsai_web_panel_config.config = Content content; _ } ->
    (match open_config_editor with
     | Some open_config_editor ->
       let%arr config_edit_effect =
         open_config_editor
           ~update:
             (let%arr inject in
              fun content -> inject (Logic.Action.Set_content content))
           content
           graph
       in
       [ `Content_config, A.on_click (fun _ -> config_edit_effect) ]
     | None -> Bonsai.return [])
  | _ -> Bonsai.return []
;;

let child_config_panel_type ~config =
  match config with
  | { Bonsai_web_panel_config.config = Content _; _ } -> "Untitled panel"
  | { Bonsai_web_panel_config.config = Tabbed _; _ } -> "Untitled tab stack"
  | { Bonsai_web_panel_config.config = Horizontal_fixed _; _ } ->
    "Untitled horizontal stack"
  | { Bonsai_web_panel_config.config = Vertical_fixed _; _ }
  | { Bonsai_web_panel_config.config = Vertical_variable _; _ } ->
    "Untitled vertical stack"
;;

let single_panel_row ~style_config ~config ~title =
  let%arr { Style_config.panel_attr; render_icon; _ } = style_config
  and title
  and config in
  fun ~buttons ->
    let title =
      Option.value_map
        title
        ~default:(`Unnamed, child_config_panel_type ~config)
        ~f:(Tuple2.create `Named)
    in
    let title =
      let italics =
        match fst title with
        | `Named -> A.empty
        | `Unnamed -> [%css {|font-style: italic;|}]
      in
      let title = Vdom.Node.text (snd title) in
      {%html|
        <div style="flex-grow: 1; padding-right: 1em" %{italics}>
          %{title}
        </div>
      |}
    in
    let buttons =
      List.map
        ~f:(fun (icon, on_click) ->
          let icon = render_icon icon in
          let icon =
            match icon with
            | N.Widget _ -> N.div [ icon ]
            | _ -> icon
          in
          match icon with
          | N.Element e ->
            N.Element (N.Element.map_attrs ~f:(fun a -> A.many [ on_click; a ]) e)
          | _ -> icon)
        buttons
    in
    {%html|
      <div
        %{panel_attr}
        style="display: flex; flex-direction: row; justify-content: space-between"
      >
        %{title}
        <div style="display: flex; flex-direction: row; flex: 0 0 auto">
          *{buttons}
        </div>
      </div>
    |}
    |> Option.return
;;

let panel_layout_options ~open_config_editor ~style_config ~recurse state (local_ graph)
  : N.t list Bonsai.t
  =
  let%sub ~config, ~inject, ~child_layout = state in
  let layout =
    let%arr child_layout in
    let%map.Option _, layout = child_layout in
    layout
  in
  match%sub config with
  | { Bonsai_web_panel_config.config = Content _; _ } -> Bonsai.return []
  | { Bonsai_web_panel_config.config =
        Horizontal_fixed _ | Vertical_variable _ | Vertical_fixed _
    ; _
    } ->
    let child_layouts =
      let%arr config in
      Bonsai_web_panel_config.child_float_layouts config |> Option.value_exn
    in
    let child_configs =
      let%arr config in
      Bonsai_web_panel_config.child_configs config |> Option.value_exn
    in
    let children_with_ids =
      let%arr child_configs and child_layouts in
      let children =
        Bonsai_web_panel_config.create_children child_configs child_layouts
      in
      List.mapi children ~f:(fun index (config, layout) ->
        let panel_id = Bonsai_web_panel_config.panel_id config in
        panel_id, (index, config, layout))
      |> Map.of_alist_exn (module Bonsai_web_panel_config.Panel_id)
    in
    Bonsai.assoc
      (module Bonsai_web_panel_config.Panel_id)
      children_with_ids
      ~f:(fun _panel_id child_data (local_ graph) ->
        let%sub child_index, config, layout = child_data in
        let child_inject =
          let%arr inject and config in
          let panel_id = Bonsai_web_panel_config.panel_id config in
          fun action -> inject (Logic.Action.Update_child_config (~panel_id, ~action))
        in
        let state =
          let%arr config and layout and child_inject and child_index in
          ~config, ~inject:child_inject, ~child_layout:(Some (child_index, layout))
        in
        let hide_button =
          let%arr layout and inject and child_index and child_layouts and config in
          let panel_id = Bonsai_web_panel_config.panel_id config in
          if (not layout.hidden)
             && List.for_alli child_layouts ~f:(fun i other_layout ->
               if i = child_index then true else other_layout.hidden)
          then []
          else
            [ ( (if layout.hidden then `Hidden else `Shown)
              , A.on_click (fun _ ->
                  Effect.Many
                    [ Effect.Stop_propagation
                    ; inject
                        (Logic.Action.Set_hidden (~panel_id, ~hidden:(not layout.hidden)))
                    ]) )
            ]
        in
        let child_buttons =
          let%arr child_buttons =
            child_config_buttons ~open_config_editor ~config ~inject:child_inject graph
          and hide_button in
          child_buttons @ hide_button
        in
        let title =
          let%arr layout in
          Bonsai_web_panel_config.Child_layout.title layout
        in
        let%arr single_panel_row = single_panel_row ~style_config ~title ~config
        and child_buttons
        and child_children = recurse state graph in
        {%html|
          <div>
            ?{single_panel_row ~buttons:child_buttons}
            <div style="padding-left: 1em">*{child_children}</div>
          </div>
        |})
      graph
    >>| Map.data
  | { Bonsai_web_panel_config.config = Tabbed { tabs; _ }; _ } ->
    let tabs_with_ids =
      let%arr tabs in
      Nonempty_list.to_list tabs
      |> List.mapi ~f:(fun tab_index (config, title) ->
        let panel_id = Bonsai_web_panel_config.panel_id config in
        panel_id, (tab_index, config, title))
      |> Map.of_alist_exn (module Bonsai_web_panel_config.Panel_id)
    in
    Bonsai.assoc
      (module Bonsai_web_panel_config.Panel_id)
      tabs_with_ids
      ~f:(fun _panel_id tab_data (local_ graph) ->
        let%sub tab_index, config, title = tab_data in
        let child_inject =
          let%arr inject and config in
          let panel_id = Bonsai_web_panel_config.panel_id config in
          fun action -> inject (Logic.Action.Update_child_config (~panel_id, ~action))
        in
        let child_layout =
          let%arr tab_index and layout in
          let%bind.Option layout in
          (tab_index, layout) |> Option.return
        in
        let state =
          let%arr config and inject and child_layout in
          ~config, ~inject, ~child_layout
        in
        let%arr single_panel_row =
          single_panel_row ~style_config ~title:(title >>| Option.some) ~config
        and child_children = recurse state graph
        and buttons =
          child_config_buttons ~open_config_editor ~config ~inject:child_inject graph
        in
        {%html|
          <div>
            ?{single_panel_row ~buttons}
            <div style="padding-left: 1em">*{child_children}</div>
          </div>
        |})
      graph
    >>| Map.data
;;

let component
  ?(style_config = Bonsai.return default_style)
  ?presets
  ?open_config_editor
  ~logic
  (local_ graph)
  =
  let%sub { Logic.inject; config; set_config } = logic in
  let preset_chooser =
    let%arr { presets_attr; _ } = style_config
    and presets = Bonsai.transpose_opt presets
    and set_config in
    let%map.Option presets in
    let on_click config =
      A.on_click (fun _ -> Effect.Many [ Effect.Stop_propagation; set_config config ])
    in
    let presets =
      Map.to_alist presets
      |> List.map ~f:(fun (name, config) ->
        {%html|<div %{on_click config}>%{name#String}</div>|})
    in
    {%html|
      <div %{presets_attr}>
        <span class="title">Presets</span>
        <div>*{presets}</div>
        <hr style="width: 100%" />
      </div>
    |}
  in
  let state =
    let%arr config and inject in
    ~config, ~inject, ~child_layout:None
  in
  let panel_layout_options =
    Bonsai.fix ~f:(panel_layout_options ~style_config ~open_config_editor) state graph
  in
  let%arr preset_chooser and panel_layout_options in
  {%html|<div>?{preset_chooser} *{panel_layout_options}</div>|}
;;
