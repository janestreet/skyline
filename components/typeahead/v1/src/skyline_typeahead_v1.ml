open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Suggestion_style = struct
  type t =
    | Popover
    | Inline
end

type t = string Skyline_input_v1.t

let component
  ?(attrs = return [])
  ?test_selector
  ?state:external_state
  ?(disabled = return false)
  ?(autofocus = return false)
  ?(on_blur = return Effect.Ignore)
  ?on_select
  ?on_tab
  ?score
  ?(suggestion_style = return Suggestion_style.Popover)
  ?(max_visible_suggestions = return 5)
  ?suggestion
  ?(no_matching_suggestions = return Vdom.Node.none)
  ~to_string
  ~placeholder
  suggestions
  graph
  =
  let state, set_state =
    match external_state with
    | Some (state, set_state) -> state, set_state
    | None -> Bonsai.state "" graph
  in
  let suggestion_list, inject =
    let score =
      match score with
      | Some score -> score state
      | None ->
        let%arr state and to_string in
        let query = Fuzzy_search.Query.create state in
        fun item -> Fuzzy_search.score query ~item:(to_string item)
    in
    let suggestion =
      match suggestion with
      | Some suggestion -> Some (suggestion state)
      | None -> None
    in
    let on_select =
      match on_select with
      | Some on_select ->
        let%arr on_select and set_state in
        fun item ->
          let%bind.Effect new_text_box_contents = on_select item in
          set_state new_text_box_contents
      | None ->
        let%arr set_state and to_string in
        fun item -> set_state (to_string item)
    in
    let on_tab_complete =
      match on_tab with
      | Some on_tab ->
        let%arr on_tab and set_state in
        fun item ->
          let%bind.Effect new_text_box_contents = on_tab item in
          set_state new_text_box_contents
      | None -> return (const Effect.Ignore)
    in
    Private_skyline_typeahead.component
      ~query:state
      ~to_string
      ~limit:max_visible_suggestions
      ~score
      ~on_select
      ~on_tab_complete
      ~suggestion
      ~no_matching_suggestions
      suggestions
      graph
  in
  let input_width, set_input_width = Bonsai.state 0. graph in
  let track_width =
    let%arr set_input_width in
    Bonsai_web_element_size_hooks.Size_tracker.on_change
      (fun { border_box = { width; height = _ }; content_box = _ } ->
         set_input_width width)
  in
  let suggestions =
    match%sub suggestion_style, suggestion_list with
    | _, `Idle -> return `Idle
    | Popover, (`Empty vdom | `Matches vdom) ->
      let%arr anchor =
        Private_skyline_typeahead.suggestion_popover ~input_width vdom graph
      in
      `Popover anchor
    | Inline, (`Empty vdom | `Matches vdom) ->
      let%arr vdom in
      `Inline vdom
  in
  let view =
    let%arr inject
    and state
    and set_state
    and disabled
    and autofocus =
      match%arr autofocus with
      | true -> Private_skyline_autofocus.focus_on_mount
      | false -> Vdom.Attr.empty
    and on_blur
    and placeholder
    and track_width
    and suggestions
    and attrs in
    let disabled =
      if disabled
      then
        Vdom.Attr.many
          [ Vdom.Attr.style (Css_gen.create ~field:"cursor" ~value:"not-allowed")
          ; Vdom.Attr.disabled
          ]
      else Vdom.Attr.empty
    in
    let suggestion_attr =
      match suggestions with
      | `Popover attr -> attr
      | _ -> Vdom.Attr.empty
    in
    let on_key event =
      let code = Js_of_ocaml.Dom_html.Keyboard_code.of_event event in
      let () =
        match code with
        | ArrowUp | ArrowDown -> Js_of_ocaml.Dom.preventDefault event
        | Tab when Option.is_some on_tab ->
          (* Don't prevent tab navigation by default unless on_tab is used. *)
          Js_of_ocaml.Dom.preventDefault event
        | _ -> ()
      in
      match code with
      | Escape ->
        (* Prevent the escape event bubbling when suggestions are displayed so that we
           don't e.g. dismiss an open dialog when a type-ahead is closed with the escape
           key.

           (Note that this behaviour should only apply if the suggestions are displayed as
           a floating element.

           This behaviour plays well with the typical use for inline type-ahead inputs
           that are e.g. often used for command-pallet style popovers / dialogs etc.) *)
        let has_active_popover_suggestions =
          match suggestions with
          | `Popover _ -> true
          | `Idle | `Inline _ -> false
        in
        if has_active_popover_suggestions
        then (
          Js_of_ocaml.Dom.preventDefault event;
          Js_of_ocaml.Dom_html.stopPropagation event);
        inject Deactivate
      | ArrowUp -> inject Move_up
      | ArrowDown -> inject Move_down
      | Enter | NumpadEnter -> inject Select_current
      | Tab when Option.is_some on_tab -> inject Tab_complete_current
      | _ -> Effect.Ignore
    in
    Skyline_flex_v1.column
      ~gap:(`Px 4)
      ~align:Stretch
      [ Vdom.Node.input
          ~attrs:
            ([ Skyline_text_input_v1.Expert.style
             ; disabled
             ; autofocus
             ; suggestion_attr
             ; track_width
             ; Vdom.Attr.placeholder placeholder
             ; Vdom.Attr.value state
             ; Vdom.Attr.on_input (fun _ input ->
                 let%bind.Effect () = set_state input in
                 inject Activate)
             ; Vdom.Attr.on_focus (fun _ -> inject Activate)
             ; Vdom.Attr.on_blur (fun _ ->
                 let%bind.Effect () = inject Deactivate in
                 on_blur)
             ; Vdom.Attr.on_keydown on_key
             ; Test_selector.attr_of_opt test_selector
             ]
             @ attrs)
          ()
      ; (match suggestions with
         | `Inline list -> list
         | _ -> Vdom.Node.none)
      ]
  in
  Skyline_input_v1.create view state set_state
;;

let view input = Skyline_input_v1.view input
let value input = Skyline_input_v1.value input
let update input new_value = Skyline_input_v1.update input new_value
