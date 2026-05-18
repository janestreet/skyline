open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  let mix_background foreground =
    Skyline_theme_v1.ramp foreground (Percent.of_percentage 20.)
    |> Css_gen.Color.to_string_css
  ;;

  let mix_secondary_background foreground =
    Skyline_theme_v1.ramp foreground (Percent.of_percentage 10.)
    |> Css_gen.Color.to_string_css
  ;;

  let common_colors ~intent =
    let foreground =
      match intent with
      | Some intent -> Css_gen.Color.to_string_css intent
      | None -> Css_gen.Color.to_string_css Skyline_theme_v1.primary
    in
    let background = mix_background Skyline_theme_v1.primary in
    let hover_foreground = Css_gen.Color.to_string_css Skyline_theme_v1.background in
    let hover_background =
      match intent with
      | Some intent -> Css_gen.Color.to_string_css intent
      | None -> Css_gen.Color.to_string_css Skyline_theme_v1.primary
    in
    ~foreground, ~background, ~hover_foreground, ~hover_background
  ;;

  let css_reset =
    [%css
      {|
        box-sizing: border-box;
        margin: 0;
        padding: 0;

        font-family: var(--skyline-font-sans, sans-serif);
        line-height: inherit;

        color: inherit;
        background-color: transparent;
        background-image: none;
        border-width: 0;
        border-style: solid;
        -webkit-appearance: button;

        appearance: button;
        cursor: pointer;
      |}]
  ;;

  module Regular = struct
    include
      [%css
      stylesheet
        {|
          .button {
            height: 28px;
            padding: 0 12px;
            column-gap: 4px;

            font-size: 0.8rem;
            font-weight: 600;
            text-decoration: none;
            line-height: 16px;

            display: flex;
            align-items: center;
            justify-content: center;
            white-space: nowrap;

            border-radius: 4px;
            color: var(--foreground);
            background-color: var(--background);
          }

          .button.dropdown {
            height: 28px;
            width: 28px;
            flex-grow: 0;
            flex-shrink: 1;
          }

          .button.enabled {
            cursor: pointer;
          }

          .button.enabled:hover {
            color: var(--hover-foreground);
            background-color: var(--hover-background);
          }

          .button.secondary {
            background-color: unset;
            border-width: 1px;
            border-color: var(--background);
          }

          .button.secondary:hover {
            color: var(--foreground);
            background-color: var(--background);
          }

          .disabled {
            opacity: 0.6;
            cursor: not-allowed;
          }
        |}]

    let colors ~intent =
      let ~foreground, ~background, ~hover_foreground, ~hover_background =
        common_colors ~intent
      in
      Variables.set_all ~foreground ~background ~hover_foreground ~hover_background
    ;;
  end

  module Compact = struct
    include
      [%css
      stylesheet
        {|
          .container {
            height: 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-shrink: 0;

            border-radius: 4px;
            color: var(--foreground);
            background: var(--background);
          }

          .button {
            height: 24px;
            min-width: 24px;
            width: max-content;
            padding: 0;
            padding-left: 4px;
            padding-right: var(--padding-right);

            display: flex;
            justify-content: center;
            align-items: center;
            flex-shrink: 0;
            gap: 2px;
            flex-grow: 1;

            font-size: 0.8rem;
            font-weight: 600;
            text-decoration: none;
            line-height: 24px;
            border-radius: 4px;
          }

          .dropdown {
            height: 24px;
            width: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            border-radius: 4px;
            background: none;
          }

          .container.enabled:hover {
            background-color: var(--secondary-hover-background);
          }
          .container.enabled .dropdown:hover,
          .container.enabled .button:hover {
            color: var(--hover-foreground);
            background-color: var(--hover-background);
          }

          .container.disabled {
            opacity: 0.6;
          }
          .container.disabled .button,
          .container.disabled .dropdown {
            cursor: not-allowed;
          }
        |}]

    let colors ~secondary ~intent =
      let ~foreground, ~background, ~hover_foreground, ~hover_background =
        match secondary with
        | false -> common_colors ~intent
        | true ->
          let foreground =
            match intent with
            | Some intent -> intent
            | None -> Skyline_theme_v1.primary
          in
          let hover_background = mix_background foreground in
          let foreground = Css_gen.Color.to_string_css foreground in
          ~foreground, ~background:"none", ~hover_foreground:foreground, ~hover_background
      in
      let secondary_hover_background =
        if secondary
        then mix_secondary_background Skyline_theme_v1.primary
        else background
      in
      Variables.set_all
        ~foreground
        ~background
        ~hover_foreground
        ~hover_background
        ~secondary_hover_background
    ;;
  end

  module Link = struct
    include
      [%css
      stylesheet
        {|
          .icon {
          }

          .link {
            display: flex;
            flex-direction: row;
            align-items: center;
            text-align: start;
            text-decoration: inherit;
          }

          .link:has(> .icon) {
            column-gap: 4px;
          }

          .link:hover > span {
            text-decoration: underline;
          }

          .link.disabled {
            opacity: 0.8;
            cursor: not-allowed;
          }

          .link.disabled > span {
            text-decoration: line-through;
          }
        |}]
  end
