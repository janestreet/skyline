open! Core
open! Private_skyline_prelude

module Style = struct
  let base =
    {%css|
      display: flex;
      cursor: pointer;
      border-radius: 0.5em;
      width: min-content;
      height: 1em;
      padding: 2px;
      box-sizing: border-box;

      @media not (prefers-reduced-motion: reduce) {
        transition: background-color 150ms ease-in-out, border-color 150ms
          ease-in-out, box-shadow 150ms ease-in-out;
      }
    |}
  ;;

  let indicator_container =
    {%css|
      /* 2px block padding */
      font-size: calc(1em - 4px);
      height: 1em;

      border-radius: 0.5em;
      position: relative;
      aspect-ratio: 2 / 1;
    |}
  ;;

  let indicator =
    {%css|
      background-color: currentColor;
      border-radius: 50%;
      position: absolute;
      top: 0;
      bottom: 0;
      left: 0;
      aspect-ratio: 1 / 1;

      box-shadow: 0px 2px 4px -2px rgba(0, 0, 0, 0.1), 0px 4px 6px 1px
        rgba(0, 0, 0, 0.1);

      @media not (prefers-reduced-motion: reduce) {
        transition: left 150ms ease-in-out;
      }
    |}
  ;;

  let focus_shadow color =
    {%css|
      &:focus,
      &.for-testing--force-focus {
        box-shadow: 0 0 0 3px %{color#Css_gen.Color};
        outline: none;
      }
    |}
  ;;

  let color ~disabled ~filled (intent : Skyline_field_v2.Intent.t) =
    if disabled
    then Attr.many Classes.[ bg_secondary; text_disabled ]
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
        else Attr.many Classes.[ bg_secondary; bg_secondary_hover; bg_secondary_active ]
      in
      let fg =
        match intent with
        | `Primary -> Classes.text_on_filled_primary
        | `Success -> Classes.text_on_filled_success
        | `Danger -> Classes.text_on_filled_danger
        | `Warning -> Classes.text_on_filled_warning
      in
      let shadow =
        let open Colors.Shadow in
        match intent with
        | `Primary -> focus_shadow primary
        | `Danger -> focus_shadow danger
        | `Success -> focus_shadow success
        | `Warning -> focus_shadow warning
      in
      Attr.many [ bg; fg; shadow ])
  ;;
end

let content ?test_selector ?(attrs = []) ~state () =
  Skyline_field_v2.Content.make (fun ~size ~intent ~disabled ->
    let checked, on_change = state in
    let filled = checked in
    let content =
      let position =
        if filled then {%css|left: calc(100% - 1em);|} else {%css|left: 0;|}
      in
      {%html.jsx|
        <div %{Style.indicator_container}>
          <div %{Style.indicator} %{position}></div>
        </div>
      |}
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
    {%html.jsx|
      <Skyline_text_v2.view *{attrs} ~size:%{text_size} ?test_selector>
        <div style="display: flex; height: 1lh; align-items: center">
          <Bonsai_web_checkbox.component
            %{Style.base}
            %{Style.color ~disabled ~filled intent}
            %{cursor_disabled}
            ~disabled
            ~checked
            ~on_change
            ~ignore_clicks:%{true}
          >
            <!-- Add a hidden native checkbox input so that clicks on the wrapping <label>
             (from Skyline_field_v2.view) forward to this input and toggle the state. -->
            <input
              type="checkbox"
              %{if checked then Vdom.Attr.checked else Vdom.Attr.empty}
              %{if disabled then Classes.disabled else Vdom.Attr.empty}
              on_change=%{fun _event _value -> if disabled then Effect.Ignore else on_change (not checked)}
              style="display: none"
            />
            %{content}
          </>
        </div>
      </>
    |})
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
