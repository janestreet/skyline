open! Core
open! Private_skyline_prelude
module Keyboard_code = Segmented_input.Keyboard_code

let handle_digit_keycode (code : Keyboard_code.t) =
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

let numeric_increment ~max value =
  match Option.bind value ~f:Int.of_string_opt with
  | None -> "1"
  | Some n -> Int.to_string (if n >= max then 0 else n + 1)
;;

let numeric_decrement ~max value =
  match Option.bind value ~f:Int.of_string_opt with
  | None -> Int.to_string max
  | Some n -> Int.to_string (if n <= 0 then max else n - 1)
;;

let zero_pad ~width value =
  let pad_len = max 0 (width - String.length value) in
  String.make pad_len '0' ^ value
;;

let validate_numeric_range ~max value =
  match Int.of_string_opt value with
  | None -> value, Some (Error.of_string "not a number")
  | Some n when n >= 0 && n <= max -> value, None
  | Some n -> value, Some (Error.create_s [%message "out of range" (n : int) (max : int)])
;;

let hh_config : Segmented_input.Segment_spinbutton.Config.t =
  { placeholder = "HH"
  ; aria_label = "hours"
  ; width = 2
  ; display = zero_pad ~width:2
  ; handle_append_keycode = handle_digit_keycode
  ; increment = numeric_increment ~max:23
  ; decrement = numeric_decrement ~max:23
  }
;;

let mm_config : Segmented_input.Segment_spinbutton.Config.t =
  { placeholder = "MM"
  ; aria_label = "minutes"
  ; width = 2
  ; display = zero_pad ~width:2
  ; handle_append_keycode = handle_digit_keycode
  ; increment = numeric_increment ~max:59
  ; decrement = numeric_decrement ~max:59
  }
;;

let ss_config : Segmented_input.Segment_spinbutton.Config.t =
  { placeholder = "SS"
  ; aria_label = "seconds"
  ; width = 2
  ; display = zero_pad ~width:2
  ; handle_append_keycode = handle_digit_keycode
  ; increment = numeric_increment ~max:59
  ; decrement = numeric_decrement ~max:59
  }
;;

type hh_mm =
  hh:Segmented_input.Segment_spinbutton.t * mm:Segmented_input.Segment_spinbutton.t

type hh_mm_ss =
  hh:Segmented_input.Segment_spinbutton.t
  * mm:Segmented_input.Segment_spinbutton.t
  * ss:Segmented_input.Segment_spinbutton.t

module Format = struct
  type _ gadt =
    | HH_MM : hh_mm gadt
    | HH_MM_SS : hh_mm_ss gadt

  type packed = T : _ gadt -> packed

  type t =
    | HH_MM
    | HH_MM_SS
  [@@deriving sexp_of, equal]

  let to_packed = function
    | HH_MM -> T HH_MM
    | HH_MM_SS -> T HH_MM_SS
  ;;

  let of_gadt (type s) (gadt : s gadt) : t =
    match gadt with
    | HH_MM -> HH_MM
    | HH_MM_SS -> HH_MM_SS
  ;;
end