end

let href_and_target href target =
  Vdom.Attr.combine
    (Vdom.Attr.href href)
    (Vdom.Attr.target (Effect.Open_url_target.to_target target))
;;

let regular_impl
  ~attrs
  ~loading
  ~autofocus
  ~disabled
  ~secondary
  ~intent
  ~tooltip
  ~test_selector
  ~on_click
  ~dropdown
  ~icon
  ~label
  =
  let disabled = disabled || loading in
  let autofocus =
    if autofocus && not disabled
    then Private_skyline_autofocus.focus_on_mount
    else Vdom.Attr.empty
  in
  let intent = if loading || disabled then None else intent in
  let attrs_common =
    Vdom.Attr.many
      [ (if disabled
         then Vdom.Attr.many [ Style.Regular.disabled; Vdom.Attr.disabled ]
         else Style.Regular.enabled)
      ; (if secondary then Style.Regular.secondary else Vdom.Attr.empty)
      ]
  in
  let button ~attrs =
    let tooltip =
      match tooltip with
      | Some "" | None -> Vdom.Attr.empty
      | Some text -> Skyline_tooltip_v1.text ~position:Top ~alignment:Center text
    in
    let attrs =
      Style.Regular.colors ~intent
      :: Style.Regular.button
      :: Style.css_reset
      :: tooltip
      :: autofocus
      :: attrs_common
      :: Test_selector.attr_of_opt test_selector
      :: attrs
    in
    let contents =
      let icon =
        if loading
        then Skyline_loading_indicator_v1.spinner ()
        else Option.value_map icon ~f:Codicons.svg ~default:Vdom.Node.none
      in
      [ icon; Vdom.Node.span [ Vdom.Node.text label ] ]
    in
    match on_click with
    | Effect.Open { url; target } when not disabled ->
      Vdom.Node.a ~attrs:(href_and_target url target :: attrs) contents
    | _ ->
      let on_click = if disabled then Effect.Ignore else on_click in
      Vdom.Node.button ~attrs:(Vdom.Attr.on_click (fun _ -> on_click) :: attrs) contents
  in
  match dropdown with
  | Some dropdown ->
    let dropdown =
      let on_click = if disabled then Effect.Ignore else dropdown in
      Vdom.Node.button
        ~attrs:
          [ Style.Regular.colors ~intent:None
          ; Style.Regular.button
          ; Style.css_reset
          ; Style.Regular.dropdown
          ; attrs_common
          ; Vdom.Attr.on_click (fun _ -> on_click)
          ]
        [ Codicons.svg Chevron_down ]
    in
    Skyline_flex_v1.row
      ~attrs
      ~gap:(`Px 2)
      [ button ~attrs:[ Vdom.Attr.style (Css_gen.create ~field:"flex" ~value:"1") ]
      ; dropdown
      ]
  | None -> button ~attrs
;;

let compact_impl
  ~attrs
  ~loading
  ~autofocus
  ~disabled
  ~secondary
  ~intent
  ~tooltip
  ~test_selector
  ~on_click
  ~dropdown
  ~icon
  ~label
  =
  let disabled = disabled || loading in
  let autofocus =
    if autofocus && not disabled
    then Private_skyline_autofocus.focus_on_mount
    else Vdom.Attr.empty
  in
  let intent = if loading || disabled then None else intent in
  let tooltip =
    match tooltip with
    | Some "" | None -> Vdom.Attr.empty
    | Some text -> Skyline_tooltip_v1.text ~position:Top ~alignment:Center text
  in
  let attrs =
    Style.Compact.colors
      ~intent
      ~secondary
      ~padding_right:(if Option.is_some dropdown then "0px" else "4px")
    :: Style.Compact.container
    :: (if disabled
        then Vdom.Attr.many [ Style.Compact.disabled; Vdom.Attr.disabled ]
        else Style.Compact.enabled)
    :: tooltip
    :: attrs
  in
  let button =
    let contents =
      let icon =
        if loading
        then Skyline_loading_indicator_v1.spinner ()
        else Option.value_map icon ~f:Codicons.svg ~default:Vdom.Node.none
      in
      [ icon
      ; (if String.is_empty label
         then Vdom.Node.none
         else Vdom.Node.span [ Vdom.Node.text label ])
      ]
    in
    match on_click with
    | Effect.Open { url; target } when not disabled ->
      Vdom.Node.a
        ~attrs:
          [ Style.Compact.button
          ; Style.css_reset
          ; href_and_target url target
          ; autofocus
          ; Test_selector.attr_of_opt test_selector
          ]
        contents
    | _ ->
      let on_click = if disabled then Effect.Ignore else on_click in
      Vdom.Node.button
        ~attrs:
          [ Style.Compact.button
          ; Style.css_reset
          ; Vdom.Attr.on_click (fun _ -> on_click)
          ; autofocus
          ; Test_selector.attr_of_opt test_selector
          ]
        contents
  in
  let dropdown =
    match dropdown with
    | Some dropdown ->
      let on_click = if disabled then Effect.Ignore else dropdown in
      Vdom.Node.button
        ~attrs:
          [ Style.Compact.dropdown
          ; Style.css_reset
          ; Vdom.Attr.on_click (fun _ -> on_click)
          ]
        [ Codicons.svg ~size:(`Px 8) Triangle_down ]
    | None -> Vdom.Node.none
  in
  Vdom.Node.div ~attrs [ button; dropdown ]
