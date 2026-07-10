open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  include
    [%css
    stylesheet
      ~dont_hash_prefixes:[ "--skyline" ]
      {|
        .input {
          box-sizing: border-box;
          position: relative;
          min-height: 24px;
          width: 100%;
          padding: 3px; /* so that we have a total height of 24px */
          margin: 0;

          font-family: var(--skyline-font-sans, sans-serif);
          font-size: 0.8rem;
          font-weight: inherit;
          line-height: 1em;

          color: var(--skyline-color-primary, inherit);
          background-color: var(--skyline-color-surface);
          border-radius: 2px;
          border-width: 1px;
          border-style: solid;
          border-color: var(--skyline-color-border);

          outline: none !important;
          cursor: text;
        }

        .input:has(input:focus),
        .input:has(input:active) {
          border-color: var(--skyline-color-accent);
        }

        .input input {
          box-sizing: border-box;
          height: 24px;
          width: 100%;
          min-width: 100px;
          flex: 1;
          margin: -4px;
          padding: 0 4px;

          border: none;
          background: none;
          outline: none !important;
        }

        .chip {
          box-sizing: boder-box;
          height: 16px;
          width: max-content;
          display: flex;
          flex-direction: row;
          align-items: center;
          gap: 2px;
          padding: 2px 0 2px 2px;
          margin: 0;

          color: var(--skyline-color-primary, inherit);
          background-color: var(--skyline-color-border);

          border: 1px solid #fff0;
          border-radius: 2px;
          cursor: pointer;
        }

        .chip.selected {
          border: 1px solid var(--skyline-color-accent);
        }

        .chip:hover {
          color: var(--skyline-color-background, inherit);
          background-color: var(--skyline-color-primary);
        }
      |}]
end

type 'a t = 'a list Skyline_input_v1.t

let chip ~selected ~on_click item =
  Vdom.Node.button
    ~attrs:
      [ Style.chip
      ; (if selected then Style.selected else Vdom.Attr.empty)
      ; Vdom.Attr.on_click (const on_click)
      ]
    [ item; Codicons.svg Close ]
;;

let focused_selection ~query ~state ~set_state graph =
  let focused, set_focused = Bonsai.state None graph in
  (* Reset focus on last element when query changes. *)
  Bonsai.Edge.on_change
    ~trigger:`After_display
    query
    ~equal:[%equal: string]
    ~callback:
      (let%arr set_focused in
       fun _ -> set_focused None)
    graph;
  (* Reset focus on last element when the selection becomes empty. *)
  Bonsai.Edge.on_change
    ~trigger:`After_display
    state
    ~equal:[%equal: _ list]
    ~callback:
      (let%arr set_focused in
       function
       | [] -> set_focused None
       | _ -> Effect.Ignore)
    graph;
  let inject =
    let%arr focused and set_focused and query and state and set_state in
    function
    | `Esc | `Blur -> set_focused None
    | `Left ->
      (* Go left, or enter focus on last element when not typing. *)
      (match focused with
       | Some idx -> set_focused (Some (if idx > 0 then idx - 1 else 0))
       | None when String.is_empty query -> set_focused (Some (List.length state - 1))
       | None -> Effect.Ignore)
    | `Right ->
      (* Go right or exit focus. *)
      (match focused with
       | Some idx ->
         if idx < List.length state - 1
         then set_focused (Some (idx + 1))
         else set_focused None
       | None -> Effect.Ignore)
    | `Backspace when String.is_empty query ->
      (* Enter focus or remove current element. *)
      (match focused with
       | None ->
         if List.length state = 0
         then Effect.Ignore
         else set_focused (Some (List.length state - 1))
       | Some idx ->
         let new_state = List.filteri state ~f:(fun i _ -> i <> idx) in
         let%bind.Effect () =
           if List.is_empty new_state
           then set_focused None
           else set_focused (Some (max (idx - 1) 0))
         in
         set_state new_state)
    | `Backspace -> Effect.Ignore
  in
  focused, inject
;;

