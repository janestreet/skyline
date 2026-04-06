open! Core
open! Private_skyline_prelude

module Style = struct
  let base =
    Attr.many
      ({%css|
         /* Reset native radio appearance */
         appearance: none;

         /* Custom styling */
         display: inline-flex;
         height: 1em;
         width: 1em;
         align-items: center;
         justify-content: center;
         cursor: pointer;
         box-sizing: border-box;
       |}
       :: Classes.[ border 1; border_solid; border_default; bg_input; rounded_full ])
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

  let color ~disabled ~checked (intent : Skyline_field_v2.Intent.t) =
    if disabled
    then Attr.many Classes.[ bg_input_disabled; text_disabled; border_none ]
    else (
      let bg =
        if checked
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
      let border =
        let open Colors.Border in
        match checked with
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
      Attr.many [ bg; border; shadow ])
  ;;

  (* Styling the inner circle when checked *)
  let checked_indicator ~disabled =
    let color =
      if disabled then Colors.Text.disabled else (Palette.white :> Css_gen.Color.t)
    in
    {%css|
      color: %{color#Css_gen.Color};
      position: relative;
      &::after {
        content: "";
        position: absolute;
        top: 50%;
        left: 50%;
        width: 0.5em;
        height: 0.5em;
        border-radius: 50%;
        background-color: currentColor;
        opacity: 0;
      }
      &:checked::after {
        opacity: 1;
        transform: translate(-50%, -50%) scale(1);
      }
    |}
  ;;
end

let content ?test_selector ?(attrs = []) ~group ~state () =
  Skyline_field_v2.Content.make (fun ~size ~intent ~disabled ->
    let checked, on_change = state in
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
          <input
            type="radio"
            name=%{group}
            on_change=%{fun _ _ -> on_change}
            %{Style.base}
            %{Style.color ~disabled ~checked intent}
            %{Style.checked_indicator ~disabled}
            %{cursor_disabled}
            %{Vdom.Attr.bool_property "checked" checked}
            %{if disabled then Attr.disabled else Attr.empty}
          />
        </div>
      </>
    |})
;;

module For_docs = struct
  let ml_filepath = __FILE__
end
