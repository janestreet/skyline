open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  include
    [%css
    stylesheet
      ~dont_hash_prefixes:[ "--skyline" ]
      {|
        .container {
          box-sizing: border-box;
          display: flex;
          margin: 0;
          padding: 0;
          position: relative;
          line-height: inherit;
        }

        .input {
          box-sizing: border-box;
          position: relative;
          width: 100%;
          height: 24px;
          padding: 0 4px;
          margin: 0;

          font-family: var(--skyline-font-sans, sans-serif);
          font-size: 0.8rem;
          font-weight: inherit;
          line-height: 1em;

          color: var(--skyline-color-primary, inherit);
          background-color: var(--skyline-color-surface);
          border-radius: 2px;
          border-width: 1px;
          border-style: solid;
          border-color: var(--skyline-color-border);

          outline: none !important;
        }

        .input:focus,
        .input:active {
          border-color: var(--skyline-color-accent);
        }

        .actions {
          position: absolute;
          top: 2px;
          right: 2px;
          bottom: 2px;
        }

        .action {
          box-sizing: border-box;
          margin: 0;
          padding: 0;

          height: 20px;
          width: 20px;
          display: flex;
          align-items: center;
          justify-content: center;

          border-width: 1px;
          border-style: solid;
          border-radius: 2px;

          border-color: var(--border);
          background-color: var(--background);
          color: var(--color);
        }

        .action:hover {
          background: var(--hover);
        }

        .input.with_actions {
          padding-right: var(--action-width);
        }
      |}]

  let input = Vdom.Attr.many [ input ]

  let with_actions ~count =
    let action_width = Css_gen.Length.to_string_css (`Px (count * 24)) in
    Vdom.Attr.many [ Variables.set ~action_width (); with_actions ]
  ;;

  let action ~border ~color ~background ~hover =
    Vdom.Attr.many [ Variables.set ~border ~background ~hover ~color (); action ]
  ;;
end

module Action = struct
  type t =
    | Single of
        { return_focus_to_input : bool
        ; intent : Skyline_theme_v1.Color.t
        ; tooltip : string
        ; on_click : unit Effect.t
        ; icon : Codicons.t
        }
    | Submenu of
        { return_focus_to_input : bool
        ; intent : Skyline_theme_v1.Color.t
        ; tooltip : string
        ; menu_items : unit Skyline_context_menu_v1.t
        ; icon : Codicons.t
        }
    | Clear

  let single
    ?(return_focus_to_input = true)
    ?(intent = Skyline_theme_v1.primary)
    ?(tooltip = "")
    ~on_click
    icon
    =
    Single { return_focus_to_input; intent; tooltip; on_click; icon }
  ;;

  let submenu
    ?(return_focus_to_input = false)
    ?(intent = Skyline_theme_v1.primary)
    ?(tooltip = "")
    ?(icon = Codicons.Ellipsis)
    menu_items
    =
    Submenu { return_focus_to_input; intent; tooltip; menu_items; icon }
  ;;

  let clear = Clear

  let component ~tooltip ~intent ~on_click icon =
    let tooltip =
      if String.is_empty tooltip then Vdom.Attr.empty else Skyline_tooltip_v1.text tooltip
    in
    let border =
      if Css_gen.Color.equal intent Skyline_theme_v1.primary
      then "#0000"
      else
        Skyline_theme_v1.fade intent (Percent.of_percentage 30.)
        |> Css_gen.Color.to_string_css
    in
    let background =
      if Css_gen.Color.equal intent Skyline_theme_v1.primary
      then "#0000"
      else
        Skyline_theme_v1.fade intent (Percent.of_percentage 20.)
        |> Css_gen.Color.to_string_css
    in
    let hover =
      Skyline_theme_v1.fade intent (Percent.of_percentage 30.)
      |> Css_gen.Color.to_string_css
    in
    Vdom.Node.button
      ~attrs:
        [ Style.action
            ~border
            ~background
            ~hover
            ~color:(Css_gen.Color.to_string_css intent)
        ; tooltip
        ; Vdom.Attr.on_click (fun _ -> on_click)
        ]
      [ Skyline_icon_v1.component ~intent icon ]
  ;;
end

module Input_type = struct
  type t =
    | Text
    | Password
  [@@deriving sexp_of, equal, compare]

  let to_string = function
    | Text -> "text"
    | Password -> "password"
  ;;
end

type t = string Skyline_input_v1.t

let action_buttons ~value ~update ~focus_input actions graph =
  let menu_items, set_menu_items = Bonsai.state [] graph in
  let menu, toggle_menu =
    Skyline_context_menu_v1.manual_popover
      ~position:(return Skyline_popover_v1.Position.Bottom)
      ~alignment:(return Skyline_popover_v1.Alignment.End)
      menu_items
      graph
  in
  let actions =
    let%arr value
    and update
    and focus_input
    and set_menu_items
    and toggle_menu
    and actions in
    List.filter_map
      (actions : Action.t list)
      ~f:(function
        | Single { return_focus_to_input; intent; tooltip; on_click; icon } ->
          let on_click =
            if return_focus_to_input
            then Effect.Many [ on_click; focus_input ]
            else on_click
          in
          Some (Action.component ~intent ~tooltip ~on_click icon)
        | Submenu { return_focus_to_input; intent; tooltip; menu_items; icon } ->
          let on_click =
            let%bind.Effect () = set_menu_items menu_items in
            let%bind.Effect () =
              if return_focus_to_input then focus_input else Effect.return ()
            in
            toggle_menu
          in
          Some (Action.component ~intent ~tooltip ~on_click icon)
        | Clear when not (String.is_empty value) ->
          let on_click = Effect.Many [ update ""; focus_input ] in
          Some
            (Action.component
               ~intent:Skyline_theme_v1.primary
               ~tooltip:""
               ~on_click
               Close)
        | Clear -> None)
  in
  menu, actions
;;

let component
  ?(attrs = Bonsai.return [])
  ?(type_ = Bonsai.return Input_type.Text)
  ?test_selector
  ?state:external_state
  ?(disabled = Bonsai.return false)
  ?(actions = Bonsai.return [])
  ?(autofocus = Bonsai.return false)
  ~placeholder
  graph
  =
  let input_id = Bonsai.path_id graph in
  let value, update =
    match external_state with
    | Some state -> state
    | None -> Bonsai.state ~equal:String.equal "" graph
  in
  let manual_focus, focus_input = Private_skyline_manual_focus.component graph in
  let actions_menu_anchor, actions =
    action_buttons
      ~value
      ~update
      ~focus_input:
        (let%arr ~focus, .. = focus_input in
         focus)
      actions
      graph
  in
  let view =
    let%arr input_id
    and disabled
    and value
    and update
    and actions_menu_anchor
    and actions
    and autofocus =
      match%arr autofocus with
      | true -> Private_skyline_autofocus.focus_on_mount
      | false -> Vdom.Attr.empty
    and manual_focus
    and placeholder
    and attrs
    and type_ in
    let maybe_disabled =
      if disabled
      then Vdom.Attr.many [ [%css {|cursor: not-allowed;|}]; Vdom.Attr.disabled ]
      else Vdom.Attr.empty
    in
    Vdom.Node.div
      ~key:input_id
      ~attrs:[ Style.container ]
      [ Vdom.Node.input
          ~attrs:
            [ Vdom.Attr.id input_id
            ; Vdom.Attr.type_ (Input_type.to_string type_)
            ; Vdom.Attr.value value
            ; Vdom.Attr.placeholder placeholder
            ; Vdom.Attr.on_input (fun _ input -> update input)
            ; autofocus
            ; manual_focus
            ; maybe_disabled
            ; Style.input
            ; (if List.is_empty actions
               then Vdom.Attr.empty
               else Style.with_actions ~count:(List.length actions))
            ; Test_selector.attr_of_opt test_selector
            ; Vdom.Attr.many attrs
            ]
          ()
      ; (if List.is_empty actions
         then Vdom.Node.none
         else View.hbox ~gap:(`Px 2) ~attrs:[ Style.actions; actions_menu_anchor ] actions)
      ]
  in
  Skyline_input_v1.create view value update
;;

let view input = Skyline_input_v1.view input
let value input = Skyline_input_v1.value input
let update input new_value = Skyline_input_v1.update input new_value

module Expert = struct
  let style = Style.input
end
