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

  let apply_action ~width model (action : Action.t) =
    match action with
    | Start_editing -> { model with state = `Nothing_typed }
    | Set_value f ->
      (* We support a [Set_value] action instead of a higher-level "increment/decrement"
         action because we want idempotency within a single frame. If the user holds
         [UpArrow], we want to increment once, then render, then increment again, and so
         on. This is a UX decision; otherwise a high key repeat rate would look like the
         spinbutton is skipping steps.

         While [Set_value] is idempotent, [Append_value] below is not. *)
      { model with value = f model.value }
    | Append_value value ->
      let new_value =
        match model.state with
        | `Nothing_typed -> value
        | `Something_typed ->
          let prev_value = Option.value ~default:"" model.value in
          (* The calling on_key_down handler on the spinbutton normally prevents overflow
             by checking the length of the current string value, but this logic is based
             on Bonsai data so it may be stale: a burst of keydown events within a single
             frame (with no intermediate stabilizations) can push the value past the
             configured width. Since we have access to the state machine's previous value
             here, we re-check the appended value against the width and drop the edit if
             it would overflow.

             While simple [UpArrow]/[DownArrow] handling can be made idempotent by using
             [Set_value], actual typing cannot be because each individual key is probably
             important. *)
          if String.length prev_value >= width then prev_value else prev_value ^ value
      in
      { value = Some new_value; state = `Something_typed }
  ;;

  let create ~width (local_ graph) =
    Bonsai.actor
      ~default_model:initial_state
      ~recv:(fun _ctx model (action : Action.t) ->
        let next_model = apply_action ~width model action in
        let next_value = next_model.value in
        next_model, next_value)
      graph
  ;;
end

