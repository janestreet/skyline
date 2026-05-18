open! Core
open! Private_skyline_prelude

module Size = struct
  type t =
    [ `Inherit
    | `Two_xs
    | `Xs
    | `Sm
    | `Md
    | `Lg
    | `Xl
    | `Two_xl
    | `Three_xl
    | `Four_xl
    | `Five_xl
    ]
  [@@deriving enumerate, to_string, sexp, equal]

  let to_attr = function
    | `Inherit ->
      (* Inherit font-size and line-height ambiently *)
      Vdom.Attr.empty
    | `Two_xs -> Classes.text_2xs
    | `Xs -> Classes.text_xs
    | `Sm -> Classes.text_sm
    | `Md -> Classes.text_base
    | `Lg -> Classes.text_lg
    | `Xl -> Classes.text_xl
    | `Two_xl -> Classes.text_2xl
    | `Three_xl -> Classes.text_3xl
    | `Four_xl -> Classes.text_4xl
    | `Five_xl -> Classes.text_5xl
  ;;

  let to_attr' size ~default =
    match size with
    | None -> default
    | Some size -> to_attr size
  ;;
end

module Weight = struct
  type t =
    [ `Inherit
    | `Light
    | `Normal
    | `Medium
    | `Semibold
    | `Bold
    ]
  [@@deriving enumerate, to_string, sexp, equal]

  let to_attr = function
    | `Inherit -> Vdom.Attr.empty
    | `Light -> Classes.font_light
    | `Normal -> Classes.font_normal
    | `Medium -> Classes.font_medium
    | `Semibold -> Classes.font_semibold
    | `Bold -> Classes.font_bold
  ;;
end

module Color = struct
  type t =
    [ `Inherit
    | `Default
    | Skyline_intent.t
    | Css_gen.Color.t
    ]

  let fg (t : t) =
    match t with
    | `Inherit -> Vdom.Attr.empty
    | `Default -> Classes.text_default
    | #Skyline_intent.t as intent ->
      (match intent with
       | `Primary -> Classes.text_primary
       | `Secondary -> Classes.text_secondary
       | `Danger -> Classes.text_danger
       | `Success -> Classes.text_success
       | `Warning -> Classes.text_warning)
    | #Css_gen.Color.t as color -> {%css|color: %{color#Css_gen.Color};|}
  ;;

  let link_focus_outline (t : t) =
    match t with
    | `Inherit ->
      {%css|
        &:focus-visible,
        &.for-testing--force-focus-visible {
          outline-color: currentColor;
        }
      |}
    | `Default -> Classes.outline_default_focus_visible
    | #Skyline_intent.t as intent ->
      (match intent with
       | `Primary -> Classes.outline_primary_focus_visible
       | `Secondary -> Classes.outline_primary_focus_visible
       | `Danger -> Classes.outline_danger_focus_visible
       | `Success -> Classes.outline_success_focus_visible
       | `Warning -> Classes.outline_warning_focus_visible)
    | #Css_gen.Color.t as color ->
      (* We don't have custom focus outline colors for arbitrary [Css_gen.Color.t] colors *)
      {%css|
        &:focus-visible,
        &.for-testing--force-focus-visible {
          outline-color: %{color#Css_gen.Color};
        }
      |}
  ;;
end

module Style = struct
  let header = Attr.many Classes.[ font_bold; pb 2. ]

  let link_base =
    {%css|
      outline-width: 2px;
      outline-offset: 2px;

      @media not (prefers-reduced-motion: reduce) {
        transition: color 0.2s ease, text-decoration-color 0.2s ease;
      }
      cursor: pointer;
      &.for-testing--force-hover,
      &:hover,
      &.for-testing--force-active,
      &:active {
        text-decoration-line: underline;
        text-decoration-color: currentColor;
      }
      &.for-testing--force-focus-visible,
      &:focus-visible {
        outline-style: solid;
      }
    |}
  ;;

  let code =
    Attr.many
      [ {%css|
          line-height: 1.25em;
          padding: .125em;
          border-radius: .25em;
          background-color: %{Colors.Background.code#Css_gen.Color};
          border: 1px solid %{Colors.Border.default#Css_gen.Color};
          white-space: pre-wrap;
          overflow-wrap: anywhere;
          margin: 0;
        |}
      ]
  ;;
end

module Layout = struct
  type t =
    [ `Inline
    | `Contents
    ]

  let to_attr = function
    | `Inline -> Attr.empty
    | `Contents -> {%css|display: contents;|}
  ;;
end

let view
  ?test_selector
  ?(attrs = [])
  ?(size = `Inherit)
  ?(weight = `Inherit)
  ?(color = `Inherit)
  ?(layout = `Inline)
  children
  =
  [%html.jsx
    {|
      <span
        *{attrs}
        %{Size.to_attr size}
        %{Weight.to_attr weight}
        %{Color.fg color}
        %{Layout.to_attr layout}
        %{Test_selector.attr_of_opt test_selector}
        %{Classes.data_skyline_component "text"}
        >*{children}</span
      >
    |}]
;;

let monospace
  ?test_selector
  ?(attrs = [])
  ?(size = `Inherit)
  ?(weight = `Inherit)
  ?(color = `Inherit)
  ?(layout = `Inline)
  children
  =
  [%html.jsx
    {|
      <span
        *{attrs}
        %{Size.to_attr size}
        %{Weight.to_attr weight}
        %{Color.fg color}
        %{Layout.to_attr layout}
        %{Test_selector.attr_of_opt test_selector}
        %{Classes.font_monospace}
        %{Classes.data_skyline_component "text"}
        >*{children}</span
      >
    |}]
;;

let target_to_icon = function
  | Effect.Open_url_target.New_tab_or_window ->
    Some
      {%html.jsx|
        <Bonsai_web_icon.view
          style="display: inline; margin-left: 0.2em"
          ~size:%{`Em_float 0.75}
          ~icon:%{Lucide.external_link}
        />
      |}
  | _ -> None
;;

let href_and_target href target =
  [ Attr.href href; Attr.target (Effect.Open_url_target.to_target target) ]
;;

let link
  ?test_selector
  ?(attrs = [])
  ?(size = `Inherit)
  ?(weight = `Inherit)
  ?(color = `Primary)
  ?(show_external_link_icon = true)
  children
  ~on_click
  =
  let on_click_attrs, maybe_external_icon =
    match on_click with
    | Effect.Open { url; target } ->
      ( href_and_target url target
      , if show_external_link_icon then target_to_icon target else None )
    | _ ->
      (* Without href, ensure focusability for keyboard users. *)
      [ Attr.tabindex 0; Attr.on_click (fun _ -> on_click) ], None
  in
  {%html.jsx|
    <a
      *{attrs}
      *{on_click_attrs}
      %{Size.to_attr size}
      %{Weight.to_attr weight}
      %{Style.link_base}
      %{Color.fg color}
      %{Color.link_focus_outline color}
      %{Test_selector.attr_of_opt test_selector}
    >
      *{children}?{maybe_external_icon}
    </a>
  |}
;;

let h1 ?test_selector ?(attrs = []) ?(color = `Default) children =
  [%html.jsx
    {|
      <h1
        *{attrs}
        %{Size.to_attr `Three_xl}
        %{Style.header}
        %{Color.fg color}
        %{Test_selector.attr_of_opt test_selector}
        %{Classes.data_skyline_component "text"}
      >
        *{children}
      </h1>
    |}]
;;

let h2 ?test_selector ?(attrs = []) ?(color = `Default) children =
  [%html.jsx
    {|
      <h2
        *{attrs}
        %{Size.to_attr `Two_xl}
        %{Style.header}
        %{Color.fg color}
        %{Test_selector.attr_of_opt test_selector}
        %{Classes.data_skyline_component "text"}
      >
        *{children}
      </h2>
    |}]
;;

let h3 ?test_selector ?(attrs = []) ?(color = `Default) children =
  [%html.jsx
    {|
      <h3
        *{attrs}
        %{Size.to_attr `Xl}
        %{Style.header}
        %{Color.fg color}
        %{Test_selector.attr_of_opt test_selector}
        %{Classes.data_skyline_component "text"}
      >
        *{children}
      </h3>
    |}]
