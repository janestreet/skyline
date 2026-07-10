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
  module Loading_state = struct
    type t =
      { is_loading : bool
      ; handle : 'a. 'a Effect.t -> 'a Effect.t
      }

    let component (local_ graph) =
      let in_flight_count, update_in_flight_count = Bonsai.state' 0 graph in
      let%arr in_flight_count and update_in_flight_count in
      let handle effect =
        let%bind.Effect () = update_in_flight_count (fun count -> count + 1) in
        Effect.protect
          effect
          ~finally:(update_in_flight_count (fun count -> Int.max 0 (count - 1)))
      in
      { is_loading = in_flight_count > 0; handle }
    ;;
  end

  type t =
    | Yes
    | No
    | While_effect_in_progress of Loading_state.t

  let is_loading = function
    | Yes -> true
    | No -> false
    | While_effect_in_progress { is_loading; _ } -> is_loading
  ;;

  let wrap_on_click ~on_click = function
    | Yes | No -> on_click
    | While_effect_in_progress { handle; _ } -> handle on_click
  ;;

  let while_effect_in_progress (graph @ local) =
    let%arr while_effect_in_progress = Loading_state.component graph in
    While_effect_in_progress while_effect_in_progress
  ;;
end

module Type_attr = struct
  type t =
    | Button
    | Submit

  let to_attr = function
    | Button -> Attr.type_ "button"
    | Submit -> Attr.type_ "submit"
  ;;
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
      | Ghost, `Secondary -> Classes.text_default
      | Ghost, `Danger -> Classes.text_danger
      | Ghost, `Success -> Classes.text_success
      | Ghost, `Warning -> Classes.text_warning
      | Outlined, `Primary -> Classes.text_primary
      | Outlined, `Secondary -> Classes.text_default
      | Outlined, `Danger -> Classes.text_danger
      | Outlined, `Success -> Classes.text_success
      | Outlined, `Warning -> Classes.text_warning
      | Link, `Primary -> Classes.text_primary
      | Link, `Secondary -> Classes.text_default
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
      | Outlined, `Secondary -> Classes.border_default_alt
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
              padding: 3px;
            }
          }
          .sm {
            --size: 12px;

            &.has_one_child:has(> .icon) {
              padding: 5px;
            }
          }
          .md {
            --size: 12px;

            &.has_one_child:has(> .icon) {
              padding: 7px;
            }
          }
          .lg {
            --size: 16px;

            &.has_one_child:has(> .icon) {
              padding: 7px;
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
      <><span %{Style.Loading.container}><%{spinner} />#{" Loading "}</span
        ><span %{Style.Loading.hidden_children}>*{children}</span></>
    |}
;;

let with_external_link_indicator contents =
  match Am_running_how_js.am_running_how with
  | `Node_test | `Node_jsdom_test -> contents
  | `Browser | `Browser_test | `Browser_benchmark | `Node | `Node_benchmark ->
    contents @ [ {%html|<Icon.view ~icon:%{Lucide.external_link} />|} ]
;;

let num_children children =
  (* Make sure we count text nodes inside a fragment. *)
  let rec node_length (node : Vdom.Node.t) =
    match node with
    | Fragment nodes -> List.sum (module Int) nodes ~f:node_length
    | None -> 0
    | Text _ | Element _ | Widget _ | Lazy _ -> 1
  in
  List.sum (module Int) children ~f:node_length
;;

let contains_type_attribute attr =
  (* Only a real HTML [type] attribute should suppress the default. Hooks and properties
     named [type] don't set the same field in the raw Vdom attrs. *)
  attr
  |> Attr.Expert.filter_by_kind ~f:(function
    | `Attribute -> true
    | `Class | `Handler | `Hook | `Property | `Style -> false)
  |> Attr.Expert.contains_name "type"
;;

let view
  ?test_selector
  ?(attrs = [])
  ?(size = `Md)
  ?(slim = false)
  ?(variant = Variant.Filled)
  ?(rounded = false)
  ?(disabled = false)
  ?(loading = Loading.No)
  ?(intent : Skyline_intent.t = `Secondary)
  ?tooltip
  ?tooltip_position
  ?(show_external_link_icon = true)
  ?type_attr
  children
  ~on_click
  =
  let on_click = Loading.wrap_on_click ~on_click loading in
  let loading = Loading.is_loading loading in
  let children = if loading then [ loading_overlay children ] else children in
  let disabled = disabled || loading in
  let attrs =
    let type_attr =
      match type_attr, List.exists attrs ~f:contains_type_attribute with
      | Some type_attr, _ -> Some type_attr
      | None, false -> Some Type_attr.Button
      | None, true -> None
    in
    (* If [type_attr] is explicit and [attrs] also contains [Vdom.Attr.type_], the
       caller's [attrs] win via Vdom merge order and Vdom emits a duplicate-attribute
       warning. For the implicit default, avoid adding a duplicate [type] attribute. *)
    match type_attr with
    | None -> attrs
    | Some type_attr -> Type_attr.to_attr type_attr :: attrs
  in
  let tooltip =
    match tooltip with
    | Some "" | None -> Attr.empty
    | Some text ->
      Skyline_tooltip_v2.attr
        ?position:tooltip_position
        ~alignment:Center
        (Node.text text)
  in
  let button_attrs ~children =
    [ Test_selector.attr_of_opt test_selector
    ; Style.button_base
    ; Style.size_styles size ~rounded ~slim
    ; Style.variant_styles variant ~intent ~disabled
    ; Style.Icon.attrs ~size ~num_children:(num_children children) ~slim
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
      | true, New_tab_or_window -> with_external_link_indicator children
    in
    {%html|<a *{[href_and_target url target; Attr.many (button_attrs ~children)]}>*{children}</a>|}
  | _ ->
    let on_click = if disabled then Effect.Ignore else on_click in
    {%html|<button *{ [Attr.on_click (fun _ -> on_click); Attr.many (button_attrs ~children)]}>*{children}</button>|}
;;

module Copy = struct
  module State = struct
    type t = Bonsai_web_clipboard.With_status.t

    let component ~text (local_ graph) =
      Bonsai_web_clipboard.With_status.copy_text text graph
    ;;
  end

  (* Overlay children with a checkmark when content has been copied. *)
  let on_copy_overlay children =
    match Am_running_how_js.am_running_how with
    | `Node_test | `Node_jsdom_test -> {%html|<Icon.view ~icon:%{Lucide.check} />|}
    | `Browser | `Browser_test | `Browser_benchmark | `Node | `Node_benchmark ->
      {%html|
        <>
          <span %{Style.Loading.container}>
            <Icon.view ~icon:%{Lucide.check} />
          </span>
          <span %{Style.Loading.hidden_children}>*{children}</span>
        </>
      |}
  ;;

  let view
    ?test_selector
    ?(attrs = [])
    ?size
    ?slim
    ?variant
    ?rounded
    ?disabled
    ?(loading = false)
    ?intent
    ?(on_copied_tooltip = "Copied!")
    ?on_copied_tooltip_position
    ?type_attr
    children
    ~state
    =
    let ~on_click, ~tooltip, ~children =
      match state with
      | `Copied ->
        let tooltip =
          (* We use `Always_show because the user is already hovering over the button. *)
          Node.text on_copied_tooltip
          |> Skyline_tooltip_v2.attr
               ?position:on_copied_tooltip_position
               ~behavior:`Always_show
        in
        ~on_click:Effect.Ignore, ~tooltip, ~children:[ on_copy_overlay children ]
      | `Idle on_click -> ~on_click, ~tooltip:Attr.empty, ~children
    in
    let loading = if loading then Loading.Yes else Loading.No in
    view
      ?test_selector
      ?size
      ?slim
      ?variant
      ?rounded
      ?disabled
      ~loading
      ?intent
      ~attrs:(tooltip :: attrs)
      ?type_attr
      children
      ~on_click
  ;;
end

let group_style = Vdom.Attr.create "data-skyline-button-group" ""

module For_testing = struct
  let has_one_child_classname = Style.Icon.Stylesheet.For_referencing.has_one_child
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
