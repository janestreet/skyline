open! Core
open! Bonsai_web
open Private_skyline_theme

let toplayer_constants =
  { View.Constants.Toplayer.tooltips_have_arrows = `No
  ; tooltip_offset_px = 4.
  ; tooltip_show_delay = Time_ns.Span.of_ms 0.
  ; tooltip_hide_grace_period = Time_ns.Span.of_ms 0.
  ; hoverable_tooltip_hide_grace_period = Time_ns.Span.of_ms 100.
  ; popover_default_offset_px = 4.
  ; popover_with_arrow_default_offset_px = 12.
  ; popover_with_arrow_default_arrow_length_px = 8.
  }
;;

let constants ~is_dark =
  let c ~fg ~bg = { View.Constants.Fg_bg.foreground = fg; background = bg } in
  let primary = c ~fg:Colors.Constants.primary ~bg:Colors.Constants.background in
  let extreme = c ~fg:Colors.Constants.primary ~bg:Colors.Constants.surface in
  let extreme_primary_border = Colors.Constants.border in
  { View.Constants.primary
  ; extreme
  ; extreme_primary_border
  ; intent =
      { info = c ~fg:primary.background ~bg:Colors.Constants.accent
      ; success = c ~fg:primary.background ~bg:Colors.Constants.success
      ; warning = c ~fg:primary.background ~bg:Colors.Constants.warning
      ; error = c ~fg:primary.background ~bg:Colors.Constants.error
      }
  ; table =
      { body_row_even = c ~bg:Colors.Constants.surface ~fg:primary.foreground
      ; body_row_odd = primary
      ; body_row_focused = c ~fg:primary.foreground ~bg:Colors.Constants.accent
      ; body_cell_focused = c ~fg:primary.foreground ~bg:Colors.Constants.accent
      ; header_row = c ~bg:Colors.Constants.background ~fg:primary.foreground
      ; header_header_border = extreme_primary_border
      ; header_body_border = extreme_primary_border
      ; body_body_border = extreme_primary_border
      ; body_row_focused_border = extreme_primary_border
      }
  ; small_font_size = Typography.small_font_size
  ; large_font_size = Typography.extra_large_font_size
  ; form =
      { error_message = c ~fg:Colors.Constants.error ~bg:Colors.Constants.background
      ; error_toggle_text = Colors.Constants.primary
      ; error_border = Colors.Constants.error
      ; tooltip_message = c ~fg:Colors.Constants.primary ~bg:Colors.Constants.surface
      ; tooltip_toggle_text = Colors.Constants.primary
      ; tooltip_border = Colors.Constants.border
      }
  ; is_dark
  ; toplayer = toplayer_constants
  }
;;

let theme style =
  let is_dark =
    match (style : Style.t) with
    | Dark -> true
    | Light -> false
    | Vscode { is_dark } -> is_dark
  in
  View.Expert.override_theme View.Expert.default_theme ~f:(fun (module M) ->
    (module struct
      class c =
        object
          inherit M.c as super
          method! theme_name = "skyline"
          method! constants : View.Constants.t = constants ~is_dark

          method! app_attr =
            lazy (if is_dark then View.Expert.set_dark_class_on_html else Vdom.Attr.empty)

          method! themed_text ~attrs ~intent ~style ~size text =
            Skyline_text_v1.span
              ~attrs
              ?intent:
                (match intent with
                 | None -> None
                 | Some Info -> Some Skyline_theme_v1.accent
                 | Some Success -> Some Skyline_theme_v1.success
                 | Some Warning -> Some Skyline_theme_v1.warning
                 | Some Error -> Some Skyline_theme_v1.error)
              ?size:
                (match size with
                 | None -> None
                 | Some Small -> Some Small
                 | Some Regular -> Some Regular
                 | Some Large -> Some Large)
              ~style:
                (match style with
                 | None | Some Regular | Some Underlined -> Regular
                 | Some Bold -> Bold
                 | Some Italic -> Italic)
              ~decoration:
                (match style with
                 | None | Some Regular | Some Bold | Some Italic -> None
                 | Some Underlined -> Underline)
              text

          method! tooltip ~container_attrs =
            let container_attrs =
              Vdom.Attr.style (Css_gen.text_decoration ~line:[ `None ] ())
              :: container_attrs
            in
            super#tooltip ~container_attrs

          method! button = Button.make
          method! use_intent_fg_or_bg_for_highlighting = `Bg
          method! codemirror_theme = Some (if is_dark then Vscode_dark else Vscode_light)

          method! toplayer_popover_styles =
            let popover_styles =
              Css_gen.(
                max_height (`Percent Percent.one_hundred_percent)
                @> uniform_padding (`Px 4)
                @> border_radius (`Px 4)
                @> border
                     ~width:(`Px 1)
                     ~style:`Solid
                     ~color:Private_skyline_theme.Colors.Constants.border
                     ()
                @> background_color Private_skyline_theme.Colors.Constants.surface
                @> overflow_x `Hidden
                @> overflow_y `Auto)
            in
            Vdom.Attr.many
              [ Vdom.Attr.style popover_styles
              ; Vdom.Attr.style Private_skyline_theme.Shadows.floating_card
              ; Private_skyline_theme.Stylesheet.step_nested_surface_ramp
              ]
        end
    end))
;;
