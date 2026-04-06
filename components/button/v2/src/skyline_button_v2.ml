open! Core
open! Private_skyline_prelude

module Variant = struct
  type t =
    | Filled
    | Ghost
    | Outlined
    | Link
    | Soft
  [@@deriving enumerate, to_string]
end

module Loading = struct
  type t =
    | Yes
    | No
    | While_effect_in_progress
  [@@deriving enumerate, to_string]
end

module Style = struct
  let button_base =
    Attr.many
      [ {%css|
          -webkit-appearance: button;
          appearance: button;
          display: inline-flex;
          flex-shrink: 0;
          justify-content: center;
          align-items: center;
          position: relative;
          width: max-content;
          user-select: none;
          &.for-testing--force-focus-visible,
          &:focus-visible {
            outline-style: solid;
          }
        |}
      ; Classes.font_medium
      ]
  ;;

  let size_styles (size : Skyline_size.t) ~rounded ~slim =
    let height_dependent height =
      let border_radius = if rounded then height / 2 else 4 in
      let min_width = if slim then 0 else height in
      {%css|
        border-radius: %{`Px border_radius#Css_gen.Length};
        min-height: %{`Px height#Css_gen.Length};
        min-width: %{`Px min_width#Css_gen.Length};

        /* Button group support: adjust border-radius when inside a button group */
        [data-skyline-button-group] > & {
          border-radius: 0;
        }
        [data-skyline-button-group] > &:first-child {
          border-top-left-radius: %{`Px border_radius#Css_gen.Length};
          border-bottom-left-radius: %{`Px border_radius#Css_gen.Length};
        }
        [data-skyline-button-group] > &:last-child {
          border-top-right-radius: %{`Px border_radius#Css_gen.Length};
          border-bottom-right-radius: %{`Px border_radius#Css_gen.Length};
        }
        [data-skyline-button-group] > &:not(:first-child) {
          border-left-width: 0;
        }
        [data-skyline-button-group] > &:only-child {
          border-radius: %{`Px border_radius#Css_gen.Length};
        }
      |}
    in
    match size with
    | `Xs ->
      let padding_x = if slim then 2 else 3 in
      Attr.many
        [ height_dependent 18
        ; {%css|
            padding: 0px %{`Px padding_x#Css_gen.Length};
            gap: 2px;
            font-size: 12px;
            line-height: 16px;
          |}
        ]
    | `Sm ->
      let padding_x = if slim then 3 else 7 in
      Attr.many
        [ height_dependent 24
        ; {%css|
            padding: 3px %{`Px padding_x#Css_gen.Length};
            gap: 2px;
            font-size: 12px;
            line-height: 16px;
          |}
        ]
    | `Md ->
      let padding_x = if slim then 4 else 7 in
      Attr.many
        [ height_dependent 28
        ; {%css|
            padding: 3px %{`Px padding_x#Css_gen.Length};
            gap: 4px;
            font-size: 14px;
            line-height: 20px;
          |}
        ]
    | `Lg ->
      let padding_x = if slim then 4 else 11 in
      Attr.many
        [ height_dependent 32
        ; {%css|
            padding: 3px %{`Px padding_x#Css_gen.Length};
            gap: 4px;
            font-size: 16px;
            line-height: 24px;
          |}
        ]
  ;;

  let variant_styles variant ~intent ~disabled =
    let base =
      {%css|
        background-clip: border-box;
        border-width: 1px;
        border-style: solid;
        outline-width: 2px;
        outline-offset: 2px;

        @media not (prefers-reduced-motion: reduce) {
          transition: background 0.2s ease, color 0.2s ease, border-color 0.2s ease,
            opacity 0.2s ease;
        }

        &:hover,
        &.for-testing--force-hover,
        &:active,
        &.for-testing--force-active {
          text-decoration: none;
        }
        &:disabled {
          opacity: 50%;
          cursor: default;
        }
      |}
    in
    let fg_class =
      match (variant : Variant.t), intent with
      | Filled, `Primary -> Classes.text_on_filled_primary
      | Filled, `Secondary -> Classes.text_on_filled_secondary
      | Filled, `Danger -> Classes.text_on_filled_danger
      | Filled, `Success -> Classes.text_on_filled_success
      | Filled, `Warning -> Classes.text_on_filled_warning
      | Soft, `Primary -> Classes.text_on_soft_primary
      | Soft, `Secondary -> Classes.text_on_soft_secondary
      | Soft, `Danger -> Classes.text_on_soft_danger
      | Soft, `Success -> Classes.text_on_soft_success
      | Soft, `Warning -> Classes.text_on_soft_warning
      | Ghost, `Primary -> Classes.text_primary
      | Ghost, `Secondary -> Classes.text_secondary
      | Ghost, `Danger -> Classes.text_danger
      | Ghost, `Success -> Classes.text_success
      | Ghost, `Warning -> Classes.text_warning
      | Outlined, `Primary -> Classes.text_primary
      | Outlined, `Secondary -> Classes.text_secondary
      | Outlined, `Danger -> Classes.text_danger
      | Outlined, `Success -> Classes.text_success
      | Outlined, `Warning -> Classes.text_warning
      | Link, `Primary -> Classes.text_primary
      | Link, `Secondary -> Classes.text_secondary
      | Link, `Danger -> Classes.text_danger
      | Link, `Success -> Classes.text_success
      | Link, `Warning -> Classes.text_warning
    in
    let bg_class =
      match (variant : Variant.t), intent with
      | Filled, `Primary -> Classes.bg_primary
      | Filled, `Secondary -> Classes.bg_secondary
      | Filled, `Danger -> Classes.bg_danger
      | Filled, `Success -> Classes.bg_success
      | Filled, `Warning -> Classes.bg_warning
      | Soft, `Primary -> Classes.bg_soft_primary
      | Soft, `Secondary -> Classes.bg_soft_secondary
      | Soft, `Danger -> Classes.bg_soft_danger
      | Soft, `Success -> Classes.bg_soft_success
      | Soft, `Warning -> Classes.bg_soft_warning
      | (Ghost | Outlined | Link), _ -> {%css|background-color: transparent;|}
    in
    let hover_class =
      match (variant : Variant.t), intent with
      | Filled, `Primary -> Classes.bg_primary_hover
      | Filled, `Secondary -> Classes.bg_secondary_hover
      | Filled, `Danger -> Classes.bg_danger_hover
      | Filled, `Success -> Classes.bg_success_hover
      | Filled, `Warning -> Classes.bg_warning_hover
      | Soft, `Primary -> Classes.bg_soft_primary_hover
      | Soft, `Secondary -> Classes.bg_soft_secondary_hover
      | Soft, `Danger -> Classes.bg_soft_danger_hover
      | Soft, `Success -> Classes.bg_soft_success_hover
      | Soft, `Warning -> Classes.bg_soft_warning_hover
      | Ghost, `Primary -> Classes.bg_primary_ghost_hover
      | Ghost, `Secondary -> Classes.bg_secondary_ghost_hover
      | Ghost, `Danger -> Classes.bg_danger_ghost_hover
      | Ghost, `Success -> Classes.bg_success_ghost_hover
      | Ghost, `Warning -> Classes.bg_warning_ghost_hover
      | Outlined, `Primary -> Classes.bg_primary_ghost_hover
      | Outlined, `Secondary -> Classes.bg_secondary_ghost_hover
      | Outlined, `Danger -> Classes.bg_danger_ghost_hover
      | Outlined, `Success -> Classes.bg_success_ghost_hover
      | Outlined, `Warning -> Classes.bg_warning_ghost_hover
      | Link, _ ->
        {%css|
          background-color: transparent;
          &:hover,
          &.for-testing--force-hover {
            text-decoration: underline;
          }
        |}
    in
    let active_bg_class =
      match (variant : Variant.t), intent with
      | Filled, `Primary -> Classes.bg_primary_active
      | Filled, `Secondary -> Classes.bg_secondary_active
      | Filled, `Danger -> Classes.bg_danger_active
      | Filled, `Success -> Classes.bg_success_active
      | Filled, `Warning -> Classes.bg_warning_active
      | Soft, `Primary -> Classes.bg_soft_primary_active
      | Soft, `Secondary -> Classes.bg_soft_secondary_active
      | Soft, `Danger -> Classes.bg_soft_danger_active
      | Soft, `Success -> Classes.bg_soft_success_active
      | Soft, `Warning -> Classes.bg_soft_warning_active
      | Ghost, `Primary -> Classes.bg_primary_ghost_active
      | Ghost, `Secondary -> Classes.bg_secondary_ghost_active
      | Ghost, `Danger -> Classes.bg_danger_ghost_active
      | Ghost, `Success -> Classes.bg_success_ghost_active
      | Ghost, `Warning -> Classes.bg_warning_ghost_active
      | Outlined, `Primary -> Classes.bg_primary_ghost_active
      | Outlined, `Secondary -> Classes.bg_secondary_ghost_active
      | Outlined, `Danger -> Classes.bg_danger_ghost_active
      | Outlined, `Success -> Classes.bg_success_ghost_active
      | Outlined, `Warning -> Classes.bg_warning_ghost_active
      | Link, _ -> {%css|background-color: transparent;|}
    in
    let border_class =
      match (variant : Variant.t), intent with
      | Outlined, `Primary -> Classes.border_primary
      | Outlined, `Secondary -> Classes.border_default
      | Outlined, `Danger -> Classes.border_danger
      | Outlined, `Success -> Classes.border_success
      | Outlined, `Warning -> Classes.border_warning
      | (Filled | Soft | Ghost | Link), _ -> {%css|border-color: transparent;|}
    in
    let focus_outline_class =
      match (variant : Variant.t), intent with
      | _, `Primary -> Classes.outline_primary_focus_visible
      | _, `Secondary -> Classes.outline_primary_focus_visible
      | _, `Danger -> Classes.outline_danger_focus_visible
      | _, `Success -> Classes.outline_success_focus_visible
      | _, `Warning -> Classes.outline_warning_focus_visible
    in
    Attr.many
      [ base
      ; fg_class
      ; bg_class
      ; (if disabled then Attr.empty else hover_class)
      ; (if disabled then Attr.empty else active_bg_class)
      ; border_class
      ; focus_outline_class
      ]
  ;;

  module Loading =
    [%css
    stylesheet
      {|
        .container {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          overflow: hidden;
          display: flex;
          gap: inherit;
          justify-content: center;
          align-items: center;
          flex-wrap: wrap;
          padding: 0 2px;
        }
        @keyframes spin {
          to {
            transform: rotate(360deg);
          }
        }
        .spinner-animation {
          animation: spin 2s linear infinite;
          @media (prefers-reduced-motion) {
            animation: none;
          }
          display: inline-grid;
          place-items: center;
          /* Making the height 100% combined with overflow: hidden on the parent means
             any content that doesn't fit next to the spinner (which gets wrapped) will be
             hidden. */
          height: 100%;
        }
        .hidden-children {
          visibility: hidden;
        }
      |}]

  module Icon = struct
    module Stylesheet =
      [%css
      stylesheet
        {|
          .icon {
            display: inline;
          }

          .xs {
            --size: 10px;

            &.has_one_child:has(> .icon) {
              padding: 4px;
            }
          }
          .sm {
            --size: 12px;

            &.has_one_child:has(> .icon) {
              padding: 6px;
            }
          }
          .md {
            --size: 12px;

            &.has_one_child:has(> .icon) {
              padding: 8px;
            }
          }
          .lg {
            --size: 16px;

            &.has_one_child:has(> .icon) {
              padding: 8px;
            }
          }
        |}]

    let attrs ~size ~num_children ~slim =
      let size_class =
        match size with
        | `Xs -> Stylesheet.xs
        | `Sm -> Stylesheet.sm
        | `Md -> Stylesheet.md
        | `Lg -> Stylesheet.lg
      in
      let has_one_child_class =
        if slim || num_children <> 1 then Attr.empty else Stylesheet.has_one_child
      in
      (* CSS can't detect text nodes, so we add .has_one_child when num_children = 1 *)
      Attr.many [ size_class; has_one_child_class ]
    ;;
  end
end

module Icon = struct
  let view ?(attrs = []) ~icon () =
    {%html|
      <Bonsai_web_icon.view
        *{[ Style.Icon.Stylesheet.icon; Attr.many attrs ]}
        ~size:%{(`Var Style.Icon.Stylesheet.For_referencing.size)}
        ~icon
      />
    |}
  ;;
