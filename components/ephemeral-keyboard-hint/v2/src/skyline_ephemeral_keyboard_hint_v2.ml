open! Core
open! Private_skyline_prelude

module Position = struct
  type t =
    | Bottom
    | Top
    | Left
    | Right
  [@@deriving sexp_of, enumerate, to_string ~capitalize:"kebab-case"]
end

let data_attr_name = "data-skyline-kb-hint"
let data_position_attr_name = "data-skyline-kb-hint-position"

module Style = struct
  let bg_color =
    Css_gen.Color.light_dark
      (Palette.black :> Css_gen.Color.t)
      (Colors.Background.secondary_alt :> Css_gen.Color.t)
  ;;

  let border_color =
    Css_gen.Color.light_dark
      (Colors.transparent :> Css_gen.Color.t)
      (Colors.Border.default :> Css_gen.Color.t)
  ;;

  (* Uses CSS custom properties so that nested keyboard shortcut boundaries compose
     correctly - a child boundary's hint state overrides its parent's in the cascade.

     NOTE: we can't use regular ppx_css here, because we need to interpolate into
     selectors. However, the perf impact should be very small here. *)
  let hint_css =
    let active_selector = Bonsai_web_keyboard_shortcut.Hint_status.active_selector in
    let inactive_selector = Bonsai_web_keyboard_shortcut.Hint_status.inactive_selector in
    let bg_color = Css_gen.Color.to_string_css bg_color in
    let text_color = Css_gen.Color.to_string_css (Palette.white :> Css_gen.Color.t) in
    let border_color = Css_gen.Color.to_string_css border_color in
    let font_size = Css_gen.Length.to_string_css Font.size_2xs in
    let line_height = Css_gen.Length.to_string_css Font.line_height_xs in
    let font_weight = Font.Weight.to_string_css Font.Weight.normal in
    let padding_x = Css_gen.Length.to_string_css (Skyline_tokens_v2.spacing 1.) in
    let padding_y = Css_gen.Length.to_string_css (Skyline_tokens_v2.spacing 0.5) in
    let gap = Css_gen.Length.to_string_css (Skyline_tokens_v2.spacing 1.) in
    let font_family = Font.Family.to_string_css Font.Family.monospace in
    Inline_css.Private.Dynamic.attr
      [%string
        {|
        %{active_selector} {
          --skyline-kb-hint-visibility: visible;
        }

        %{inactive_selector} {
          --skyline-kb-hint-visibility: hidden;
        }

        [%{data_attr_name}]::after {
          content: attr(%{data_attr_name});
          visibility: var(--skyline-kb-hint-visibility, hidden);

          position: absolute;
          z-index: 1;
          pointer-events: none;
          white-space: nowrap;

          display: inline-flex;
          justify-content: center;
          align-items: center;
          gap: %{gap};

          background-color: %{bg_color};
          color: %{text_color};
          border: 1px solid %{border_color};
          font-size: %{font_size};
          line-height: %{line_height};
          font-family: %{font_family};
          font-weight: %{font_weight};
          padding: %{padding_y} %{padding_x};
          border-radius: 2px;
        }

        [%{data_position_attr_name}=%{Position.to_string Position.Bottom}]::after {
          bottom: 0;
          left: 50%;
          transform: translate(-50%, 75%);
        }

        [%{data_position_attr_name}=%{Position.to_string Position.Top}]::after {
          top: 0;
          left: 50%;
          transform: translate(-50%, -75%);
        }

        [%{data_position_attr_name}=%{Position.to_string Position.Left}]::after {
          top: 50%;
          left: 0;
          transform: translate(-75%, -50%);
        }

        [%{data_position_attr_name}=%{Position.to_string Position.Right}]::after {
          top: 50%;
          right: 0;
          transform: translate(75%, -50%);
        }

        /* It is a little unusual to use transition on [visibility]. We do this
           since transition cannot be used on the [display] property, and
           transition creates an easy way to create a delay. The syntax is
           `<property> <duration> <delay>`. */
        @media not (prefers-reduced-motion: reduce) {
          %{active_selector} [%{data_attr_name}]::after {
            transition: visibility 0s 200ms;
          }
        }
      |}]
  ;;
end

let attr' ?(position = Position.Bottom) keystroke =
  let label =
    Vdom_keyboard.Keystroke.to_string_hum ~capitalize_letter_keys:true keystroke
  in
  Attr.many
    [ Attr.create data_attr_name label
    ; Attr.create data_position_attr_name (Position.to_string position)
    ; Style.hint_css
    ; Classes.data_skyline_component "ephemeral-keyboard-hint"
    ]
;;

let attr ?(position = Position.Bottom) keystroke =
  let hint_attr = attr' ~position keystroke in
  let register ?prevent_default ~effect (local_ graph) =
    Bonsai_web_keyboard_shortcut.register
      ?prevent_default
      ~effect
      (Bonsai.return keystroke)
      graph
  in
  hint_attr, register
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
