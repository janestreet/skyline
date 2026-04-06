open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Position = struct
  type t =
    | Top
    | Center
  [@@deriving sexp_of, compare, equal]
end

module Restore_focus_on_close = Bonsai_web_ui_toplayer.Restore_focus_on_close

module Style = struct
  let dialog (position : Position.t) =
    let margin =
      match position with
      | Center -> "auto"
      | Top -> "24px auto"
    in
    [ {%css|
        display: flex;
        flex-direction: column;
        max-width: calc(100vw - 48px); /* 48px = 2 x top/bottom margins from above */
        max-height: calc(100vh - 48px);
        overflow: auto;
        padding: 8px;
        margin: %{margin};
        border-radius: 4px;
        border: 1px solid var(--skyline-color-border);
        color: var(--skyline-color-primary);
        background-color: var(--skyline-color-surface);
        /* We need to use ppx_css here since we can't set backdrop via an inline style.

                   In general, we want to avoid using ppx css in Skyline since it's expensive at
                   runtime and Skyline components are so widely used. */
        &::backdrop {
          backdrop-filter: brightness(90%) grayscale(90%);
        }
      |}
    ; Private_skyline_theme.Stylesheet.step_nested_surface_ramp
    ; Vdom.Attr.style Private_skyline_theme.Shadows.raised_card
    ]
  ;;

  let message_text = {%css|max-width: 360px;|}
end

let close_on_click_outside_toplayer close_on_click_outside =
  let%arr close_on_click_outside in
  if close_on_click_outside
  then
    (* Any popovers below the modal are inert and unclickable, so if a popover can be
       clicked, it is on top of the modal, and probably shouldn't cause the modal to
       close. *)
    Bonsai_web_ui_toplayer.Close_on_click_outside.Yes_unless_target_is_popover
  else No
;;

