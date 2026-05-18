open! Core
open! Bonsai_web
open Bonsai.Let_syntax
module Keyboard_code = Vdom_keyboard.Keyboard_event.Keyboard_code

module Segment_state = struct
  type t =
    { state : [ `Nothing_typed | `Something_typed ]
    ; value : string option
    }
  [@@deriving sexp_of]

  module Action = struct
    type t =
      | Start_editing
      | Set_value of (string option -> string option)
      | Append_value of string
  end

  let initial_state = { state = `Nothing_typed; value = None }

  let apply_action model (action : Action.t) =
    match action with
    | Start_editing -> { model with state = `Nothing_typed }
    | Set_value f -> { model with value = f model.value }
    | Append_value value ->
      let new_value =
        match model.state with
        | `Nothing_typed -> value
        | `Something_typed ->
          let prev_value = Option.value ~default:"" model.value in
          prev_value ^ value
      in
      { value = Some new_value; state = `Something_typed }
  ;;

  module For_testing = struct
    let initial_state = initial_state
    let apply_action = apply_action
  end

  let create (local_ graph) =
    Bonsai.actor
      ~default_model:initial_state
      ~recv:(fun _ctx model (action : Action.t) ->
        let next_model = apply_action model action in
        let next_value = next_model.value in
        next_model, next_value)
      graph
  ;;
end

module Segment_spinbutton = struct
  module Config = struct
    type t =
      { placeholder : string
      ; aria_label : string
      ; width : int
      ; display : string -> string
      ; handle_append_keycode : Keyboard_code.t -> string option
      ; increment : string option -> string
      ; decrement : string option -> string
      }

    let sexp_of_t { placeholder; aria_label; width; _ } =
      [%message "" (placeholder : string) (aria_label : string) (width : int)]
    ;;
  end

  type t =
    { state : Segment_state.t
    ; apply_action : Segment_state.Action.t -> string option Effect.t
    ; focus : unit Effect.t
    ; focus_attr : Vdom.Attr.t
    ; config : Config.t
    }

  let sexp_of_t t =
    [%message
      "" ~aria_label:(t.config.aria_label : string) ~segment:(t.state : Segment_state.t)]
  ;;

  let create (config : Config.t) (local_ graph) =
    let state, apply_action = Segment_state.create graph in
    let%sub { focus; attr = focus_attr; blur = _ } =
      Effect.Focus.on_effect ~name_for_testing:config.aria_label () graph
    in
    let%arr state and apply_action and focus and focus_attr in
    { state; apply_action; focus; focus_attr; config }
  ;;
end

let display_value (spinbutton : Segment_spinbutton.t) =
  match spinbutton.state.value with
  | None -> Vdom.Node.text spinbutton.config.placeholder
  | Some value -> Vdom.Node.text (spinbutton.config.display value)
;;

module Content = struct
  type t =
    | Segment of
        { spinbutton : Segment_spinbutton.t
        ; attrs : Vdom.Attr.t list
        }
    | Delimiter of char
    | Vdom of Vdom.Node.t
    | Action_element of
        { on_activate : unit Effect.t
        ; render : attrs:Vdom.Attr.t list -> Vdom.Node.t
        }

  let focus_for_part t =
    match t with
    | Vdom _ | Delimiter _ -> None
    | Segment { spinbutton; _ } -> Some spinbutton.focus
    | Action_element _ -> None
  ;;

  let render ~disabled ~focus_prev_part ~focus_next_part ~focus_last_segment t
    : Vdom.Node.t
    =
    match t with
    | Vdom node -> node
    | Delimiter c -> {%html|<div style="user-select: none">#{Char.to_string c}</div>|}
    | Segment { spinbutton; attrs = caller_attrs } ->
      let { Segment_spinbutton.state = seg_state
          ; apply_action
          ; focus_attr
          ; config
          ; focus = _
          }
        =
        spinbutton
      in
      let attrs =
        if disabled
        then []
        else (
          let on_key_down event =
            let with_stop_propagation effect =
              let event = Browser_extra.Coercion.of_jsoo_event event in
              event##preventDefault;
              event##stopPropagation;
              effect |> Effect.ignore_m
            in
            match Vdom_keyboard.Keyboard_event.Keyboard_code.of_event event with
            | Backspace | Delete ->
              (match seg_state.Segment_state.value with
               | None -> focus_prev_part |> with_stop_propagation
               | Some _ ->
                 apply_action (Set_value (fun _ -> None)) |> with_stop_propagation)
            | ArrowUp ->
              let new_value = config.increment seg_state.value in
              let effect =
                let%bind.Effect _ = apply_action (Set_value (fun _ -> Some new_value)) in
                apply_action Start_editing
              in
              effect |> with_stop_propagation
            | ArrowDown ->
              let new_value = config.decrement seg_state.value in
              let effect =
                let%bind.Effect _ = apply_action (Set_value (fun _ -> Some new_value)) in
                apply_action Start_editing
              in
              effect |> with_stop_propagation
            | ArrowRight -> focus_next_part |> with_stop_propagation
            | ArrowLeft -> focus_prev_part |> with_stop_propagation
            | code ->
              (match config.handle_append_keycode code with
               | None -> Effect.Ignore
               | Some value ->
                 (* If the segment is already complete and we're in append mode, reject
                    further input. This prevents garbage accumulation when the segment is
                    the last in the list (no next part to auto-advance to). *)
                 let already_complete =
                   match seg_state.value, seg_state.state with
                   | Some v, `Something_typed -> String.length v >= config.width
                   | Some _, `Nothing_typed | None, _ -> false
                 in
                 if already_complete
                 then Effect.Ignore
                 else (
                   let%bind.Effect (next_value : string option) =
                     apply_action (Append_value value)
                   in
                   match next_value with
                   | Some v when String.length v >= config.width -> focus_next_part
                   | _ -> Effect.Ignore))
          in
          let on_key_down_attr = Vdom.Attr.on_keydown on_key_down in
          let on_focus_attr =
            Vdom.Attr.on_focus (fun _ -> apply_action Start_editing |> Effect.ignore_m)
          in
          let on_click_attr =
            Vdom.Attr.on_click (fun event ->
              event##preventDefault;
              Effect.Ignore)
          in
          [ Vdom.Attr.create "role" "spinbutton"
          ; Vdom.Attr.create "aria-label" config.aria_label
          ; Vdom.Attr.tabindex 0
          ; on_key_down_attr
          ; on_focus_attr
          ; on_click_attr
          ; focus_attr
          ])
      in
      let value = display_value spinbutton in
      {%html|<div *{caller_attrs} *{attrs}>%{value}</div>|}
    | Action_element { on_activate; render } ->
      let attrs =
        if disabled
        then []
        else (
          let on_click =
            Vdom.Attr.on_click
              (fun (event : Js_of_ocaml.Dom_html.mouseEvent Js_of_ocaml.Js.t) ->
                 Js_of_ocaml.Dom.preventDefault event;
                 on_activate)
          in
          let on_keydown =
            Vdom.Attr.on_keydown
              (fun (event : Js_of_ocaml.Dom_html.keyboardEvent Js_of_ocaml.Js.t) ->
                 match Vdom_keyboard.Keystroke.Keyboard_code.of_event event with
                 | Space -> on_activate
                 | Escape | ArrowLeft -> focus_last_segment
                 | _ -> Effect.Ignore)
          in
          [ on_click; on_keydown; Vdom.Attr.tabindex 0 ])
      in
      render ~attrs
  ;;

  let segment ?(attrs = []) ~segment () = Segment { spinbutton = segment; attrs }
  let delimiter ~char () = Delimiter char
  let vdom node = Vdom (Vdom.Node.fragment node)

  let action_element ~on_activate ?(attrs = []) children =
    Action_element
      { on_activate
      ; render =
          (fun ~attrs:inner_attrs ->
            {%html|<div *{attrs} *{inner_attrs}>*{children}</div>|})
      }
  ;;
end

let view ?test_selector ?(attrs = []) ?(disabled = false) children : Vdom.Node.t =
  let focuses = List.map children ~f:(fun child -> Content.focus_for_part child) in
  let focus_first_part =
    focuses |> List.filter_map ~f:Fn.id |> List.hd |> Option.value ~default:Effect.Ignore
  in
  let focus_last_segment =
    focuses
    |> List.filter_map ~f:Fn.id
    |> List.last
    |> Option.value ~default:Effect.Ignore
  in
  let children =
    children
    |> List.mapi ~f:(fun idx child ->
      let focuses_before, focuses_after =
        let focuses_before, focuses = List.split_n focuses idx in
        let focuses_after = List.drop focuses 1 in
        ( focuses_before |> List.filter_map ~f:Fn.id
        , focuses_after |> List.filter_map ~f:Fn.id )
      in
      let focus_prev_part =
        List.last focuses_before |> Option.value ~default:Effect.Ignore
      in
      let focus_next_part =
        List.hd focuses_after |> Option.value ~default:Effect.Ignore
      in
      Content.render ~disabled ~focus_prev_part ~focus_next_part ~focus_last_segment child)
  in
  let on_focus =
    if disabled then Vdom.Attr.empty else Vdom.Attr.on_focus (fun _ -> focus_first_part)
  in
  {%html|
    <div
      %{Test_selector.attr_of_opt test_selector}
      *{attrs}
      %{Vdom.Attr.tabindex (-1)}
      %{on_focus}
    >
      *{children}
    </div>
  |}
;;

module State = struct
  type ('s, 'a) t =
    { spinbuttons : 's
    ; value : 'a option
    }
  [@@deriving sexp_of]

  let create ~spinbuttons ~parse ~unparse ~equal ?state (local_ graph) =
    let external_value, external_set =
      Option.value_or_thunk state ~default:(fun () -> Bonsai.state_opt graph)
    in
    let interactive_value =
      let%arr spinbuttons in
      parse spinbuttons
    in
    let interactive_set =
      let%arr spinbuttons in
      fun value -> unparse spinbuttons value
    in
    let () =
      Bonsai_extra.Mirror.mirror
        ~equal
        ~store_value:external_value
        ~store_set:external_set
        ~interactive_value
        ~interactive_set
        graph
    in
    let%arr spinbuttons
    and value = external_value in
    { spinbuttons; value }
  ;;
end
