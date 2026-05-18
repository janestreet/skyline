open! Core
open! Private_skyline_prelude

module Style = struct
  let base =
    Classes.
      [ w_full
      ; text_default
      ; border 1
      ; border_solid
      ; border_default
      ; bg_input
      ; {%css|
          outline: none;

          &.for-testing--force-focus-visible,
          &:focus {
            background-color: %{Colors.Background.input_active#Css_gen.Color};
          }

          &::placeholder {
            color: %{Css_gen.Color.to_string_css Colors.Text.input_placeholder};
          }
        |}
      ]
  ;;

  let size = function
    | `Xs -> Classes.[ text_xs; px 0.5; rounded_xs ]
    | `Sm -> Classes.[ text_sm; px 1.; rounded_xs ]
    | `Md -> Classes.[ text_base; px 2.; py 1.; rounded_sm ]
    | `Lg -> Classes.[ text_lg; px 2.; py 2.; rounded_md ]
  ;;

  let border_color ~disabled intent =
    if disabled
    then Classes.border_default
    else (
      match intent with
      | `Primary -> Classes.border_default
      | `Danger -> Classes.border_danger
      | `Success -> Classes.border_success
      | `Warning -> Classes.border_warning)
  ;;

  let focus_color (intent : Skyline_field_v2.Intent.t) =
    let border, shadow =
      match intent with
      | `Primary -> Colors.Border.primary, Colors.Shadow.primary
      | `Danger -> Colors.Border.danger, Colors.Shadow.danger
      | `Success -> Colors.Border.success, Colors.Shadow.success
      | `Warning -> Colors.Border.warning, Colors.Shadow.warning
    in
    Attr.many
      [ {%css|
          @media not (prefers-reduced-motion: reduce) {
            transition: box-shadow 150ms ease-in-out;
          }
          &.for-testing--force-focus-visible,
          &:focus {
            border-color: %{border#Css_gen.Color};
            box-shadow: 0 0 0 3px %{shadow#Css_gen.Color};
          }
        |}
      ]
  ;;

  let disabled = Attr.many Classes.[ bg_input_disabled; text_input_placeholder ]
end

let content
  ?test_selector
  ?(attrs = [])
  ?placeholder
  ?(rows = 2)
  ?(resizable = false)
  ~state
  ()
  =
  Skyline_field_v2.Content.make (fun ~size ~intent ~disabled ->
    let value, set_value = state in
    let input_attrs =
      [ Attr.many Style.base
      ; Attr.many (Style.size size)
      ; Style.border_color ~disabled intent
      ; Style.focus_color intent
      ; (if disabled then Style.disabled else Attr.empty)
      ; Test_selector.attr_of_opt test_selector
      ; Attr.many attrs
      ; Attr.rows rows
      ; (if resizable then Attr.empty else {%css|resize: none;|})
      ]
    in
    let placeholder =
      match placeholder with
      | None -> Attr.empty
      | Some placeholder -> Attr.placeholder placeholder
    in
    let maybe_disabled_attr = if disabled then Classes.disabled else Attr.empty in
    {%html.jsx|
      <textarea
        %{Attr.value_prop value}
        *{input_attrs}
        %{placeholder}
        %{maybe_disabled_attr}
        on_input=%{fun _ new_value -> set_value new_value}
      ></textarea>
    |})
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