;;

let maybe_confirm_guard ~confirm ~on_click (local_ graph) =
  match%sub confirm with
  | false ->
    let%arr on_click in
    `Idle, on_click
  | true ->
    let confirm = Skyline_confirm_guard_v1.component graph in
    let%arr confirm and on_click in
    let on_click =
      match confirm.stage with
      | `Idle -> confirm.trigger
      | `Cooldown -> Effect.Ignore
      | `Confirm ->
        (* Reset the confirm guard, in case the action finishes before the guard returns
           to the [Idle] stage. *)
        let%bind.Effect () = confirm.reset in
        on_click
    in
    confirm.stage, on_click
;;

let dropdown_menu ~disabled ~on_open menu graph =
  match%sub menu with
  | [] -> return None
  | _ :: _ as menu ->
    let anchor, toggle =
      Skyline_context_menu_v1.manual_popover
        ~position:(return Skyline_popover_v1.Position.Bottom)
        ~alignment:(return Skyline_popover_v1.Alignment.End)
        menu
        graph
    in
    let%arr anchor and toggle and disabled and on_open in
    let open_effect =
      if disabled then Effect.Ignore else Effect.Many [ on_open; toggle ]
    in
    let on_contextmenu =
      Vdom.Attr.on_contextmenu (fun event ->
        Js_of_ocaml.Dom.preventDefault event;
        open_effect)
    in
    Some (Vdom.Attr.combine anchor on_contextmenu, open_effect)
;;

