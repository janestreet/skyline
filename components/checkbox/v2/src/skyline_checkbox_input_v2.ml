open! Core
open! Private_skyline_prelude

module Style = struct
  let base =
    Attr.many
      ({%css|
         display: inline-flex;
         height: 1em;
         width: 1em;
         align-items: center;
         justify-content: center;
         cursor: pointer;
         box-sizing: border-box;
       |}
       :: Classes.[ border 1; border_solid; border_default; bg_input ])
  ;;

  let size = function
    | `Xs | `Sm -> Classes.rounded_xs
    | `Md | `Lg -> Classes.rounded_sm
  ;;

  let border_color ~base ~hover ~active =
    {%css|
      border-color: %{base#Css_gen.Color};
      @media not (prefers-reduced-motion: reduce) {
        transition: border-color 150ms ease-in-out;
        transition: box-shadow 150ms ease-in-out;
      }

      &:hover,
      &.for-testing--force-hover {
        border-color: %{hover#Css_gen.Color};
      }

      &:active,
      &.for-testing--force-active {
        border-color: %{active#Css_gen.Color};
      }
    |}
  ;;

  let focus_shadow color =
    {%css|
      @media not (prefers-reduced-motion: reduce) {
        transition: box-shadow 150ms ease-in-out;
      }
      &:focus,
      &.for-testing--force-focus-visible {
        box-shadow: 0 0 0 3px %{color#Css_gen.Color};
        outline: none;
      }
    |}
  ;;

  let color ~disabled ~filled (intent : Skyline_field_v2.Intent.t) =
    if disabled
    then Attr.many Classes.[ bg_input_disabled; text_disabled; border_none ]
    else (
      let bg =
        if filled
        then (
          match intent with
          | `Primary ->
            Attr.many Classes.[ bg_primary; bg_primary_hover; bg_primary_active ]
          | `Success ->
            Attr.many Classes.[ bg_success; bg_success_hover; bg_success_active ]
          | `Danger -> Attr.many Classes.[ bg_danger; bg_danger_hover; bg_danger_active ]
          | `Warning ->
            Attr.many Classes.[ bg_warning; bg_warning_hover; bg_warning_active ])
        else Attr.empty
      in
      let fg =
        match intent with
        | `Primary -> Classes.text_on_filled_primary
        | `Success -> Classes.text_on_filled_success
        | `Danger -> Classes.text_on_filled_danger
        | `Warning -> Classes.text_on_filled_warning
      in
      let border =
        let open Colors.Border in
        match filled with
        | true ->
          let base =
            match intent with
            | `Primary -> primary
            | `Success -> success
            | `Danger -> danger
            | `Warning -> warning
          in
          border_color ~base ~hover:default ~active:default
        | false ->
          let active =
            match intent with
            | `Primary -> primary
            | `Success -> success
            | `Danger -> danger
            | `Warning -> warning
          in
          border_color ~base:default ~hover:default_alt ~active
      in
      let shadow =
        let open Colors.Shadow in
        match intent with
        | `Primary -> focus_shadow primary
        | `Danger -> focus_shadow danger
        | `Success -> focus_shadow success
        | `Warning -> focus_shadow warning
      in
      Attr.many [ bg; fg; border; shadow ])
  ;;
end

let content ?test_selector ?(attrs = []) ?(indeterminate = false) ~state () =
  Skyline_field_v2.Content.make (fun ~size ~intent ~disabled ->
    let checked, on_change = state in
    let filled = checked || indeterminate in
    let icon =
      if indeterminate
      then
        Some
          {%html|
            <Bonsai_web_icon.view
              style="font-size: calc(1em - 2px)"
              ~size:%{`Em 1}
              ~icon:%{Lucide.minus}
            />
          |}
      else if checked
      then
        Some
          {%html|
            <Bonsai_web_icon.view
              style="font-size: calc(1em - 2px)"
              ~size:%{`Em 1}
              ~icon:%{Lucide.check}
            />
          |}
      else None
    in
    let cursor_disabled = if disabled then {%css|cursor: not-allowed;|} else Attr.empty in
    let text_size : Skyline_text_v2.Size.t =
      match size with
      | `Xs -> `Two_xs
      | `Sm -> `Xs
      | `Md -> `Sm
      | `Lg -> `Md
    in
    (* We want the root element to be a text node because:
       - the element is sized in [em] units
       - the element needs a text baseline so that it lines up well next to text labels *)
    {%html|
      <Skyline_text_v2.view *{attrs} ~size:%{text_size} ?test_selector>
        <div style="display: flex; height: 1lh; align-items: center">
          <Bonsai_web_checkbox.component
            %{Style.base}
            %{Style.size size}
            %{Style.color ~disabled ~filled intent}
            %{cursor_disabled}
            ~disabled
            ~checked
            ~indeterminate
            ~on_change
            ~ignore_clicks:%{true}
          >
            <!-- Add a hidden native checkbox input so that clicks on the wrapping <label>
               (from Skyline_field_v2.view) forward to this input and toggle the state. -->
            <input
              type="checkbox"
              %{Vdom.Attr.bool_property "checked" checked}
              %{Vdom.Attr.bool_property "indeterminate" indeterminate}
              %{if disabled then Classes.disabled else Vdom.Attr.empty}
              on_change=%{fun _event _value -> if disabled then Effect.Ignore else on_change (not checked)}
              style="display: none"
            />
            ?{icon}
          </>
        </div>
      </>
    |})
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