let on_click_focus_child_input (event : Js_of_ocaml.Dom_html.mouseEvent Js_of_ocaml.Js.t) =
  let open Js_of_ocaml in
  let target = event##.target in
  Js.Opt.case target (const Effect.Ignore) (fun target ->
    (* Focus the last [<input/>] child element. *)
    let children = target##.childNodes in
    let rec loop idx =
      if idx < 0
      then ()
      else (
        let child = Js.Opt.get (children##item idx) (fun () -> assert false) in
        match Js.to_string child##.nodeName with
        | "INPUT" -> (Js.Unsafe.coerce child)##focus
        | _ -> loop (idx - 1))
    in
    Effect.of_sync_fun loop (children##.length - 1))
;;

let on_click_focus_sibling_input
  (event : Js_of_ocaml.Dom_html.mouseEvent Js_of_ocaml.Js.t)
  =
  let open Js_of_ocaml in
  let target = event##.target in
  Js.Opt.case target (const Effect.Ignore) (fun target ->
    (* Focus the last [<input/>] child element. *)
    let maybe_focus () =
      let sibling = target##.nextSibling in
      Js.Opt.iter sibling (fun sibling ->
        match Js.to_string sibling##.nodeName with
        | "INPUT" -> (Js.Unsafe.coerce sibling)##focus
        | _ -> ())
    in
    Effect.of_thunk maybe_focus)
;;

let component
  ?test_selector
  ?state:external_state
  ?(disabled = return false)
  ?(autofocus = return false)
  ?score
  ?(max_visible_suggestions = return 5)
  ?suggestion
  ?selection
  ?(no_matching_suggestions = return Vdom.Node.none)
  ~to_string
  ~placeholder
  suggestions
  graph
  =
  let state, set_state =
    match external_state with
    | Some (state, set_state) -> state, set_state
    | None -> Bonsai.state [] graph
  in
  let query, set_query = Bonsai.state "" graph in
  let focused, update_focused_selection =
    focused_selection ~query ~state ~set_state graph
  in
  let suggestion_list, inject =
    let score =
      match score with
      | Some score -> score query
      | None ->
        let%arr query and to_string in
        let query = Fuzzy_search.Query.create query in
        fun item -> Fuzzy_search.score query ~item:(to_string item)
    in
    let on_select =
      let%arr set_query and state and set_state in
      fun item -> Effect.all_unit [ set_query ""; set_state (List.append state [ item ]) ]
    in
    Private_skyline_typeahead.component
      ~query
      ~to_string
      ~limit:max_visible_suggestions
      ~score
      ~on_select
      ~on_tab_complete:(return (const Effect.Ignore))
      ~suggestion
      ~no_matching_suggestions
      suggestions
      graph
  in
  let input_width, set_input_width = Bonsai.state 0. graph in
  let view =
    let%arr inject
    and query
    and set_query
    and disabled
    and placeholder
    and update_focused_selection
    and state
    and autofocus =
      match%arr autofocus with
      | true -> Private_skyline_autofocus.focus_on_mount
      | false -> Vdom.Attr.empty
    and suggestion_list
    and suggestions =
      let track_width =
        let%arr set_input_width in
        Bonsai_web_element_size_hooks.Size_tracker.on_change (fun dims ->
          set_input_width dims.border_box.width)
      in
      match%sub suggestion_list with
      | `Idle -> track_width
      | `Empty vdom | `Matches vdom ->
        let%arr track_width
        and popover =
          Private_skyline_typeahead.suggestion_popover ~input_width vdom graph
        in
        Vdom.Attr.combine track_width popover
    and selected =
      let%arr state
      and set_state
      and focused
      and selection =
        match selection with
        | Some selection -> selection
        | None ->
          let%arr to_string in
          fun item -> Skyline_text_v1.span ~size:Small (to_string item)
      in
      let drop_item idx_to_drop =
        let%bind.Effect state =
          Effect.of_sync_fun (List.filteri ~f:(fun idx _ -> idx <> idx_to_drop)) state
        in
        set_state state
      in
      List.mapi state ~f:(fun idx item ->
        let selected = Option.value_map focused ~f:(Int.equal idx) ~default:false in
        chip ~selected ~on_click:(drop_item idx) (selection item))
    in
    let disabled =
      if disabled
      then
        Vdom.Attr.many
          [ Vdom.Attr.style (Css_gen.create ~field:"cursor" ~value:"not-allowed")
          ; Vdom.Attr.disabled
          ]
      else Vdom.Attr.empty
    in
    let on_key_press event =
      let code = Js_of_ocaml.Dom_html.Keyboard_code.of_event event in
      let () =
        match code with
        | ArrowUp | ArrowDown -> Js_of_ocaml.Dom.preventDefault event
        | _ -> ()
      in
      let deactivate_when_entering_focus =
        if String.is_empty query && not (List.is_empty state)
        then inject Deactivate
        else Effect.return ()
      in
      match (code : Js_of_ocaml.Dom_html.Keyboard_code.t) with
      | Escape ->
        (* Prevent the escape event bubbling when suggestions are displayed so that we
           don't e.g. dismiss an open dialog when a type-ahead is closed with the escape
           key. *)
        let has_active_suggestions =
          match suggestion_list with
          | `Idle -> false
          | `Empty _ | `Matches _ -> true
        in
        if has_active_suggestions
        then (
          Js_of_ocaml.Dom.preventDefault event;
          Js_of_ocaml.Dom_html.stopPropagation event);
        let%bind.Effect () = inject Deactivate in
        update_focused_selection `Esc
      | ArrowUp -> inject Move_up
      | ArrowDown -> inject Move_down
      | Enter -> inject Select_current
      | ArrowLeft ->
        let%bind.Effect () = deactivate_when_entering_focus in
        update_focused_selection `Left
      | ArrowRight -> update_focused_selection `Right
      | Backspace ->
        let%bind.Effect () = deactivate_when_entering_focus in
        update_focused_selection `Backspace
      | _ -> Effect.Ignore
    in
    Skyline_flex_v1.row
      ~wrap:Wrap
      ~gap:(`Px 4)
      ~align:Center
      ~justify:Flex_start
      ~attrs:[ Style.input; suggestions; Vdom.Attr.on_click on_click_focus_child_input ]
      [ Skyline_flex_v1.row
          ~wrap:Wrap
          ~align:Center
          ~gap:(`Px 4)
          ~attrs:[ Vdom.Attr.on_click on_click_focus_sibling_input ]
          selected
      ; Vdom.Node.input
          ~key:"input"
          ~attrs:
            [ disabled
            ; autofocus
            ; Vdom.Attr.placeholder placeholder
            ; Vdom.Attr.value query
            ; Vdom.Attr.on_input (fun _ input ->
                let%bind.Effect () = set_query input in
                inject Activate)
            ; Vdom.Attr.on_focus (fun _ -> inject Activate)
            ; Vdom.Attr.on_blur (fun _ ->
                let%bind.Effect () = inject Deactivate in
                update_focused_selection `Blur)
            ; Vdom.Attr.on_keydown on_key_press
            ; Test_selector.attr_of_opt test_selector
            ]
          ()
      ]
  in
  Skyline_input_v1.create view state set_state
;;

let view input = Skyline_input_v1.view input
let value input = Skyline_input_v1.value input
let update input state = Skyline_input_v1.update input state
