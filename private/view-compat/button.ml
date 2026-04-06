open! Core
open! Bonsai_web

module Style = struct
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
          line-height: 28px;

          display: flex;
          align-items: center;
          justify-content: center;

          border-radius: 2px;
          color: var(--foreground);
          background-color: var(--background);
        }

        .button.enabled:hover {
          color: var(--hover-foreground);
          background-color: var(--hover-background);
        }

        .button.disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
      |}]

  let colors ?foreground ?background ?hover_foreground ?hover_background () =
    let foreground = Option.map foreground ~f:Css_gen.Color.to_string_css in
    let background = Option.map background ~f:Css_gen.Color.to_string_css in
    let hover_foreground = Option.map hover_foreground ~f:Css_gen.Color.to_string_css in
    let hover_background = Option.map hover_background ~f:Css_gen.Color.to_string_css in
    Variables.set ?foreground ?background ?hover_foreground ?hover_background ()
  ;;
end

let make ~attrs ~disabled ~intent ~tooltip ~on_click content =
  let variables =
    match intent with
    | Some intent ->
      let intent_color =
        match (intent : View.Constants.Intent.t) with
        | Info -> Skyline_theme_v1.accent
        | Success -> Skyline_theme_v1.success
        | Warning -> Skyline_theme_v1.warning
        | Error -> Skyline_theme_v1.error
      in
      Style.colors
        ~foreground:intent_color
        ~background:(Skyline_theme_v1.ramp intent_color (Percent.of_percentage 20.))
        ~hover_foreground:intent_color
        ~hover_background:intent_color
        ()
    | None ->
      Style.colors
        ~foreground:Skyline_theme_v1.primary
        ~background:
          (Skyline_theme_v1.ramp Skyline_theme_v1.primary (Percent.of_percentage 20.))
        ~hover_foreground:Skyline_theme_v1.background
        ~hover_background:Skyline_theme_v1.primary
        ()
  in
  let on_click =
    match disabled with
    | false -> Vdom.Attr.on_click (const on_click)
    | true -> Vdom.Attr.empty
  in
  let title' = Option.value_map tooltip ~f:Vdom.Attr.title ~default:Vdom.Attr.empty in
  Vdom.Node.button
    ~attrs:
      (Style.button
       :: variables
       :: on_click
       :: title'
       :: (if disabled then Style.disabled else Style.enabled)
       :: attrs)
    content
;;