end

let href_and_target href target =
  Attr.combine (Attr.href href) (Attr.target (Effect.Open_url_target.to_target target))
;;

let spinner () =
  {%html|
    <span %{Style.Loading.spinner_animation}>
      <Icon.view ~icon:%{Lucide.loader_circle} />
    </span>
  |}
;;

let loading_overlay children =
  match Am_running_how_js.am_running_how with
  | `Node_test | `Node_jsdom_test -> {%html|Loading...|}
  | `Browser | `Browser_test | `Browser_benchmark | `Node | `Node_benchmark ->
    {%html|
      <>
        <span %{Style.Loading.container}>
          <%{spinner} />
          Loading
        </span>
        <span %{Style.Loading.hidden_children}>*{children}</span>
      </>
    |}
;;

let with_external_link_indicator contents =
  match Am_running_how_js.am_running_how with
  | `Node_test | `Node_jsdom_test -> contents
  | `Browser | `Browser_test | `Browser_benchmark | `Node | `Node_benchmark ->
    [ {%html|
        <>
          *{contents}
          <Icon.view ~icon:%{Lucide.external_link} />
        </>
      |}
    ]
;;

let view
  ?test_selector
  ?(attrs = [])
  ?(size = `Md)
  ?(slim = false)
  ?(variant = Variant.Filled)
  ?(rounded = false)
  ?(disabled = false)
  ?(loading = false)
  ?(intent : Skyline_intent.t = `Secondary)
  ?tooltip
  ?tooltip_position
  ?(show_external_link_icon = true)
  children
  ~on_click
  =
  let children = if loading then [ loading_overlay children ] else children in
  let disabled = disabled || loading in
  let tooltip =
    match tooltip with
    | Some "" | None -> Attr.empty
    | Some text ->
      Skyline_tooltip_v2.attr
        ?position:tooltip_position
        ~alignment:Center
        (Node.text text)
  in
  let button_attrs =
    [ Test_selector.attr_of_opt test_selector
    ; Style.button_base
    ; Style.size_styles size ~rounded ~slim
    ; Style.variant_styles variant ~intent ~disabled
    ; Style.Icon.attrs ~size ~num_children:(List.length children) ~slim
    ; (if disabled then Classes.disabled else Attr.empty)
    ; tooltip
    ; Classes.data_skyline_component "button"
    ; Attr.many attrs
    ]
  in
  match on_click with
  | Effect.Open { url; target } when not disabled ->
    let children =
      match show_external_link_icon, target with
      | false, _
      | true, (This_tab | Iframe_parent_or_this_tab | Iframe_root_parent_or_this_tab) ->
        children
      | true, New_tab_or_window ->
        {%html|
          <%{with_external_link_indicator}
            >*{children}</>
        |}
    in
    {%html|<a *{[href_and_target url target; Attr.many button_attrs]}>*{children}</a>|}
  | _ ->
    let on_click = if disabled then Effect.Ignore else on_click in
    {%html|<button *{ [Attr.on_click (fun _ -> on_click); Attr.many button_attrs]}>*{children}</button>|}
