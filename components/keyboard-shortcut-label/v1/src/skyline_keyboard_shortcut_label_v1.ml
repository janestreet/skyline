open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  let ( @> ) = Css_gen.( @> )

  let key_border =
    Skyline_theme_v1.ramp Skyline_theme_v1.primary (Percent.of_percentage 50.)
  ;;

  let container =
    Css_gen.box_sizing `Border_box
    @> Css_gen.height (`Px 14)
    @> Css_gen.uniform_padding (`Px 2)
    @> Css_gen.line_height (`Px 8)
    @> Css_gen.border_radius (`Px 4)
    @> Css_gen.border ~width:(`Px 1) ~style:`Solid ~color:key_border ()
    @> Css_gen.create
         ~field:"box-shadow"
         ~value:[%string "0 .5px 0 .5px %{Css_gen.Color.to_string_css key_border}"]
    @> Css_gen.color Skyline_theme_v1.background
    @> Css_gen.background_color Skyline_theme_v1.primary
    |> Vdom.Attr.style
  ;;

  let seperator =
    Css_gen.height (`Px 14)
    @> Css_gen.line_height (`Px 14)
    @> Css_gen.color
         (Skyline_theme_v1.ramp Skyline_theme_v1.primary (Percent.of_percentage 50.))
    |> Vdom.Attr.style
  ;;
end

let part label = Skyline_text_v1.span ~attrs:[ Style.container ] ~size:Small label

let component (modifier, key) =
  Skyline_flex_v1.row
    ~gap:(`Px 2)
    ~align:Center
    [ part (Skyline_keyboard_shortcut_v1.Modifier.to_string modifier)
    ; Skyline_text_v1.span ~size:Small ~attrs:[ Style.seperator ] "+"
    ; part (Skyline_keyboard_shortcut_v1.Key.to_string key)
    ]
;;
