open! Core
open! Private_skyline_prelude
module Date_input = Bonsai_web_contrib_date_input_yyyy_mm_dd

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
        font-family: monospace;
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

let view_with_error
  ?test_selector
  ?(attrs = [])
  ?(size = `Md)
  ?(intent = `Primary)
  ?(disabled = false)
  ~(state : Date_input.State.t)
  ()
  =
  let { Date_input.State.yyyy_part_valid
      ; mm_part_valid
      ; dd_part_valid
      ; yyyy_part
      ; mm_part
      ; dd_part
      ; _
      }
    =
    state
  in
  let calendar_icon =
    {%html.jsx|<Bonsai_web_icon.view ~size:%{`Em 1} ~icon:%{Lucide.calendar} />|}
  in
  let part_attrs field =
    let is_valid, is_placeholder, date_part, label =
      match field with
      | `YYYY -> yyyy_part_valid, Option.is_none yyyy_part.value, yyyy_part, "year"
      | `MM -> mm_part_valid, Option.is_none mm_part.value, mm_part, "month"
      | `DD -> dd_part_valid, Option.is_none dd_part.value, dd_part, "day"
    in
    let aria_valuenow =
      match date_part.value with
      | Some v -> Attr.create "aria-valuenow" v
      | None -> Attr.empty
    in
    Attr.many
      [ Style.part ~disabled ~is_valid ~is_placeholder size intent
      ; Attr.role "spinbutton"
      ; Attr.create "aria-label" label
      ; Attr.create "aria-valuemin" "1"
      ; Attr.create "aria-valuemax" (Int.to_string date_part.max_value)
      ; aria_valuenow
      ]
  in
  let date_input_attrs =
    [ Attr.many attrs
    ; Style.container ~disabled ~size ~intent
    ; (* Prevent the wrapping <label> (from Skyline_field_v2.view) from forwarding clicks
         to the hidden focus target. Without this, clicking on any date part (e.g. mm)
         would be overridden by the label activating the hidden input and redirecting
         focus to yyyy. Mouse focus already happens on mousedown (before click), so
         preventing default on click only suppresses the label forwarding without
         affecting normal focus behavior. *)
      Attr.on_click (fun event ->
        event##preventDefault;
        Effect.Ignore)
    ]
  in
  let date_input_view =
    let maybe_disabled_style =
      if disabled
      then
        {%css|
          cursor: auto;
          pointer-events: none;
        |}
      else Attr.empty
    in
    {%html.jsx|
      <Date_input.view
        ?test_selector
        %{Classes.data_skyline_component "date-input"}
        *{date_input_attrs}
        ~disabled
        %{maybe_disabled_style}
        ~state:%{state}
      >
        <Date_input.yyyy_part %{part_attrs `YYYY} />
        <Date_input.delimiter
          style="display: inline-block; color: %{Colors.Text.secondary#Css_gen.Color}"
        />
        <Date_input.mm_part %{part_attrs `MM} />
        <Date_input.delimiter
          style="display: inline-block; color: %{Colors.Text.secondary#Css_gen.Color}"
        />
        <Date_input.dd_part %{part_attrs `DD} />
        <Date_input.calendar_icon %{Style.calendar_icon ~disabled ~size ~intent}>
          %{calendar_icon}
        </>
      </>
    |}
  in
  let error =
    let invalid_parts =
      List.filter_opt
        [ (if not yyyy_part_valid then Some "year" else None)
        ; (if not mm_part_valid then Some "month" else None)
        ; (if not dd_part_valid then Some "day" else None)
        ]
    in
    match invalid_parts with
    | [] -> Ok ()
    | parts -> Or_error.error_s [%message "Invalid date" (parts : string list)]
  in
  date_input_view, error
;;

module State = struct
  type t = Date_input.State.t

  let create = Date_input.State.create
end

let content ?test_selector ?attrs ~state () =
  Skyline_field_v2.Content.make' (fun ~size ~intent ~disabled ->
    view_with_error ?test_selector ?attrs ~size ~intent ~disabled ~state ())
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