;;

module Loading_state = struct
  type t =
    { is_loading : bool
    ; handle : 'a. 'a Effect.t -> 'a Effect.t
    }

  let component (local_ graph) =
    let { Bonsai.Toggle.state = is_loading; set_state = set_loading; toggle = _ } =
      Bonsai.toggle' ~default_model:false graph
    in
    let%arr is_loading and set_loading in
    let handle effect =
      let%bind.Effect () = set_loading true in
      let%bind.Effect result = effect in
      let%bind.Effect () = set_loading false in
      Effect.return result
    in
    { is_loading; handle }
  ;;
end

let component
  ?test_selector
  ?(confirm = Bonsai.return false)
  ?(disabled = Bonsai.return false)
  ?(loading = Bonsai.return Loading.No)
  ?(attrs = Bonsai.return [])
  ?(size = Bonsai.return `Md)
  ?(slim = Bonsai.return false)
  ?(variant = Bonsai.return Variant.Filled)
  ?(rounded = Bonsai.return false)
  ?(intent = Bonsai.return `Secondary)
  ?tooltip
  ?tooltip_position
  ?(show_external_link_icon = Bonsai.return true)
  children
  ~on_click
  graph
  =
  let _ = confirm in
  let tooltip = Bonsai.transpose_opt tooltip in
  let test_selector = Bonsai.transpose_opt test_selector in
  let tooltip_position = Bonsai.transpose_opt tooltip_position in
  let loading_state = Loading_state.component graph in
  let%arr loading
  and disabled
  and loading_state
  and variant
  and rounded
  and intent
  and attrs
  and tooltip
  and tooltip_position
  and show_external_link_icon
  and on_click
  and children
  and test_selector
  and size
  and slim in
  let loading, on_click =
    match (loading : Loading.t) with
    | Yes -> true, on_click
    | No -> false, on_click
    | While_effect_in_progress -> loading_state.is_loading, loading_state.handle on_click
  in
  view
    ~size
    ~slim
    ~variant
    ~intent
    ~disabled
    ~loading
    ~on_click
    ~attrs:[ Attr.many attrs ]
    ~rounded
    ~show_external_link_icon
    ?test_selector
    ?tooltip
    ?tooltip_position
    children
;;

let group_style = Vdom.Attr.create "data-skyline-button-group" ""

module For_docs = struct
  let ml_filepath = __FILE__
end
