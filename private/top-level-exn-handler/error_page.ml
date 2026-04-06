open! Core
open! Bonsai_web

let maybe_stack_trace (exn : Exn.t) =
  let maybe_js_stack_trace =
    Js_of_ocaml.Js_error.of_exn exn
    |> Option.bind ~f:(fun err ->
      Js_of_ocaml.Js_error.stack err
      |> Option.map ~f:String.strip
      |> Option.filter ~f:(fun trace -> not (String.is_empty trace)))
  in
  match maybe_js_stack_trace with
  | Some stack_trace ->
    Vdom.Node.div
      ~attrs:
        [ Css_gen.(
            flex_container ~direction:`Column ~column_gap:(`Px 2) ()
            @> white_space `Pre_wrap
            @> font_size (`Rem 0.8)
            @> font_weight (`Number 500)
            @> font_family [ "var(--skyline-font-mono)"; "'Fira Mono'"; "monospace" ]
            @> color Skyline_theme_v1.primary)
          |> Vdom.Attr.style
        ]
      [ Vdom.Node.text stack_trace ]
    |> Option.some
  | None -> None
;;

let view (exn : Exn.t) =
  let error_codicon =
    Vdom.Node.inner_html_svg
      ~tag:"svg"
      ~attrs:
        Vdom.Attr.
          [ create "width" "16px"
          ; create "height" "16px"
          ; create "viewBox" "0 0 16 16"
          ; create "fill" "currentColor"
          ]
      ~this_html_is_sanitized_and_is_totally_safe_trust_me:
        "<path fill-rule=\"evenodd\" clip-rule=\"evenodd\" d=\"M8.6 1c1.6.1 3.1.9 4.2 2 \
         1.3 1.4 2 3.1 2 5.1 0 1.6-.6 3.1-1.6 4.4-1 1.2-2.4 2.1-4 \
         2.4-1.6.3-3.2.1-4.6-.7-1.4-.8-2.5-2-3.1-3.5C.9 9.2.8 7.5 1.3 6c.5-1.6 1.4-2.9 \
         2.8-3.8C5.4 1.3 7 .9 8.6 1zm.5 12.9c1.3-.3 2.5-1 3.4-2.1.8-1.1 1.3-2.4 1.2-3.8 \
         0-1.6-.6-3.2-1.7-4.3-1-1-2.2-1.6-3.6-1.7-1.3-.1-2.7.2-3.8 1-1.1.8-1.9 1.9-2.3 \
         3.3-.4 1.3-.4 2.7.2 4 .6 1.3 1.5 2.3 2.7 3 1.2.7 2.6.9 3.9.6zM7.9 7.5L10.3 \
         5l.7.7-2.4 2.5 2.4 2.5-.7.7-2.4-2.5-2.4 2.5-.7-.7 2.4-2.5-2.4-2.5.7-.7 2.4 \
         2.5z\"/>"
      ()
  in
  let exn_error_message =
    match exn with
    | Failure message -> message
    | exn -> Exn.to_string exn
  in
  let maybe_stack_trace = maybe_stack_trace exn in
  let maybe_chrome_dev_tools_warning =
    match maybe_stack_trace with
    | Some _ ->
      Vdom.Node.span
        [ Vdom.Node.text
            "Use the Chrome Dev Tools Console to get a stack trace that can use your \
             source map."
        ]
    | None -> None
  in
  Vdom.Node.div
    ~attrs:
      [ Css_gen.(
          flex_container ~direction:`Column ~row_gap:(`Px 12) ()
          @> uniform_padding (`Px 24)
          @> width (`Vw Percent.one_hundred_percent)
          @> font_size (`Rem 0.9)
          @> font_weight (`Number 500)
          @> font_family [ "var(--skyline-font-sans)"; "Inter"; "sans-serif" ])
        |> Vdom.Attr.style
      ]
    [ Vdom.Node.div
        ~attrs:
          [ Css_gen.(
              flex_container ~direction:`Row ~align_items:`Center ~column_gap:(`Px 4) ()
              @> color Skyline_theme_v1.error)
            |> Vdom.Attr.style
          ]
        [ error_codicon
        ; Vdom.Node.span
            ~attrs:[ Vdom.Attr.style Css_gen.(font_weight (`Number 800)) ]
            [ Vdom.Node.text "Uncaught Exception" ]
        ]
    ; Vdom.Node.span [ Vdom.Node.text exn_error_message ]
    ; Option.value maybe_stack_trace ~default:Vdom.Node.none
    ; Vdom.Node.div
        ~attrs:
          [ Css_gen.(flex_container ~direction:`Column ~row_gap:(`Px 4) () @> opacity 0.6)
            |> Vdom.Attr.style
          ]
        [ Vdom.Node.span
            [ Vdom.Node.text
                "App crashed with fatal error. Please report this to the app owners."
            ]
        ; maybe_chrome_dev_tools_warning
        ; Vdom.Node.span
            [ Vdom.Node.text (String.concat ~sep:" " Version_util_compat.version_list) ]
        ]
    ]
;;
