open! Core
open! Private_skyline_prelude

module Content = struct
  type t = Skyline_size.t -> Vdom.Node.t
end

module Style = struct
  include
    [%css
    stylesheet
      {|
        .intent_primary {
          --accent-fg: %{Colors.Text.primary#Css_gen.Color};
          --accent-bg: %{Colors.Background.primary_alt#Css_gen.Color};
        }

        .intent_secondary {
          --accent-fg: %{Colors.Text.default#Css_gen.Color};
          --accent-bg: %{Colors.Background.secondary_alt#Css_gen.Color};
        }

        .intent_success {
          --accent-fg: %{Colors.Text.success#Css_gen.Color};
          --accent-bg: %{Colors.Background.success_alt#Css_gen.Color};
        }
        .intent_danger {
          --accent-fg: %{Colors.Text.danger#Css_gen.Color};
          --accent-bg: %{Colors.Background.danger_alt#Css_gen.Color};
        }

        .intent_warning {
          --accent-fg: %{Colors.Text.warning#Css_gen.Color};
          --accent-bg: %{Colors.Background.warning_alt#Css_gen.Color};
        }

        .header-container {
          background-color: var(--accent-bg);
        }
        .header-contents {
          display: flex;
        }
        .header-container:has(+ .body) {
          border-bottom: 1px solid %{Colors.Background.one#Css_gen.Color};
        }

        .header-icon {
          display: inline;
          flex-shrink: 0;
          color: var(--accent-fg);
        }

        .padding_xs {
          padding-block: 3px;
          padding-inline: %{Classes.spacing 1.#Css_gen.Length};
        }
        .padding_sm {
          padding-block: %{Classes.spacing 1.#Css_gen.Length};
          padding-inline: %{Classes.spacing 2.#Css_gen.Length};
        }
        .padding_md {
          padding-block: %{Classes.spacing 2.#Css_gen.Length};
          padding-inline: %{Classes.spacing 2.#Css_gen.Length};
        }
        .padding_lg {
          padding-block: %{Classes.spacing 3.#Css_gen.Length};
          padding-inline: %{Classes.spacing 4.#Css_gen.Length};
        }

        .header_gap_xs {
          gap: %{Classes.spacing 1.#Css_gen.Length};
        }
        .header_gap_rest {
          gap: %{Classes.spacing 2.#Css_gen.Length};
        }

        .loading-bar {
          height: 2px;
          position: absolute;
          left: 0;
          bottom: 0;
          background-color: currentColor;
          width: 2%;

          @media not (prefers-reduced-motion: reduce) {
            animation: 4s infinite linear loading;
          }
        }

        @keyframes loading {
          0% {
            transform: translateX(0%) scaleX(1);
          }
          50% {
            transform: translateX(2500%) scaleX(3);
          }
          100% {
            transform: translateX(4900%) scaleX(1);
          }
        }
      |}]

  let container_attrs intent =
    let intent_attr =
      match intent with
      | `Primary -> intent_primary
      | `Secondary -> intent_secondary
      | `Success -> intent_success
      | `Danger -> intent_danger
      | `Warning -> intent_warning
    in
    intent_attr
  ;;

  let padding (size : Skyline_size.t) =
    match size with
    | `Xs -> padding_xs
    | `Sm -> padding_sm
    | `Md -> padding_md
    | `Lg -> padding_lg
  ;;

  let header_gap (size : Skyline_size.t) =
    match size with
    | `Xs -> header_gap_xs
    | `Sm | `Md | `Lg -> header_gap_rest
  ;;
end

let loading_bar ~intent =
  let color =
    match intent with
    | `Primary -> Classes.text_on_filled_alt_primary
    | `Secondary -> Classes.text_on_filled_alt_secondary
    | `Success -> Classes.text_on_filled_alt_success
    | `Danger -> Classes.text_on_filled_alt_danger
    | `Warning -> Classes.text_on_filled_alt_warning
  in
  [%html {|<div %{Style.loading_bar} style="pointer-events: none" %{color}></div>|}]
;;

let view ?test_selector ?(attrs = []) ?(size = `Md) ?(intent = `Primary) ?loading children
  =
  let loading_node =
    let%bind.Option loading in
    match loading with
    | `Indeterminate -> Some (loading_bar ~intent)
  in
  let children = List.map children ~f:(fun child -> child size) in
  [%html
    {|
      <div
        style="position: relative; overflow: hidden"
        *{Classes.[flex; flex_col; bg_one; border 1; border_default; rounded_md]}
        %{Style.container_attrs intent}
        %{Bonsai.Test_selector.attr_of_opt test_selector}
        *{attrs}
        %{Classes.data_skyline_component "banner"}
      >
        *{children} ?{loading_node}
      </div>
    |}]
;;

let text_size : Skyline_size.t -> Skyline_text_v2.Size.t = function
  | `Xs -> `Two_xs
  | `Sm | `Md | `Lg -> `Sm
;;

module Header = struct
  module T = struct
    let view' ?test_selector ?(attrs = []) children =
      [%html
        {|
          <div
            %{Bonsai.Test_selector.attr_of_opt test_selector}
            *{Style.[header_container; header_contents]}
            *{Classes.[flex; flex_row; items_center]}
            *{attrs}
          >
            *{children}
          </div>
        |}]
    ;;
  end

  let view ?test_selector ?(attrs = []) children : Content.t =
    fun size ->
    [%html
      {|
        <T.view'
          ?test_selector
          %{Style.padding size}
          %{Style.header_gap size}
          *{attrs}
        >
          *{children}
        </>
      |}]
  ;;

  let text ?test_selector ?(attrs = []) contents : Content.t =
    fun size ->
    [%html
      {|
        <T.view'
          ?test_selector
          %{Style.padding size}
          %{Style.header_gap size}
          *{attrs}
        >
          <Skyline_text_v2.view
            style="flex: 1"
            *{Classes.[flex; flex_row; items_center]}
            *{Style.[header_contents]}
            %{Style.header_gap size}
            ~size:%{text_size size}
          >
            *{contents}
          </>
        </>
      |}]
  ;;

  let icon ?test_selector ?(attrs = []) ~icon () =
    [%html
      {|
        <Bonsai_web_icon.view
          ~size:%{`Raw "calc(1em + 2px)"}
          ~icon
          %{Test_selector.attr_of_opt test_selector}
          %{Style.header_icon}
          *{attrs}
        />
      |}]
  ;;

  let spacer () = [%html {|<div style="flex: 1"></div>|}]
end

module Section = struct
  module T = struct
    let view' ?test_selector ?(attrs = []) children =
      [%html
        {|
          <section
            *{Style.[body]}
            style="flex: 1; overflow: auto"
            %{Bonsai.Test_selector.attr_of_opt test_selector}
            *{attrs}
          >
            *{children}
          </section>
        |}]
    ;;
  end

  let content ?test_selector ?(attrs = []) children : Content.t =
    fun size ->
    [%html
      {|
        <T.view' ?test_selector %{Style.padding size} *{attrs}>
          *{children}
        </>
      |}]
  ;;

  let text ?test_selector ?(attrs = []) contents : Content.t =
    fun size ->
    [%html
      {|
        <T.view' ?test_selector %{Style.padding size} *{attrs}>
          <Skyline_text_v2.view style="display: contents" ~size:%{text_size size}>
            *{contents}
          </>
        </>
      |}]
  ;;
end

module For_docs = struct
  let ml_filepath = __FILE__
end
