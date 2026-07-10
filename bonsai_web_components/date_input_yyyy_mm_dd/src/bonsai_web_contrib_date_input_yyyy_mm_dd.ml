open! Core
open! Bonsai_web
open Bonsai.Let_syntax

let update_parts_from_date date ~set_yyyy ~set_mm ~set_dd =
  match date with
  | None -> Effect.all_unit [ set_yyyy None; set_mm None; set_dd None ]
  | Some date ->
    let parts = Date.to_string date |> String.split ~on:'-' in
    let part n = List.nth parts n in
    Effect.all_unit [ set_yyyy (part 0); set_mm (part 1); set_dd (part 2) ]
;;

let focus ?name_for_testing (local_ graph) =
  let%sub { focus; attr; blur = _ } = Effect.Focus.on_effect ?name_for_testing () graph in
  focus, attr
;;

let hidden_input_for_date_picker date ~id ~disabled ~on_change ~on_forwarded_click =
  Vdom_input_widgets.Entry.date
    ~extra_attrs:
      [ [%css
          {|
            visibility: hidden;
            padding: 0;
            margin: 0;
            border: none;
            height: 0;
            width: 0;
            user-select: none;
          |}]
      ; Vdom.Attr.id id
      ; Vdom.Attr.tabindex (-1)
      ; (* [on_forwarded_click] is the click event forwarded to <input> by a <label>
           ancestor. It's not possible otherwise to click this element. *)
        Vdom.Attr.on_click on_forwarded_click
      ]
    ~disabled
    ~value:date
    ~on_input:on_change
    ()
;;

module State = struct
  type t =
    { value : Date.t option
    ; yyyy_part : Date_part_input_state.t
    ; yyyy_apply_action : Date_part_input_state.Action.t -> string option Effect.t
    ; yyyy_part_valid : bool
    ; mm_part : Date_part_input_state.t
    ; mm_apply_action : Date_part_input_state.Action.t -> string option Effect.t
    ; mm_part_valid : bool
    ; dd_part : Date_part_input_state.t
    ; dd_apply_action : Date_part_input_state.Action.t -> string option Effect.t
    ; dd_part_valid : bool
    ; focus_yyyy : unit Effect.t
    ; focus_mm : unit Effect.t
    ; focus_dd : unit Effect.t
    ; focus_attr_yyyy : Vdom.Attr.t
    ; focus_attr_mm : Vdom.Attr.t
    ; focus_attr_dd : Vdom.Attr.t
    ; set_value : Date.t option -> unit Effect.t
    ; hidden_date_input_id : string
    }

  let is_valid_day
    ~(yyyy_part : Date_part_input_state.t Bonsai.t)
    ~(mm_part : Date_part_input_state.t Bonsai.t)
    ~(dd_part : Date_part_input_state.t Bonsai.t)
    =
    let%arr yyyy_part and mm_part and dd_part in
    let day = Option.value dd_part.value ~default:"" in
    let in_default_range day = day >= 1 && day <= 31 in
    let to_int part = Option.map part ~f:Int.of_string in
    match to_int yyyy_part.value, to_int mm_part.value, Int.of_string_opt day with
    | Some year, Some month, Some day ->
      (match Month.of_int month with
       | None -> in_default_range day
       (* we only validate the real day range when [year] and [month] are present,
          otherwise [day] will be highlighted red every time [year] or [month] are
          missing/invalid *)
       | Some month -> day >= 1 && day <= Date.days_in_month ~year ~month)
    | _, _, Some day -> in_default_range day
    | _, _, _ -> true
  ;;

  let create ?state (local_ graph) =
    let value, set_value =
      match state with
      | Some state -> state
      | None -> Bonsai.state_opt graph
    in
    let yyyy_part, yyyy_apply_action =
      Date_part_input_state.create ~format:"YYYY" ~max_value:9999 graph
    in
    let yyyy_part_valid =
      let%arr yyyy_part in
      let yyyy = Option.value yyyy_part.value ~default:"" in
      match Int.of_string_opt yyyy with
      | None -> true
      | Some yyyy -> yyyy >= 1 && yyyy <= yyyy_part.max_value
    in
    let mm_part, mm_apply_action =
      Date_part_input_state.create ~format:"MM" ~max_value:12 graph
    in
    let mm_part_valid =
      let%arr mm_part in
      let mm = Option.value mm_part.value ~default:"" in
      match Int.of_string_opt mm with
      | None -> true
      | Some mm -> mm >= 1 && mm <= mm_part.max_value
    in
    let dd_part, dd_apply_action =
      Date_part_input_state.create ~format:"DD" ~max_value:31 graph
    in
    let dd_part_valid = is_valid_day ~yyyy_part ~mm_part ~dd_part in
    let set_part_value apply_action =
      let%arr apply_action in
      fun value ->
        let%bind.Effect _ = apply_action (Date_part_input_state.Action.Set_value value) in
        Effect.Ignore
    in
    let combined_date_value =
      let%arr yyyy_part and mm_part and dd_part in
      let yyyy = Date_part_input_state.to_string yyyy_part in
      let mm = Date_part_input_state.to_string mm_part in
      let dd = Date_part_input_state.to_string dd_part in
      try Some (Date.of_string [%string "%{yyyy}-%{mm}-%{dd}"]) with
      | _ -> None
    in
    let set_yyyy = set_part_value yyyy_apply_action in
    let set_mm = set_part_value mm_apply_action in
    let set_dd = set_part_value dd_apply_action in
    let interactive_set =
      let%arr set_yyyy and set_mm and set_dd in
      fun value -> update_parts_from_date value ~set_yyyy ~set_mm ~set_dd
    in
    let () =
      Bonsai_extra.Mirror.mirror
        ~equal:[%equal: Date.t option]
        ~store_value:value
        ~store_set:set_value
        ~interactive_value:combined_date_value
        ~interactive_set
        graph
    in
    let focus_yyyy, focus_attr_yyyy = focus ~name_for_testing:"yyyy" graph in
    let focus_mm, focus_attr_mm = focus ~name_for_testing:"mm" graph in
    let focus_dd, focus_attr_dd = focus ~name_for_testing:"dd" graph in
    let%arr yyyy_part
    and yyyy_apply_action
    and yyyy_part_valid
    and mm_part
    and mm_apply_action
    and mm_part_valid
    and dd_part
    and dd_apply_action
    and dd_part_valid
    and focus_yyyy
    and focus_mm
    and focus_dd
    and focus_attr_yyyy
    and focus_attr_mm
    and focus_attr_dd
    and value
    and set_value
    and hidden_date_input_id = Bonsai.path_id graph in
    { yyyy_part
    ; yyyy_apply_action
    ; yyyy_part_valid
    ; mm_part
    ; mm_apply_action
    ; mm_part_valid
    ; dd_part
    ; dd_apply_action
    ; dd_part_valid
    ; focus_yyyy
    ; focus_mm
    ; focus_dd
    ; focus_attr_yyyy
    ; focus_attr_mm
    ; focus_attr_dd
    ; value
    ; set_value
    ; hidden_date_input_id
    }
  ;;
end

module Content = struct
  type t =
    | Vdom of Vdom.Node.t
    | Yyyy_part of (value:string -> attrs:Vdom.Attr.t list -> Vdom.Node.t)
    | Mm_part of (value:string -> attrs:Vdom.Attr.t list -> Vdom.Node.t)
    | Dd_part of (value:string -> attrs:Vdom.Attr.t list -> Vdom.Node.t)
    | Date_picker_icon of (attrs:Vdom.Attr.t list -> Vdom.Node.t)

  let focus_for_part ~(state : State.t) t =
    match t with
    | Vdom _ -> None
    | Yyyy_part _ -> Some state.focus_yyyy
    | Mm_part _ -> Some state.focus_mm
    | Dd_part _ -> Some state.focus_dd
    | Date_picker_icon _ -> None
  ;;

  let render
    ~disabled
    ~(state : State.t)
    ~focus_prev_part
    ~focus_next_part
    ~focus_last_part
    t
    : Vdom.Node.t
    =
    let make_render_part ~date_part ~apply_action ~focus_attr render =
      let attrs =
        if disabled
        then []
        else (
          let ignore_result effect =
            let%bind.Effect _ = effect in
            Effect.Ignore
          in
          let on_key_down event =
            let with_stop_propagation effect =
              let event = Browser_extra.Coercion.of_jsoo_event event in
              event##preventDefault;
              event##stopPropagation;
              effect |> ignore_result
            in
            match Vdom_keyboard.Keyboard_event.Keyboard_code.of_event event with
            | Backspace | Delete ->
              (match date_part.Date_part_input_state.value with
               | None -> focus_prev_part |> with_stop_propagation
               | Some _ ->
                 apply_action Date_part_input_state.Action.Reset_value
                 |> with_stop_propagation)
            | ArrowUp ->
              apply_action Date_part_input_state.Action.Increase_by_one
              |> with_stop_propagation
            | ArrowDown ->
              apply_action Date_part_input_state.Action.Decrease_by_one
              |> with_stop_propagation
            | ArrowRight -> focus_next_part |> with_stop_propagation
            | ArrowLeft -> focus_prev_part |> with_stop_propagation
            | _ ->
              let value =
                let code = Vdom_keyboard.Keystroke.Keyboard_code.of_event event in
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
              in
              (match value with
               | None -> Effect.Ignore
               | Some value ->
                 let%bind.Effect (next_value : string option) =
                   apply_action (Date_part_input_state.Action.Append_value value)
                 in
                 if String.length (Option.value next_value ~default:"")
                    = String.length date_part.Date_part_input_state.format
                 then focus_next_part
                 else Effect.Ignore)
          in
          let on_key_down_attr = Vdom.Attr.on_keydown on_key_down in
          (* Instead of explicitly handling clicks on the yyyy/mm/dd segments, we add
             tabindex and listen for focus events (which include mousedown). This also
             handles keyboard navigation more robustly. *)
          let on_focus_attr =
            Vdom.Attr.on_focus (fun _ ->
              apply_action Date_part_input_state.Action.Focus |> ignore_result)
          in
          (* Work around native <label> click forwarding, which triggers a click event on
             the hidden input that we don't want. *)
          let on_click_attr =
            Vdom.Attr.on_click (fun event ->
              (* We use [preventDefault] instead of [stopPropagation] because <label>
                 click forwarding doesn't actually use event bubbling; it uses "legacy
                 pre-activation behavior" which [preventDefault] disables:
                 https://stackoverflow.com/questions/67612404/why-does-event-stoppropagation-not-prevent-a-label-from-checking-its-checkbo *)
              event##preventDefault;
              Effect.Ignore)
          in
          [ Vdom.Attr.tabindex 0
          ; on_key_down_attr
          ; on_focus_attr
          ; on_click_attr
          ; focus_attr
          ])
      in
      let value = date_part |> Date_part_input_state.to_string in
      render ~value ~attrs
    in
    match t with
    | Vdom node -> node
    | Date_picker_icon render ->
      let attrs =
        if disabled
        then []
        else
          let open Js_of_ocaml in
          let open_date_picker =
            Effect.of_thunk (fun () ->
              let hidden_input =
                Dom_html.document##getElementById (Js.string state.hidden_date_input_id)
              in
              Js.Opt.iter hidden_input (fun input ->
                (* [Dom_html.CoerceTo] doesn't have [date_input] option. We can only
                   coerce to [input] but then would still need an unsafe coerce to call
                   [showPicker ] *)
                let date_input = Js.Unsafe.coerce input in
                date_input##showPicker ()))
          in
          let on_click =
            Vdom.Attr.on_click (fun (event : Dom_html.mouseEvent Js.t) ->
              Dom.preventDefault event;
              open_date_picker)
          in
          let on_keydown =
            Vdom.Attr.on_keydown (fun (event : Dom_html.keyboardEvent Js.t) ->
              match Vdom_keyboard.Keystroke.Keyboard_code.of_event event with
              | Space -> open_date_picker
              | Escape | ArrowLeft -> focus_last_part
              | _ -> Effect.Ignore)
          in
          [ on_click; on_keydown; Vdom.Attr.tabindex 0 ]
      in
      render ~attrs
    | Yyyy_part render ->
      make_render_part
        ~date_part:state.yyyy_part
        ~apply_action:state.yyyy_apply_action
        ~focus_attr:state.focus_attr_yyyy
        render
    | Mm_part render ->
      make_render_part
        ~date_part:state.mm_part
        ~apply_action:state.mm_apply_action
        ~focus_attr:state.focus_attr_mm
        render
    | Dd_part render ->
      make_render_part
        ~date_part:state.dd_part
        ~apply_action:state.dd_apply_action
        ~focus_attr:state.focus_attr_dd
        render
  ;;
end

let view ?test_selector ?(attrs = []) ?(disabled = false) ~(state : State.t) children =
  let focuses = List.map children ~f:(fun child -> Content.focus_for_part ~state child) in
  let focus_first_part =
    focuses |> List.filter_map ~f:Fn.id |> List.hd |> Option.value ~default:Effect.Ignore
  in
  let focus_last_part =
    focuses
    |> List.filter_map ~f:Fn.id
    |> List.last
    |> Option.value ~default:Effect.Ignore
  in
  let hidden_input_for_date_picker =
    hidden_input_for_date_picker
      state.value
      ~id:state.hidden_date_input_id
      ~disabled
      ~on_change:(fun date ->
        let%bind.Effect () = state.set_value date in
        focus_first_part)
      ~on_forwarded_click:(fun _ -> focus_first_part)
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
      Content.render
        ~disabled
        ~state
        ~focus_prev_part
        ~focus_next_part
        ~focus_last_part
        child)
  in
  let on_focus =
    if disabled then Vdom.Attr.empty else Vdom.Attr.on_focus (fun _ -> focus_first_part)
  in
  (* Use [tabindex (-1)] to make the parent div interactable but not in the tab order.
     Clicking on the whitespace in this input focuses the first part (via [on_focus]), but
     shift-tab from the first part does NOT land back on the parent (triggering
     [on_focus], focusing the first part, and creating a focus trap). *)
  {%html|
    <div
      %{Test_selector.attr_of_opt test_selector}
      *{attrs}
      %{Vdom.Attr.tabindex (-1)}
      %{on_focus}
    >
      *{children} %{hidden_input_for_date_picker}
    </div>
  |}
;;

let make_part ?test_selector ?(attrs = []) () ~value ~attrs:inner_attrs =
  {%html|
    <div %{Test_selector.attr_of_opt test_selector} *{attrs} *{inner_attrs}>
      #{value}
    </div>
  |}
;;

let yyyy_part ?test_selector ?attrs () : Content.t =
  Content.Yyyy_part (make_part ?test_selector ?attrs ())
;;

let mm_part ?test_selector ?attrs () : Content.t =
  Content.Mm_part (make_part ?test_selector ?attrs ())
;;

let dd_part ?test_selector ?attrs () : Content.t =
  Content.Dd_part (make_part ?test_selector ?attrs ())
;;

let delimiter ?test_selector ?(attrs = []) ?(char = '-') () : Content.t =
  Content.Vdom
    {%html|
      <div
        %{Test_selector.attr_of_opt test_selector}
        *{attrs}
        style="user-select: none"
      >
        #{Char.to_string char}
      </div>
    |}
;;

let calendar_icon ?test_selector ?(attrs = []) children : Content.t =
  Content.Date_picker_icon
    (fun ~attrs:inner_attrs ->
      {%html|
        <div %{Test_selector.attr_of_opt test_selector} *{attrs} *{inner_attrs}>
          *{children}
        </div>
      |})
;;

module Date_part_input_state = Date_part_input_state