let component
  ?test_selector
  ?(close_on_click_outside = return false)
  ?(close_on_esc = return true)
  ?(position = return Position.Center)
  ?padding
  ?restore_focus_on_close
  content
  ~close
  (local_ graph)
  =
  let close_on_click_outside = close_on_click_outside_toplayer close_on_click_outside in
  let autoclose =
    Bonsai_web_ui_toplayer.Autoclose.create
      ~close_on_click_outside
      ~close_on_esc
      ~close
      graph
  in
  let extra_attrs =
    let padding_attr =
      match padding with
      | Some padding ->
        let%arr padding in
        {%css|padding: %{padding#Css_gen.Length};|}
      | None -> return Vdom.Attr.empty
    in
    let%arr padding_attr in
    padding_attr :: [ Bonsai_web.Test_selector.attr_of_opt test_selector ]
  in
  Bonsai_web_ui_toplayer.Modal.always_open
    ~extra_attrs
    ~config:
      (`This_one
        (let%arr position in
         { Bonsai_web_ui_toplayer.Modal.Config.modal_attrs = Style.dialog position }))
    ~autoclose
    ~overflow_auto_wrapper:(return false)
    ?restore_focus_on_close
    ~content
    graph
;;

let effect
  ?state
  ?position
  ?padding
  ?close_on_click_outside
  ?close_on_esc
  ?restore_focus_on_close
  content
  graph
  =
  let visible, set_visible =
    match state with
    | None -> Bonsai.state false graph
    | Some external_state -> external_state
  in
  let close =
    let%arr set_visible in
    set_visible false
  in
  let%sub () =
    match%sub visible with
    | true ->
      component
        ?close_on_click_outside
        ?position
        ?close_on_esc
        ?padding
        ?restore_focus_on_close
        (content ~close)
        ~close
        graph;
      return ()
    | false -> return ()
  in
  let%arr set_visible in
  set_visible true
;;

let dialog ~title ~message actions =
  Skyline_flex_v1.column
    ~gap:(`Px 16)
    ~align:Stretch
    [ Skyline_flex_v1.column
        ~gap:(`Px 2)
        ~justify:Flex_start
        [ Skyline_text_v1.span ~style:Bold title
        ; Skyline_text_v1.span ~attrs:[ Style.message_text ] message
        ; Skyline_flex_v1.row
            ~justify:Flex_end
            [ Skyline_flex_v1.row
                ~gap:(`Px 8)
                ~attrs:[ Vdom.Attr.style (Css_gen.width (`Raw "fit-content")) ]
                actions
            ]
        ]
    ]
;;

let modal ~position ~is_open ~close ~content graph =
  let%sub () =
    match%sub is_open with
    | Some input ->
      Bonsai_web_ui_toplayer.Modal.always_open
        ~config:
          (`This_one
            (let%arr position in
             { Bonsai_web_ui_toplayer.Modal.Config.modal_attrs = Style.dialog position }))
        ~autoclose:
          (Bonsai_web_ui_toplayer.Autoclose.create
             ~close_on_click_outside:
               (return Bonsai_web_ui_toplayer.Close_on_click_outside.No)
             ~close_on_right_click_outside:
               (return Bonsai_web_ui_toplayer.Close_on_click_outside.No)
             ~close_on_esc:(return true)
             ~close
             graph)
        ~overflow_auto_wrapper:(return false)
        ~content:(content input)
        graph;
      return ()
    | None -> return ()
  in
  ()
;;

let alert graph =
  let state, action =
    Bonsai.state_machine
      ~default_model:[]
      ~apply_action:(fun _ model action ->
        match action with
        | `Open input -> input :: model
        | `Close -> List.drop model 1)
      graph
  in
  let close =
    let%arr action in
    action `Close
  in
  let open_state =
    let%arr state in
    List.hd state
  in
  modal
    ~position:(return Position.Center)
    ~is_open:open_state
    ~close
    ~content:(fun input _graph ->
      let%arr ~intent, ~button_label, ~title, ~message = input
      and close in
      dialog
        ~title
        ~message
        [ Skyline_button_v1.regular' ~autofocus:true ?intent ~on_click:close button_label
        ])
    graph;
  let%arr action in
  fun ?intent ?(button_label = "Ok") ~title message ->
    action (`Open (~intent, ~button_label, ~title, ~message))
;;

type confirm_model =
  { outcome : bool Async_kernel.Ivar.t
  ; intent : Skyline_theme_v1.Color.t
  ; cancel_label : string
  ; confirm_label : string
  ; title : string
  ; message : string
  }

let confirm (local_ graph) =
  let state, action =
    let drop_and_fill (model : confirm_model list) ~with_ =
      match model with
      | [] -> []
      | { outcome; _ } :: tl ->
        Async_kernel.Ivar.fill_exn outcome with_;
        tl
    in
    Bonsai.state_machine
      ~default_model:[]
      ~apply_action:(fun _ model action ->
        match action with
        | `Open input -> input :: model
        | `Cancel -> drop_and_fill ~with_:false model
        | `Confirm -> drop_and_fill ~with_:true model)
      graph
  in
  let%sub cancel, confirm =
    let%arr action in
    action `Cancel, action `Confirm
  in
  let open_state =
    let%arr state in
    List.hd state
  in
  modal
    ~position:(return Position.Center)
    ~is_open:open_state
    ~close:cancel
    ~content:(fun input (local_ graph) ->
      let%sub { intent; title; message; confirm_label; cancel_label; _ } = input in
      let%arr confirm =
        Skyline_button_v1.regular
          ~autofocus:(return true)
          ~loading:(Bonsai.return `While_on_click_in_flight)
          ~intent
          ~on_click:confirm
          confirm_label
          graph
      and cancel
      and title
      and message
      and cancel_label in
      dialog
        ~title
        ~message
        [ Skyline_button_v1.regular' ~on_click:cancel cancel_label; confirm ])
    graph;
  let%arr action in
  fun ?(intent = Skyline_theme_v1.accent)
    ?(cancel_label = "Cancel")
    ?(confirm_label = "Confirm")
    ~title
    message ->
    let%bind.Effect outcome = Effect.of_thunk Async_kernel.Ivar.create in
    let%bind.Effect () =
      action (`Open { outcome; intent; cancel_label; confirm_label; title; message })
    in
    Effect.of_deferred_fun Async_kernel.Ivar.read outcome
;;