module Segment_spinbutton = struct
  module Config = struct
    type t =
      { placeholder : string
      ; label : string
      ; aria_attrs : value:string option -> Vdom.Attr.t list
      ; width : int
      ; display : string -> string
      ; handle_append_keycode : Keyboard_code.t -> string option
      ; jump_one_up : string option -> string
      ; jump_one_down : string option -> string
      ; jump_page_up : (string option -> string) option
      ; jump_page_down : (string option -> string) option
      ; jump_top : (unit -> string) option
      ; jump_bottom : (unit -> string) option
      }

    let sexp_of_t { placeholder; label; width; _ } =
      [%message "" (placeholder : string) (label : string) (width : int)]
    ;;

    let make
      ~placeholder
      ~aria_label
      ~display
      ~handle_append_keycode
      ~jump_one_up
      ~jump_one_down
      ?jump_page_up
      ?jump_page_down
      ?jump_top
      ?jump_bottom
      ()
      =
      { placeholder
      ; label = aria_label
      ; aria_attrs = (fun ~value:_ -> [ Vdom.Attr.create "aria-label" aria_label ])
      ; width = String.length placeholder
      ; display
      ; handle_append_keycode
      ; jump_one_up
      ; jump_one_down
      ; jump_page_up
      ; jump_page_down
      ; jump_top
      ; jump_bottom
      }
    ;;

    let handle_numeric_keycode (code : Keyboard_code.t) =
      match code with
      | Digit0 | Numpad0 -> Some "0"
      | Digit1 | Numpad1 -> Some "1"
      | Digit2 | Numpad2 -> Some "2"
      | Digit3 | Numpad3 -> Some "3"
      | Digit4 | Numpad4 -> Some "4"
      | Digit5 | Numpad5 -> Some "5"
      | Digit6 | Numpad6 -> Some "6"
      | Digit7 | Numpad7 -> Some "7"
      | Digit8 | Numpad8 -> Some "8"
      | Digit9 | Numpad9 -> Some "9"
      | _ -> None
    ;;

    let zero_pad ~width value =
      let pad_len = max 0 (width - String.length value) in
      String.make pad_len '0' ^ value
    ;;

    let wrap_inclusive ~min ~max value = min + ((value - min) % (max - min + 1))

    let increment_numeric ~default ~min ~max ~step value =
      match Option.bind value ~f:Int.of_string_opt with
      | None -> Int.to_string (Option.value default ~default:min)
      | Some n -> Int.to_string (wrap_inclusive ~min ~max (n + step))
    ;;

    let decrement_numeric ~default ~min ~max ~step value =
      match Option.bind value ~f:Int.of_string_opt with
      | None -> Int.to_string (Option.value default ~default:max)
      | Some n -> Int.to_string (wrap_inclusive ~min ~max (n - step))
    ;;

    let make_numeric ~placeholder ~aria_label ~min ~max ~step ?default () =
      let width = String.length placeholder in
      let aria_attrs ~value =
        let attrs =
          [ Vdom.Attr.create "aria-label" aria_label
          ; Vdom.Attr.create "aria-valuemin" (Int.to_string min)
          ; Vdom.Attr.create "aria-valuemax" (Int.to_string max)
          ]
        in
        match value with
        | None -> attrs
        | Some value -> attrs @ [ Vdom.Attr.create "aria-valuenow" value ]
      in
      { placeholder
      ; label = aria_label
      ; aria_attrs
      ; width
      ; handle_append_keycode = handle_numeric_keycode
      ; display = zero_pad ~width
      ; jump_one_up = increment_numeric ~default ~step:1 ~min ~max
      ; jump_one_down = decrement_numeric ~default ~step:1 ~min ~max
      ; jump_page_up = Some (fun v -> increment_numeric ~default ~step ~min ~max v)
      ; jump_page_down = Some (fun v -> decrement_numeric ~default ~step ~min ~max v)
      ; jump_top = Some (fun () -> Int.to_string min)
      ; jump_bottom = Some (fun () -> Int.to_string max)
      }
    ;;

    module For_testing = struct
      let wrap_inclusive = wrap_inclusive
    end
  end

  type t =
    { state : Segment_state.t
    ; apply_action : Segment_state.Action.t -> string option Effect.t
    ; focus : unit Effect.t
    ; focus_attr : Vdom.Attr.t
    ; config : Config.t
    }

  let sexp_of_t t =
    [%message "" ~label:(t.config.label : string) ~segment:(t.state : Segment_state.t)]
  ;;

  let create (config : Config.t) (local_ graph) =
    let state, apply_action = Segment_state.create ~width:config.width graph in
    let%sub { focus; attr = focus_attr; blur = _ } =
      Effect.Focus.on_effect ~name_for_testing:config.label () graph
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

  let focus_for_part t =
    match t with
    | Delimiter _ -> None
    | Segment { spinbutton; _ } -> Some spinbutton.focus
  ;;

  (** - [disabled] whether interactivity is disabled
      - [focus_prev_part] effect to focus the part to the left
      - [focus_next_part] effect to focus the part to the right
      - [activate_action] effect to trigger the hidden action element (e.g. a hidden
        <input type="date">) *)
  let render ~disabled ~focus_prev_part ~focus_next_part ~activate_action t : Vdom.Node.t =
    match t with
    | Delimiter c -> {%html|<span>#{Char.to_string c}</span>|}
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
            let maybe_jump_to_value = function
              | None -> Effect.Ignore
              | Some v ->
                let effect =
                  let%bind.Effect _ = apply_action (Set_value (fun _ -> Some v)) in
                  apply_action Start_editing
                in
                effect |> Effect.ignore_m
            in
            match Vdom_keyboard.Keyboard_event.Keyboard_code.of_event event with
            | Backspace | Delete ->
              (match seg_state.Segment_state.value with
               | None -> focus_prev_part |> with_stop_propagation
               | Some _ ->
                 apply_action (Set_value (fun _ -> None)) |> with_stop_propagation)
            | ArrowUp ->
              let new_value = config.jump_one_up seg_state.value in
              let effect =
                let%bind.Effect _ = apply_action (Set_value (fun _ -> Some new_value)) in
                apply_action Start_editing
              in
              effect |> with_stop_propagation
            | ArrowDown ->
              let new_value = config.jump_one_down seg_state.value in
              let effect =
                let%bind.Effect _ = apply_action (Set_value (fun _ -> Some new_value)) in
                apply_action Start_editing
              in
              effect |> with_stop_propagation
            | ArrowRight -> focus_next_part |> with_stop_propagation
            | ArrowLeft -> focus_prev_part |> with_stop_propagation
            | PageUp ->
              Option.map config.jump_page_up ~f:(fun f -> f seg_state.value)
              |> maybe_jump_to_value
              |> with_stop_propagation
            | PageDown ->
              Option.map config.jump_page_down ~f:(fun f -> f seg_state.value)
              |> maybe_jump_to_value
              |> with_stop_propagation
            | Home ->
              Option.map config.jump_top ~f:(fun f -> f ())
              |> maybe_jump_to_value
              |> with_stop_propagation
            | End ->
              Option.map config.jump_bottom ~f:(fun f -> f ())
              |> maybe_jump_to_value
              |> with_stop_propagation
            | Space ->
              Option.value activate_action ~default:Effect.Ignore |> with_stop_propagation
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
            (* Prevent the wrapping <label> (from Skyline_field_v2.view) from forwarding
               clicks to the hidden focus target. Without this, clicking on any date part
               (e.g. mm) would be overridden by the label activating the hidden input and
               redirecting focus to yyyy. Mouse focus already happens on mousedown (before
               click), so preventing default on click only suppresses the label forwarding
               without affecting normal focus behavior. *)
            Vdom.Attr.on_click (fun event ->
              event##preventDefault;
              Effect.Ignore)
          in
          config.aria_attrs ~value:spinbutton.state.value
          @ [ Vdom.Attr.role "spinbutton"
            ; Vdom.Attr.tabindex 0
            ; on_key_down_attr
            ; on_focus_attr
            ; on_click_attr
            ; focus_attr
            ])
      in
      let value = display_value spinbutton in
      {%html|<span *{caller_attrs} *{attrs}>%{value}</span>|}
  ;;

  let segment ?(attrs = []) ~segment () = Segment { spinbutton = segment; attrs }
  let delimiter ~char () = Delimiter char