module Style = struct
  let container ~disabled ~size ~intent =
    let container_base =
      {%css|
        box-sizing: border-box;
        display: inline-flex;
        align-items: center;
        width: 100%;
        border-width: 1px;
        border-style: solid;
        background-color: %{Skyline_tokens_v2.Colors.Background.input#Css_gen.Color};
        color: %{Skyline_tokens_v2.Colors.Text.default#Css_gen.Color};
        cursor: text;
        font-family: %{Skyline_tokens_v2.Font.Family.monospace#Skyline_tokens_v2.Font.Family};
      |}
    in
    let container_size size =
      (* Set the size via min-height to dodge border issues like [Skyline_button_v2]. *)
      (* NOTE: The container is responsible for vertically centering contents. *)
      Attr.many
        (match size with
         | `Xs -> Classes.[ min_h 4.5; px 0.5; rounded_xs; text_xs ]
         | `Sm -> Classes.[ min_h 6.; px 1.; rounded_xs; text_sm ]
         | `Md -> Classes.[ min_h 7.; px 2.; rounded_sm; text_sm ]
         | `Lg -> Classes.[ min_h 8.; px 2.; rounded_md; text_sm ])
    in
    let focus_color (intent : Skyline_field_v2.Intent.t) =
      let border, shadow =
        match intent with
        | `Primary -> Colors.Border.primary, Colors.Shadow.primary
        | `Danger -> Colors.Border.danger, Colors.Shadow.danger
        | `Success -> Colors.Border.success, Colors.Shadow.success
        | `Warning -> Colors.Border.warning, Colors.Shadow.warning
      in
      {%css|
        &:focus-within,
        &.for-testing--force-focus-visible {
          @media not (prefers-reduced-motion: reduce) {
            transition: box-shadow 150ms ease-in-out;
          }
          border-color: %{border#Css_gen.Color};
          box-shadow: 0 0 0 3px %{shadow#Css_gen.Color};
        }
      |}
    in
    let container_colors ~disabled (intent : Skyline_field_v2.Intent.t) =
      if disabled
      then
        {%css|
          background-color: %{Colors.Background.input_disabled#Css_gen.Color};
          color: %{Colors.Text.disabled#Css_gen.Color};
          border-color: %{Colors.Border.default#Css_gen.Color};
        |}
      else (
        match intent with
        | `Primary -> Classes.border_default
        | `Danger -> Classes.border_danger
        | `Success -> Classes.border_success
        | `Warning -> Classes.border_warning)
    in
    Attr.many
      [ container_base
      ; container_colors ~disabled intent
      ; (if disabled then Attr.empty else focus_color intent)
      ; container_size size
      ]
  ;;

  let part ~disabled ~is_valid ~is_placeholder size intent =
    let part_base =
      {%css|
        display: inline-block;
        outline: none;
        font-family: inherit;
        color: inherit;
        width: fit-content;
      |}
    in
    let part_color (intent : Skyline_field_v2.Intent.t) =
      let background, text, hover_background =
        match intent with
        | `Primary ->
          ( Colors.Background.primary
          , Colors.Text.on_filled_primary
          , Colors.Background.primary_ghost_hover )
        | `Danger ->
          ( Colors.Background.danger
          , Colors.Text.on_filled_danger
          , Colors.Background.danger_ghost_hover )
        | `Success ->
          ( Colors.Background.success
          , Colors.Text.on_filled_success
          , Colors.Background.success_ghost_hover )
        | `Warning ->
          ( Colors.Background.warning
          , Colors.Text.on_filled_warning
          , Colors.Background.warning_ghost_hover )
      in
      {%css|
        &:hover,
        &.for-testing--force-hover {
          background-color: %{hover_background#Css_gen.Color};
        }
        &:focus {
          background-color: %{background#Css_gen.Color};
          color: %{text#Css_gen.Color};
        }
      |}
    in
    let part_size size =
      Attr.many
        (match size with
         | `Xs -> Classes.[ px 0.5; rounded_xs ]
         | `Sm -> Classes.[ px 0.5; rounded_xs ]
         | `Md -> Classes.[ px 0.5; rounded_xs ]
         | `Lg -> Classes.[ px 0.5; rounded_sm ])
    in
    let part_invalid = {%css|color: %{Colors.Text.danger#Css_gen.Color};|} in
    let part_placeholder =
      {%css|color: %{Colors.Text.input_placeholder#Css_gen.Color};|}
    in
    Attr.many
      [ part_base
      ; part_size size
      ; (if disabled then Attr.empty else part_color intent)
      ; (if is_valid then Attr.empty else part_invalid)
      ; (if is_placeholder then part_placeholder else Attr.empty)
      ]
  ;;

  let clock_icon ~disabled ~size ~intent =
    let clock_icon_base =
      Attr.many
        [ {%css|
            color: %{Colors.Text.secondary#Css_gen.Color};
            display: inline-flex;
            align-self: center;
            cursor: pointer;
            margin-left: auto;
            &:focus-visible,
            &.for-testing--force-focus-visible {
              outline-style: solid;
              outline-width: 2px;
              outline-offset: -2px;
            }
          |}
        ]
    in
    let clock_icon_colors (intent : Skyline_field_v2.Intent.t) =
      Attr.many
        (match intent with
         | `Primary -> Classes.[ bg_primary_ghost_hover; outline_primary_focus_visible ]
         | `Danger -> Classes.[ bg_danger_ghost_hover; outline_danger_focus_visible ]
         | `Success -> Classes.[ bg_success_ghost_hover; outline_success_focus_visible ]
         | `Warning -> Classes.[ bg_warning_ghost_hover; outline_warning_focus_visible ])
    in
    let clock_icon_size size =
      Attr.many
        (match size with
         | `Xs -> Classes.[ p 0.5; rounded_xs ]
         | `Sm -> Classes.[ p 0.75; rounded_xs ]
         | `Md -> Classes.[ p 0.75; rounded_xs ]
         | `Lg -> Classes.[ p 0.75; rounded_sm ])
    in
    Attr.many
      [ clock_icon_base
      ; (if disabled then Attr.empty else clock_icon_colors intent)
      ; clock_icon_size size
      ; (if disabled then {%css|cursor: default;|} else Attr.empty)
      ]
  ;;
end

let set_spinbutton (sb : Segmented_input.Segment_spinbutton.t) v =
  sb.apply_action (Segmented_input.Segment_state.Action.Set_value (fun _ -> v))
;;

let open_native_picker ~id =
  Effect.of_thunk (fun () ->
    let open Js_of_ocaml in
    let element =
      let%bind.Option window = Browser_expert.Global.window () in
      let%bind.Option hidden_input =
        window##.document##getElementById ~elementId:(Js.string id) |> Js.Opt.to_option
      in
      Browser_expert.coerce ~to_:window##._HTMLInputElement_t hidden_input
    in
    Option.iter element ~f:(fun element -> element##showPicker))
;;

let view_with_error
  ?test_selector
  ?(attrs = [])
  ?(size = `Md)
  ?(intent = `Primary)
  ?(disabled = false)
  ~(hh : Segmented_input.Segment_spinbutton.t)
  ~(mm : Segmented_input.Segment_spinbutton.t)
  ~(ss : Segmented_input.Segment_spinbutton.t option)
  ~id
  ~(value : Time_ns.Ofday.t option)
  ()
  =
  let clock_icon =
    {%html|<Bonsai_web_icon.view ~size:%{`Em 1} ~icon:%{Lucide.clock} />|}
  in
  let part_style ~max (spinbutton : Segmented_input.Segment_spinbutton.t) =
    let is_valid =
      match spinbutton.state.value with
      | None -> true
      | Some v ->
        let (_ : string), error = validate_numeric_range ~max v in
        Option.is_none error
    in
    let is_placeholder = Option.is_none spinbutton.state.value in
    Style.part ~disabled ~is_valid ~is_placeholder size intent
  in
  let hidden_input =
    let extra_attrs =
      [ {%css|
          visibility: hidden;
          padding: 0;
          margin: 0;
          border: none;
          height: 0;
          width: 0;
          user-select: none;
          /* High-DPI screenshot test fix: Reverting font metrics forces this hidden
          input to use system defaults. By default, <input> doesn't inherit these
          properties but some of our entrypoints override this behavior and then we get
          font metrics leaking into the shadow DOM. We disable that here.

          The problem is probably that because this input has zero width/height,
          inheriting font metrics causes Chrome to cache glyphs at compressed subpixel
          offsets, polluting the global cache and microscopically shifting the rendering
          of nearby visible text.

          There's no single cr-bug about this, but it appears the Chrome team just
          straight up disables subpixel hinting in their own integration tests:
          https://issues.chromium.org/issues/339041663#comment8
          Likely because subpixel rendering is so susceptible to cache pollution bugs
          like this.
          */
          font-family: revert;
          font-size: revert;
          line-height: revert;
        |}
      ; Attr.id id
      ; Attr.tabindex (-1)
      ]
    in
    let set_all_spinbuttons new_value =
      match new_value with
      | None ->
        let%bind.Effect (_ : string option) = set_spinbutton hh None in
        let%bind.Effect (_ : string option) = set_spinbutton mm None in
        let%bind.Effect (_ : string option) =
          match ss with
          | None -> Effect.return None
          | Some ss -> set_spinbutton ss None
        in
        Effect.Ignore
      | Some time ->
        let { Time_ns.Span.Parts.hr; min; sec; _ } = Time_ns.Ofday.to_parts time in
        let%bind.Effect (_ : string option) =
          set_spinbutton hh (Some (Int.to_string hr))
        in
        let%bind.Effect (_ : string option) =
          set_spinbutton mm (Some (Int.to_string min))
        in
        let%bind.Effect (_ : string option) =
          match ss with
          | None -> Effect.return None
          | Some ss -> set_spinbutton ss (Some (Int.to_string sec))
        in
        Effect.Ignore
    in
    let value_string =
      Option.value_map value ~default:"" ~f:Time_ns.Ofday.to_millisecond_string
    in
    let on_input =
      Attr.on_input (fun _event input_value ->
        let time =
          if String.is_empty input_value
          then None
          else Option.try_with (fun () -> Time_ns.Ofday.of_string input_value)
        in
        set_all_spinbuttons time)
    in
    {%html|
      <input
        type="time"
        *{extra_attrs}
        %{Attr.value_prop value_string}
        %{on_input}
        ?{if disabled then Some Attr.disabled else None}
      />
    |}
  in
  let on_activate = open_native_picker ~id in
  let maybe_disabled_style =
    if disabled
    then
      {%css|
        cursor: auto;
        pointer-events: none;
      |}
    else Attr.empty
  in
  let is_segment_valid ~max (spinbutton : Segmented_input.Segment_spinbutton.t) =
    match spinbutton.state.value with
    | None -> true
    | Some v ->
      let (_ : string), error = validate_numeric_range ~max v in
      Option.is_none error
  in
  let on_click_prevent_default =
    Attr.on_click (fun event ->
      event##preventDefault;
      Effect.Ignore)
  in
  let ss_segments =
    match ss with
    | None -> []
    | Some ss ->
      [ Segmented_input.Content.delimiter ~char:':' ()
      ; Segmented_input.Content.segment ~attrs:[ part_style ~max:59 ss ] ~segment:ss ()
      ]
  in
  let view =
    Segmented_input.view
      ?test_selector
      ~attrs:
        [ Classes.data_skyline_component "time-input"
        ; maybe_disabled_style
        ; Style.container ~disabled ~size ~intent
        ; Attr.many attrs
        ; on_click_prevent_default
        ]
      ~disabled
      ([ Segmented_input.Content.segment ~attrs:[ part_style ~max:23 hh ] ~segment:hh ()
       ; Segmented_input.Content.delimiter ~char:':' ()
       ; Segmented_input.Content.segment ~attrs:[ part_style ~max:59 mm ] ~segment:mm ()
       ]
       @ ss_segments
       @ [ Segmented_input.Content.action_element
             ~on_activate
             ~attrs:[ Style.clock_icon ~disabled ~size ~intent ]
             [ clock_icon ]
         ; Segmented_input.Content.vdom [ hidden_input ]
         ])
  in
  let error =
    let invalid_parts =
      List.filter_opt
        [ (if not (is_segment_valid ~max:23 hh) then Some "hours" else None)
        ; (if not (is_segment_valid ~max:59 mm) then Some "minutes" else None)
        ; (match ss with
           | Some ss when not (is_segment_valid ~max:59 ss) -> Some "seconds"
           | _ -> None)
        ]
    in
    match invalid_parts with
    | [] -> Ok ()
    | parts -> Or_error.error_s [%message "Invalid time" (parts : string list)]
  in
  view, error
;;

let create_spinbuttons (type s) (format : s Format.gadt) (local_ graph) : s Bonsai.t =
  match format with
  | HH_MM ->
    let hh = Segmented_input.Segment_spinbutton.create hh_config graph in
    let mm = Segmented_input.Segment_spinbutton.create mm_config graph in
    let%arr hh and mm in
    ~hh, ~mm
  | HH_MM_SS ->
    let hh = Segmented_input.Segment_spinbutton.create hh_config graph in
    let mm = Segmented_input.Segment_spinbutton.create mm_config graph in
    let ss = Segmented_input.Segment_spinbutton.create ss_config graph in
    let%arr hh and mm and ss in
    ~hh, ~mm, ~ss
;;

let parse_time (type s) (format : s Format.gadt) (spinbuttons : s)
  : Time_ns.Ofday.t option
  =
  let parse_raw ~hh_raw ~mm_raw ~ss_raw =
    let hh = zero_pad ~width:2 hh_raw in
    let mm = zero_pad ~width:2 mm_raw in
    let ss = zero_pad ~width:2 ss_raw in
    try Some (Time_ns.Ofday.of_string [%string "%{hh}:%{mm}:%{ss}"]) with
    | _ -> None
  in
  match format with
  | HH_MM ->
    let ~hh, ~mm = spinbuttons in
    (match hh.state.value, mm.state.value with
     | Some hh_raw, Some mm_raw -> parse_raw ~hh_raw ~mm_raw ~ss_raw:"0"
     | _ -> None)
  | HH_MM_SS ->
    let ~hh, ~mm, ~ss = spinbuttons in
    (match hh.state.value, mm.state.value, ss.state.value with
     | Some hh_raw, Some mm_raw, Some ss_raw -> parse_raw ~hh_raw ~mm_raw ~ss_raw
     | _ -> None)
;;

let unparse_time
  (type s)
  (format : s Format.gadt)
  (spinbuttons : s)
  (value : Time_ns.Ofday.t option)
  : unit Effect.t
  =
  let set_hh_mm ~hh ~mm ~hr ~min =
    let%bind.Effect (_ : string option) = set_spinbutton hh (Some (Int.to_string hr)) in
    let%bind.Effect (_ : string option) = set_spinbutton mm (Some (Int.to_string min)) in
    Effect.Ignore
  in
  let clear_hh_mm ~hh ~mm =
    let%bind.Effect (_ : string option) = set_spinbutton hh None in
    let%bind.Effect (_ : string option) = set_spinbutton mm None in
    Effect.Ignore
  in
  match format with
  | HH_MM ->
    let ~hh, ~mm = spinbuttons in
    (match value with
     | None -> clear_hh_mm ~hh ~mm
     | Some time ->
       let { Time_ns.Span.Parts.hr; min; _ } = Time_ns.Ofday.to_parts time in
       set_hh_mm ~hh ~mm ~hr ~min)
  | HH_MM_SS ->
    let ~hh, ~mm, ~ss = spinbuttons in
    (match value with
     | None ->
       let%bind.Effect () = clear_hh_mm ~hh ~mm in
       let%bind.Effect (_ : string option) = set_spinbutton ss None in
       Effect.Ignore
     | Some time ->
       let { Time_ns.Span.Parts.hr; min; sec; _ } = Time_ns.Ofday.to_parts time in
       let%bind.Effect () = set_hh_mm ~hh ~mm ~hr ~min in
       let%bind.Effect (_ : string option) =
         set_spinbutton ss (Some (Int.to_string sec))
       in
       Effect.Ignore)
;;

let extract_hh_mm_ss (type s) (format : s Format.gadt) (spinbuttons : s) =
  match format with
  | HH_MM ->
    let ~hh, ~mm = spinbuttons in
    hh, mm, None
  | HH_MM_SS ->
    let ~hh, ~mm, ~ss = spinbuttons in
    hh, mm, Some ss
;;

module Controller = struct
  module State = struct
    type t = Time_ns.Ofday.t option
  end

  type t =
    | T :
        { format : 's Format.gadt
        ; segmented_state : ('s, Time_ns.Ofday.t) Segmented_input.State.t
        ; id : string
        }
        -> t

  let format (T { format; _ }) = Format.of_gadt format
  let value (T { segmented_state; _ }) = segmented_state.value

  let create_with_gadt (type s) (format : s Format.gadt) ?state (local_ graph)
    : t Bonsai.t
    =
    let spinbuttons = create_spinbuttons format graph in
    let id = Bonsai.path_id graph in
    let segmented_state =
      Segmented_input.State.create
        ~spinbuttons
        ~parse:(parse_time format)
        ~unparse:(unparse_time format)
        ~equal:[%equal: Time_ns.Ofday.t option]
        ?state
        graph
    in
    let%arr segmented_state and id in
    T { format; segmented_state; id }
  ;;

  let create ?(format = Format.HH_MM) ?state (local_ graph) =
    let (Format.T gadt) = Format.to_packed format in
    create_with_gadt gadt ?state graph
  ;;
end

let content ?test_selector ?attrs ~controller () =
  let (Controller.T { format; segmented_state; id }) = controller in
  let hh, mm, ss = extract_hh_mm_ss format segmented_state.spinbuttons in
  let value = segmented_state.value in
  Skyline_field_v2.Content.make' (fun ~size ~intent ~disabled ->
    view_with_error
      ?test_selector
      ?attrs
      ~size
      ~intent
      ~disabled
      ~hh
      ~mm
      ~ss
      ~id
      ~value
      ())
;;

module For_testing = struct
  module Segmented_input = Segmented_input
  module Segment_spinbutton = Segmented_input.Segment_spinbutton
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