;;

let h4 ?test_selector ?(attrs = []) ?(color = `Default) children =
  [%html.jsx
    {|
      <h4
        *{attrs}
        %{Size.to_attr `Lg}
        %{Style.header}
        %{Color.fg color}
        %{Test_selector.attr_of_opt test_selector}
        %{Classes.data_skyline_component "text"}
      >
        *{children}
      </h4>
    |}]
;;

let h5 ?test_selector ?(attrs = []) ?(color = `Default) children =
  [%html.jsx
    {|
      <h5
        *{attrs}
        %{Size.to_attr `Md}
        %{Style.header}
        %{Color.fg color}
        %{Test_selector.attr_of_opt test_selector}
        %{Classes.data_skyline_component "text"}
      >
        *{children}
      </h5>
    |}]
;;

let h6 ?test_selector ?(attrs = []) ?(color = `Default) children =
  [%html.jsx
    {|
      <h6
        *{attrs}
        %{Size.to_attr `Sm}
        %{Style.header}
        %{Color.fg color}
        %{Test_selector.attr_of_opt test_selector}
        %{Classes.data_skyline_component "text"}
      >
        *{children}
      </h6>
    |}]
;;

let inline_code
  ?test_selector
  ?(attrs = [])
  ?size
  ?(weight = `Inherit)
  ?(color = `Inherit)
  children
  =
  let default_size = {%css|font-size: 0.875em;|} in
  [%html.jsx
    {|
      <code
        *{attrs}
        %{Size.to_attr' size ~default:default_size}
        %{Weight.to_attr weight}
        %{Color.fg color}
        %{Test_selector.attr_of_opt test_selector}
        %{Classes.data_skyline_component "text"}
        %{Style.code}
        >*{children}</code
      >
    |}]
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