end

module Action_element = struct
  type t =
    { on_activate : unit Effect.t
    ; attrs : Vdom.Attr.t list
    ; children : Vdom.Node.t list
    }

  let content ~on_activate ?(attrs = []) children = { on_activate; attrs; children }

  let render ~disabled ~focus_last_segment action_element : Vdom.Node.t =
    let attrs =
      if disabled
      then []
      else (
        let on_click =
          Vdom.Attr.on_click
            (fun (event : Js_of_ocaml.Dom_html.mouseEvent Js_of_ocaml.Js.t) ->
               Js_of_ocaml.Dom.preventDefault event;
               action_element.on_activate)
        in
        let on_keydown =
          Vdom.Attr.on_keydown
            (fun (event : Js_of_ocaml.Dom_html.keyboardEvent Js_of_ocaml.Js.t) ->
               match Vdom_keyboard.Keystroke.Keyboard_code.of_event event with
               | Space -> action_element.on_activate
               | Escape | ArrowLeft -> focus_last_segment
               | _ -> Effect.Ignore)
        in
        [ on_click; on_keydown; Vdom.Attr.tabindex 0; Vdom.Attr.role "button" ])
    in
    {%html|<div *{attrs} *{action_element.attrs}>*{action_element.children}</div>|}
  ;;
end

module Hidden_element = struct
  type t = { children : Vdom.Node.t list }

  let content children = { children }
  let render hidden_element : Vdom.Node.t = Vdom.Node.fragment hidden_element.children
end

let view
  ?test_selector
  ?(attrs = [])
  ?(disabled = false)
  ?action_element
  ?hidden_element
  children
  : Vdom.Node.t
  =
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
  let activate_action =
    Option.map action_element ~f:(fun (a : Action_element.t) -> a.on_activate)
  in
  let children =
    children
    |> List.mapi ~f:(fun idx child ->
      let focuses_before, focuses_after =
        let #(focuses_before, focuses) = List.split_n focuses idx in
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
      Content.render ~disabled ~focus_prev_part ~focus_next_part ~activate_action child)
  in
  let action_element =
    match action_element with
    | Some action_element ->
      Action_element.render ~disabled ~focus_last_segment action_element
    | None -> Vdom.Node.None
  in
  let hidden_element =
    match hidden_element with
    | Some hidden_element -> Hidden_element.render hidden_element
    | None -> Vdom.Node.None
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
      <div>*{children}</div>
      %{action_element}%{hidden_element}
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
