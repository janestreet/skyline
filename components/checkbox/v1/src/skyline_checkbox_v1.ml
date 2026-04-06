open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
include Skyline_input_v1

module Style = struct
  let ( @> ) = Css_gen.( @> )

  let container =
    Css_gen.border_radius (`Px 4)
    @> Css_gen.flex_container ~direction:`Row ()
    @> Css_gen.user_select `None
    @> Css_gen.create ~field:"cursor" ~value:"pointer"
    |> Vdom.Attr.style
  ;;

  let checkbox_label_layout =
    Css_gen.min_height (`Px 16)
    @> Css_gen.flex_container ~direction:`Row ~align_items:`Center ~column_gap:(`Px 8) ()
    |> Vdom.Attr.style
  ;;

  let checkbox ~disabled =
    Css_gen.width (`Px 16)
    @> Css_gen.height (`Px 16)
    @> Css_gen.border ~width:(`Px 1) ~style:`Solid ~color:Skyline_theme_v1.border ()
    @> Css_gen.border_radius (`Px 4)
    @> Css_gen.flex_container ~align_items:`Center ~justify_content:`Center ()
    @> Css_gen.opacity (if disabled then 0.5 else 1.)
    |> Vdom.Attr.style
  ;;

  let checked intent = Css_gen.background_color intent |> Vdom.Attr.style
  let unchecked = Css_gen.background_color Skyline_theme_v1.surface |> Vdom.Attr.style
  let disabled = Css_gen.create ~field:"cursor" ~value:"not-allowed" |> Vdom.Attr.style
end

let on_enter effect =
  Vdom.Attr.on_keydown (fun event ->
    match Js_of_ocaml.Dom_html.Keyboard_code.of_event event with
    | Enter -> effect
    | _ -> Effect.Ignore)
;;

let component
  ?test_selector
  ?state
  ?(disabled = return false)
  ?(intent = return Skyline_theme_v1.accent)
  ?(label = return "")
  graph
  =
  let state, set_state =
    match state with
    | Some state -> state
    | None -> Bonsai.state false graph
  in
  let view =
    let%arr state and set_state and disabled and intent and label in
    let toggle = if not disabled then set_state (not state) else Effect.Ignore in
    let checkbox_view =
      [ Vdom.Node.div
          ~attrs:[ Style.checkbox_label_layout ]
          [ Vdom.Node.div
              ~attrs:
                [ Style.checkbox ~disabled
                ; (if state then Style.checked intent else Style.unchecked)
                ]
              [ Codicons.svg
                  ~size:(`Px 14)
                  ~color:Skyline_theme_v1.background
                  (if state then Check else Blank)
              ]
          ; (if String.is_empty label
             then Vdom.Node.none
             else Skyline_text_v1.span ~secondary:disabled label)
          ]
      ]
    in
    let attrs =
      [ on_enter toggle
      ; Style.container
      ; (if disabled then Style.disabled else Vdom.Attr.empty)
      ]
    in
    let append_label_in_test node =
      if Am_running_how_js.am_in_browser_like_api || String.is_empty label
      then node
      else Vdom.Node.fragment [ node; Skyline_text_v1.span ~secondary:disabled label ]
    in
    Bonsai_web_checkbox.component
      ?test_selector
      ~attrs
      ~disabled
      ~checked:state
      ~on_change:set_state
      ~disable_space_key_to_toggle_temp_param_for_skyline:true
      checkbox_view
    |> append_label_in_test
  in
  Skyline_input_v1.create view state set_state
;;
