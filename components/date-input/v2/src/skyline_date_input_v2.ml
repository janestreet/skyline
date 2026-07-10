open! Core
open! Private_skyline_prelude
module Segmented_input = Private_skyline_segmented_input

let zero_pad ~width value =
  let pad_len = max 0 (width - String.length value) in
  String.make pad_len '0' ^ value
;;

let validate_numeric_range ~max value =
  match Int.of_string_opt value with
  | None -> value, Some (Error.of_string "not a number")
  | Some n when n >= 1 && n <= max -> value, None
  | Some n -> value, Some (Error.create_s [%message "out of range" (n : int) (max : int)])
;;

module Style = struct
  (* The outermost part of this input *)
  let container ~disabled ~size ~intent =
    let container_base =
      {%css|
        /* We use border-box because that's what <input> uses */
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

  (* controls the "field selected" indicator on each of YYYY / MM / DD *)
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

  let calendar_icon ~disabled ~size ~intent =
    let calendar_icon_base =
      Attr.many
        [ {%css|
            color: %{Colors.Text.secondary#Css_gen.Color};
            display: inline-flex;
            align-self: center;
            cursor: pointer;
            margin-left: auto;
            /* Match ghost icon button focus style */
            &:focus-visible,
            &.for-testing--force-focus-visible {
              outline-style: solid;
              outline-width: 2px;
              outline-offset: -2px;
            }
          |}
        ]
    in
    let calendar_icon_colors (intent : Skyline_field_v2.Intent.t) =
      Attr.many
        (match intent with
         | `Primary -> Classes.[ bg_primary_ghost_hover; outline_primary_focus_visible ]
         | `Danger -> Classes.[ bg_danger_ghost_hover; outline_danger_focus_visible ]
         | `Success -> Classes.[ bg_success_ghost_hover; outline_success_focus_visible ]
         | `Warning -> Classes.[ bg_warning_ghost_hover; outline_warning_focus_visible ])
    in
    let calendar_icon_size size =
      Attr.many
        (match size with
         | `Xs -> Classes.[ p 0.5; rounded_xs ]
         | `Sm -> Classes.[ p 0.75; rounded_xs ]
         | `Md -> Classes.[ p 0.75; rounded_xs ]
         | `Lg -> Classes.[ p 0.75; rounded_sm ])
    in
    Attr.many
      [ calendar_icon_base
      ; (if disabled then Attr.empty else calendar_icon_colors intent)
      ; calendar_icon_size size
      ; (if disabled then {%css|cursor: default;|} else Attr.empty)
      ]
  ;;
end

let set_spinbutton (sb : Segmented_input.Segment_spinbutton.t) v =
  sb.apply_action (Segmented_input.Segment_state.Action.Set_value (fun _ -> v))
;;

type yyyy_mm_dd =
  yyyy:Segmented_input.Segment_spinbutton.t
  * mm:Segmented_input.Segment_spinbutton.t
  * dd:Segmented_input.Segment_spinbutton.t

let create_spinbuttons ~today (graph @ local) : yyyy_mm_dd Bonsai.t =
  let yyyy_config : Segmented_input.Segment_spinbutton.Config.t =
    Segmented_input.Segment_spinbutton.Config.make_numeric
      ~placeholder:"YYYY"
      ~aria_label:"year"
      ~min:1
      ~max:9999
      ~step:5
      ~default:(Date.year today)
      ()
  in
  let mm_config : Segmented_input.Segment_spinbutton.Config.t =
    Segmented_input.Segment_spinbutton.Config.make_numeric
      ~placeholder:"MM"
      ~aria_label:"month"
      ~min:1
      ~max:12
      ~step:2
      ()
  in
  let dd_config : Segmented_input.Segment_spinbutton.Config.t =
    Segmented_input.Segment_spinbutton.Config.make_numeric
      ~placeholder:"DD"
      ~aria_label:"day"
      ~min:1
      ~max:31
      ~step:7
      ()
  in
  let yyyy = Segmented_input.Segment_spinbutton.create yyyy_config graph in
  let mm = Segmented_input.Segment_spinbutton.create mm_config graph in
  let dd = Segmented_input.Segment_spinbutton.create dd_config graph in
  let%arr yyyy and mm and dd in
  ~yyyy, ~mm, ~dd
;;

let parse_date (spinbuttons : yyyy_mm_dd) : Date.t option =
  let ~yyyy, ~mm, ~dd = spinbuttons in
  match yyyy.state.value, mm.state.value, dd.state.value with
  | Some year_raw, Some month_raw, Some day_raw ->
    let year = zero_pad ~width:4 year_raw in
    let month = zero_pad ~width:2 month_raw in
    let day = zero_pad ~width:2 day_raw in
    (try Some (Date.of_string [%string "%{year}-%{month}-%{day}"]) with
     | _ -> None)
  | _ -> None
;;

let unparse_date (spinbuttons : yyyy_mm_dd) (value : Date.t option) : unit Effect.t =
  let ~yyyy, ~mm, ~dd = spinbuttons in
  match value with
  | None ->
    let%bind.Effect _ = set_spinbutton yyyy None in
    let%bind.Effect _ = set_spinbutton mm None in
    let%bind.Effect _ = set_spinbutton dd None in
    Effect.Ignore
  | Some date ->
    let%bind.Effect _ = set_spinbutton yyyy (Some (Date.year date |> Int.to_string)) in
    let%bind.Effect _ =
      set_spinbutton mm (Some (Date.month date |> Month.to_int |> Int.to_string))
    in
    let%bind.Effect _ = set_spinbutton dd (Some (Date.day date |> Int.to_string)) in
    Effect.Ignore
;;

let copy ~set_clipboard_value ~prevent_default value =
  let is_selection_empty =
    (let open Js_of_ocaml in
     let%bind.Option window = Browser_expert.Global.window () in
     let%map.Option selection = window##.document##getSelection |> Js.Opt.to_option in
     selection##.isCollapsed |> Js.to_bool)
    |> Option.value ~default:false
  in
  match is_selection_empty, value with
  | true, Some v ->
    set_clipboard_value (Date.to_string v);
    prevent_default ();
    true
  | false, _ | _, None ->
    (* If the user has directly selected some text, or if the date input is
       invalid/incomplete, fall back to the native browser copy behavior. *)
    false
;;

let cut ~disabled ~set_clipboard_value ~prevent_default value =
  if disabled
  then None
  else (
    match copy ~set_clipboard_value ~prevent_default value with
    | true -> Some None
    | false -> None)
;;

let paste ~disabled ~clipboard_value ~prevent_default =
  if disabled
  then None
  else (
    match
      Option.try_with (fun () -> clipboard_value |> String.strip |> Date.of_string)
    with
    | Some v ->
      prevent_default ();
      Some (Some v)
    | None -> None)
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

let const_ignore () = Vdom.Effect.Ignore

let view_with_error
  ?test_selector
  ?(attrs = [])
  ?(size = `Md)
  ?(intent = `Primary)
  ?(disabled = false)
  ~(yyyy : Segmented_input.Segment_spinbutton.t)
  ~(mm : Segmented_input.Segment_spinbutton.t)
  ~(dd : Segmented_input.Segment_spinbutton.t)
  ~id
  ~(value : Date.t option)
  ()
  =
  let calendar_icon =
    {%html|<Bonsai_web_icon.view ~size:%{`Em 1} ~icon:%{Lucide.calendar} />|}
  in
  let part_style ~is_valid (spinbutton : Segmented_input.Segment_spinbutton.t) =
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
    let value_string = Option.value_map value ~default:"" ~f:Date.to_string in
    let on_input =
      Attr.on_input (fun _event input_value ->
        let date =
          if String.is_empty input_value
          then None
          else Option.try_with (fun () -> Date.of_string input_value)
        in
        unparse_date (~yyyy, ~mm, ~dd) date)
    in
    {%html|
      <input
        type="date"
        *{extra_attrs}
        %{Attr.value value_string}
        %{on_input}
        ?{if disabled then Some Attr.disabled else None}
      />
    |}
  in
  let on_activate = open_native_picker ~id in
  let handle_copy (event : Js_of_ocaml.Dom_html.clipboardEvent Js_of_ocaml.Js.t) =
    Js_of_ocaml.Js.Opt.case event##.clipboardData const_ignore (fun clipboard_data ->
      let set_clipboard_value v =
        let open Js_of_ocaml in
        clipboard_data##setData (Js.string "text/plain") (Js.string v)
      in
      let prevent_default () = event##preventDefault in
      let (_ : bool) = copy ~set_clipboard_value ~prevent_default value in
      Effect.Ignore)
  in
  let handle_cut (event : Js_of_ocaml.Dom_html.clipboardEvent Js_of_ocaml.Js.t) =
    Js_of_ocaml.Js.Opt.case event##.clipboardData const_ignore (fun clipboard_data ->
      let set_clipboard_value v =
        let open Js_of_ocaml in
        clipboard_data##setData (Js.string "text/plain") (Js.string v)
      in
      let prevent_default () = event##preventDefault in
      match cut ~disabled ~set_clipboard_value ~prevent_default value with
      | Some o -> unparse_date (~yyyy, ~mm, ~dd) o
      | None -> Effect.Ignore)
  in
  let handle_paste (event : Js_of_ocaml.Dom_html.clipboardEvent Js_of_ocaml.Js.t) =
    Js_of_ocaml.Js.Opt.case event##.clipboardData const_ignore (fun clipboard_data ->
      let clipboard_value =
        let open Js_of_ocaml in
        clipboard_data##getData
          (* We use the more permissive ["text"] (rather than ["text/plain"]) in the read case *)
          (Js.string "text")
        |> Js.to_string
      in
      let prevent_default () = event##preventDefault in
      match paste ~disabled ~clipboard_value ~prevent_default with
      | Some o -> unparse_date (~yyyy, ~mm, ~dd) o
      | None -> Effect.Ignore)
  in
  let handle_keydown (event : Js_of_ocaml.Dom_html.keyboardEvent Js_of_ocaml.Js.t) =
    match
      Vdom_keyboard.Keyboard_event.(
        ( match_modifiers ~ctrl:true ~alt:false ~shift:false ~meta:false event
        , Keyboard_code.of_event event ))
    with
    | true, KeyA ->
      let open Js_of_ocaml in
      (let%bind.Option current_target = event##.currentTarget |> Js.Opt.to_option in
       let%bind.Option window = Browser_expert.Global.window () in
       let%bind.Option node =
         Browser_expert.coerce ~to_:window##._Node_t current_target
       in
       let%map.Option selection = window##.document##getSelection |> Js.Opt.to_option in
       node, selection)
      |> Option.iter ~f:(fun (node, selection) ->
        selection##selectAllChildren ~node;
        event##preventDefault;
        event##stopPropagation);
      Effect.Ignore
    | _, _ -> Effect.Ignore
  in
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
  let is_day_valid
    ~(yyyy : Segmented_input.Segment_spinbutton.t)
    ~(mm : Segmented_input.Segment_spinbutton.t)
    ~(dd : Segmented_input.Segment_spinbutton.t)
    =
    let days_in_month =
      let year =
        let%bind.Option y = yyyy.state.value in
        Int.of_string_opt y
      in
      let month =
        let%bind.Option m = mm.state.value in
        Int.of_string_opt m |> Option.bind ~f:Month.of_int
      in
      match Option.both year month with
      | Some (year, month) -> Date.days_in_month ~year ~month
      | None -> 31
    in
    is_segment_valid ~max:days_in_month dd
  in
  let year_valid = is_segment_valid ~max:9999 yyyy in
  let month_valid = is_segment_valid ~max:12 mm in
  let day_valid = is_day_valid ~yyyy ~mm ~dd in
  let view =
    {%html|
      <Segmented_input.view
        ?test_selector
        %{Classes.data_skyline_component "date-input"}
        %{maybe_disabled_style}
        %{Style.container ~disabled ~size ~intent}
        *{attrs}
        on_click=%{fun event ->
          event##preventDefault;
          Effect.Ignore}
        on_copy=%{handle_copy}
        on_cut=%{handle_cut}
        on_paste=%{handle_paste}
        on_keydown=%{handle_keydown}
        ~disabled
        ~action_element:(
          <Segmented_input.Action_element.content
            ~on_activate
            %{Style.calendar_icon ~disabled ~size ~intent}
          >
            %{calendar_icon}
          </>
        )
        ~hidden_element:(
          <Segmented_input.Hidden_element.content>
            %{hidden_input}
          </>
        )
      >
        <Segmented_input.Content.segment
          %{part_style ~is_valid:year_valid yyyy}
          ~segment:%{yyyy}
        />
        <Segmented_input.Content.delimiter ~char:%{'-'} />
        <Segmented_input.Content.segment
          %{part_style ~is_valid:month_valid mm}
          ~segment:%{mm}
        />
        <Segmented_input.Content.delimiter ~char:%{'-'} />
        <Segmented_input.Content.segment
          %{part_style ~is_valid:day_valid dd}
          ~segment:%{dd}
        />
      </>
    |}
  in
  let error =
    let invalid_parts =
      List.filter_opt
        [ (if not year_valid then Some "year" else None)
        ; (if not month_valid then Some "month" else None)
        ; (if not day_valid then Some "day" else None)
        ]
    in
    match invalid_parts with
    | [] -> Ok ()
    | parts -> Or_error.error_s [%message "Invalid date" (parts : string list)]
  in
  view, error
;;

module State = struct
  type t =
    { segmented_state : (yyyy_mm_dd, Date.t) Segmented_input.State.t
    ; id : string
    }

  let create
    ?state
    ?today_for_test:(today = Date.today ~zone:(force Timezone.local))
    (graph @ local)
    =
    let spinbuttons = create_spinbuttons ~today graph in
    let id = Bonsai.path_id graph in
    let segmented_state =
      Segmented_input.State.create
        ~spinbuttons
        ~parse:parse_date
        ~unparse:unparse_date
        ~equal:[%equal: Date.t option]
        ?state
        graph
    in
    let%arr segmented_state and id in
    { segmented_state; id }
  ;;
end

let content ?test_selector ?attrs ~state () =
  let { State.segmented_state; id } = state in
  let ~yyyy, ~mm, ~dd = segmented_state.spinbuttons in
  let value = segmented_state.value in
  Skyline_field_v2.Content.make' (fun ~size ~intent ~disabled ->
    view_with_error
      ?test_selector
      ?attrs
      ~size
      ~intent
      ~disabled
      ~yyyy
      ~mm
      ~dd
      ~id
      ~value
      ())
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end

module For_testing = struct
  let copy = copy
  let cut = cut
  let paste = paste
end