let common_impl
  view_impl
  ?(confirm = Bonsai.return false)
  ?(loading = Bonsai.return `No)
  ?(dropdown = Bonsai.return [])
  ?(on_dropdown_open = Bonsai.return Effect.Ignore)
  ?(autofocus = Bonsai.return false)
  ?(disabled = Bonsai.return false)
  ?(secondary = Bonsai.return false)
  ~intent
  ~tooltip
  ~(test_selector : Test_selector.t option Bonsai.t)
  ~icon
  ~on_click
  label
  graph
  =
  let loading_state = Skyline_loading_state_v1.component graph in
  let on_click =
    let%arr on_click and loading_state in
    Skyline_loading_state_v1.handle loading_state on_click
  in
  let%sub idle_width, track_idle_width =
    match%sub confirm with
    | true ->
      let idle_width, set_idle_width = Bonsai.state 0 graph in
      let track_idle_width_attr =
        let%arr set_idle_width in
        Bonsai_web_element_size_hooks.Size_tracker.on_change
          (fun { border_box = { width; height = _ }; content_box = _ } ->
             set_idle_width (Int.of_float width))
      in
      Bonsai.both idle_width track_idle_width_attr
    | false -> Bonsai.return (0, Vdom.Attr.empty)
  in
  let%sub confirm, on_click = maybe_confirm_guard ~confirm ~on_click graph in
  let dropdown_menu =
    let menu =
      let%arr dropdown and loading_state in
      List.map dropdown ~f:(fun item ->
        Skyline_context_menu_v1.Item.Expert.map_actions
          item
          ~f:(Skyline_loading_state_v1.handle loading_state))
    in
    dropdown_menu ~disabled ~on_open:on_dropdown_open menu graph
  in
  let%arr autofocus
  and disabled
  and loading =
    let%arr loading and loading_state in
    match loading with
    | `No -> false
    | `Yes -> true
    | `While_on_click_in_flight -> Skyline_loading_state_v1.is_loading loading_state
  and secondary
  and confirm
  and idle_width
  and track_idle_width
  and intent
  and tooltip
  and icon
  and on_click
  and dropdown_menu
  and label
  and test_selector in
  let confirm_width =
    match confirm with
    | `Idle -> track_idle_width
    | `Cooldown | `Confirm -> Vdom.Attr.style (Css_gen.min_width (`Px idle_width))
  in
  view_impl
    ~attrs:
      [ Option.value_map dropdown_menu ~f:fst ~default:Vdom.Attr.empty; confirm_width ]
    ~loading
    ~autofocus
    ~disabled
    ~secondary
    ~intent:
      (match confirm with
       | `Idle -> intent
       | _ -> None)
    ~tooltip
    ~test_selector
    ~on_click
    ~dropdown:(Option.map dropdown_menu ~f:snd)
    ~icon:
      (match confirm with
       | `Idle ->
         (match icon with
          | Some Codicons.Blank -> None
          | icon -> icon)
       | `Cooldown | `Confirm -> Some Question)
    ~label:
      (match confirm with
       | `Idle -> label
       | `Cooldown | `Confirm -> "Confirm")
;;

let regular
  ?test_selector
  ?confirm
  ?loading
  ?dropdown
  ?autofocus
  ?disabled
  ?secondary
  ?intent
  ?tooltip
  ?icon
  ~on_click
  label
  graph
  =
  common_impl
    regular_impl
    ?confirm
    ?loading
    ?autofocus
    ?disabled
    ?secondary
    ~intent:(Bonsai.transpose_opt intent)
    ~tooltip:(Bonsai.transpose_opt tooltip)
    ?dropdown
    ~icon:(Bonsai.transpose_opt icon)
    ~on_click
    ~test_selector:(Bonsai.transpose_opt test_selector)
    label
    graph
;;

let regular'
  ?test_selector
  ?(autofocus = false)
  ?(disabled = false)
  ?(secondary = false)
  ?intent
  ?tooltip
  ?icon
  ~on_click
  label
  =
  regular_impl
    ~attrs:[]
    ~loading:false
    ~autofocus
    ~disabled
    ~secondary
    ~intent
    ~tooltip
    ~on_click
    ~dropdown:None
    ~test_selector
    ~icon
    ~label
;;

let compact
  ?test_selector
  ?confirm
  ?loading
  ?dropdown
  ?autofocus
  ?disabled
  ?secondary
  ?intent
  ?tooltip
  ?icon
  ~on_click
  label
  graph
  =
  common_impl
    compact_impl
    ?confirm
    ?loading
    ?autofocus
    ?disabled
    ?secondary
    ~intent:(Bonsai.transpose_opt intent)
    ~tooltip:(Bonsai.transpose_opt tooltip)
    ?dropdown
    ~test_selector:(Bonsai.transpose_opt test_selector)
    ~icon:(Bonsai.transpose_opt icon)
    ~on_click
    label
    graph
;;

let compact'
  ?test_selector
  ?(autofocus = false)
  ?(disabled = false)
  ?(secondary = false)
  ?intent
  ?tooltip
  ?icon
  ~on_click
  label
  =
  compact_impl
    ~attrs:[]
    ~loading:false
    ~autofocus
    ~disabled
    ~secondary
    ~intent
    ~tooltip
    ~test_selector
    ~on_click
    ~dropdown:None
    ~icon
    ~label
;;

let icon ?test_selector ?loading ?dropdown ?disabled ?intent ?tooltip ~on_click icon graph
  =
  common_impl
    compact_impl
    ~confirm:(Bonsai.return false)
    ?loading
    ~autofocus:(Bonsai.return false)
    ?disabled
    ~secondary:(Bonsai.return true)
    ~intent:(Bonsai.transpose_opt intent)
    ~tooltip:(Bonsai.transpose_opt tooltip)
    ?dropdown
    ~icon:(Bonsai.map icon ~f:Option.some)
    ~test_selector:(Bonsai.transpose_opt test_selector)
    ~on_click
    (return "")
    graph
;;

let icon' ?test_selector ?(disabled = false) ?intent ?tooltip ~on_click icon =
  compact_impl
    ~attrs:[]
    ~loading:false
    ~autofocus:false
    ~disabled
    ~secondary:true
    ~intent
    ~tooltip
    ~test_selector
    ~on_click
    ~dropdown:None
    ~icon:(Some icon)
    ~label:""
;;

let link
  ?test_selector
  ?(disabled = false)
  ?(intent = Skyline_theme_v1.accent)
  ?(font = Skyline_text_v1.Font_family.Sans_serif)
  ?(size = Skyline_text_v1.Font_size.Regular)
  ?(style = Skyline_text_v1.Font_style.Regular)
  ?icon
  ~on_click
  label
  =
  let attrs =
    [ Style.Link.link
    ; Style.css_reset
    ; (if disabled
       then Vdom.Attr.many [ Style.Link.disabled; Vdom.Attr.disabled ]
       else Vdom.Attr.empty)
    ; Test_selector.attr_of_opt test_selector
    ]
  in
  let text = Skyline_text_v1.span ~font ~intent ~size ~style label in
  let content =
    match icon with
    | None -> [ text ]
    | Some icon ->
      [ Codicons.svg icon ~extra_attrs:[ Style.Link.icon ] ~color:intent; text ]
  in
  match on_click with
  | Effect.Open { url; target } when not disabled ->
    Vdom.Node.a ~attrs:(href_and_target url target :: attrs) content
  | _ ->
    let on_click =
      Vdom.Attr.on_click (fun _ -> if disabled then Effect.Ignore else on_click)
    in
    Vdom.Node.button ~attrs:(on_click :: attrs) content
;;

let with_error_common
  ?test_selector
  ?confirm
  ?(loading = Bonsai.return `While_on_click_in_flight)
  ?(dropdown = Bonsai.return [])
  ?on_dropdown_open
  ?autofocus
  ?disabled
  ?secondary
  ?intent
  ?tooltip
  ?icon
  impl
  ~on_click
  label
  (local_ graph)
  =
  let error_handler = Skyline_errors_v1.component graph in
  let error_notification =
    let%arr toast = Skyline_toast_v1.error graph in
    function%bind.Effect
    | Ok _ as ok -> Effect.return ok
    | Error error ->
      let%map.Effect () = toast error in
      Error error
  in
  let on_click =
    let%arr error_handler and error_notification and on_click in
    let%bind.Effect () = Skyline_errors_v1.clear error_handler in
    on_click |> error_notification |> Skyline_errors_v1.handle error_handler
  in
  let dropdown =
    let%arr error_handler and error_notification and dropdown in
    List.map dropdown ~f:(fun item ->
      Skyline_context_menu_v1.Item.Expert.map_actions item ~f:(fun effect ->
        effect |> error_notification |> Skyline_errors_v1.handle error_handler))
  in
  let%sub label, intent, icon, tooltip =
    let%arr error_handler
    and label
    and intent = Bonsai.transpose_opt intent
    and icon = Bonsai.transpose_opt icon
    and tooltip = Bonsai.transpose_opt tooltip in
    match Skyline_errors_v1.errors error_handler with
    | [] -> label, intent, icon, tooltip
    | error :: _ ->
      ( [%string "Retry %{label}"]
      , Some Skyline_theme_v1.error
      , Some Codicons.Refresh
      , Some (Error.to_string_hum error) )
  in
  common_impl
    impl
    ?confirm
    ~loading
    ~dropdown
    ?on_dropdown_open
    ?autofocus
    ?disabled
    ?secondary
    ~intent
    ~tooltip
    ~icon
    ~test_selector:(Bonsai.transpose_opt test_selector)
    ~on_click
    label
    graph
;;

let with_error
  ?test_selector
  ?confirm
  ?loading
  ?dropdown
  ?on_dropdown_open
  ?autofocus
  ?disabled
  ?secondary
  ?intent
  ?tooltip
  ?icon
  ~on_click
  label
  (local_ graph)
  =
  with_error_common
    ?test_selector
    ?confirm
    ?loading
    ?dropdown
    ?on_dropdown_open
    ?autofocus
    ?disabled
    ?secondary
    ?intent
    ?tooltip
    ?icon
    regular_impl
    ~on_click
    label
    graph
;;

let with_error_compact
  ?test_selector
  ?confirm
  ?loading
  ?dropdown
  ?on_dropdown_open
  ?autofocus
  ?disabled
  ?secondary
  ?intent
  ?tooltip
  ?icon
  ~on_click
  label
  (local_ graph)
  =
  with_error_common
    ?test_selector
    ?confirm
    ?loading
    ?dropdown
    ?on_dropdown_open
    ?autofocus
    ?disabled
    ?secondary
    ?intent
    ?tooltip
    ?icon
    compact_impl
    ~on_click
    label
    graph
;;
