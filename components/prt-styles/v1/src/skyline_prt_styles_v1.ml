open! Core
open! Bonsai_web
open Bonsai_web_ui_partial_render_table_styling

let style ?(padding = `Px 4) () : Bonsai_web_ui_partial_render_table_styling.t =
  create
    { colors =
        { page_bg = Skyline_theme_v1.surface
        ; page_fg = `Inherit
        ; header_bg = Skyline_theme_v1.surface
        ; header_fg = `Inherit
        ; header_cell_focused_bg = `Inherit
        ; header_cell_focused_fg = `Inherit
        ; row_even_bg = `Inherit
        ; row_even_fg = `Inherit
        ; row_odd_bg =
            Skyline_theme_v1.fade Skyline_theme_v1.primary (Percent.of_percentage 5.)
        ; row_odd_fg = `Inherit
        ; row_of_focused_cell_bg = None
        ; row_of_focused_cell_fg = None
        ; cell_focused_bg =
            Skyline_theme_v1.ramp Skyline_theme_v1.accent (Percent.of_percentage 20.)
        ; cell_focused_fg = `Inherit
        ; row_focused_bg =
            Skyline_theme_v1.ramp Skyline_theme_v1.accent (Percent.of_percentage 20.)
        ; row_focused_fg = `Inherit
        ; cell_focused_outline = Some Skyline_theme_v1.accent
        ; row_focused_border = Skyline_theme_v1.accent
        ; header_header_border = `Name "transparent"
        ; body_body_border = `Name "transparent"
        ; header_body_border = `Inherit
        }
    ; lengths =
        { body_body_border_width_x = `Px 0
        ; body_body_border_width_y = `Px 1
        ; cell_focused_outline_width = `Px 1
        ; header_cell_padding_x = padding
        ; header_cell_padding_y = padding
        ; body_cell_padding_x = padding
        ; body_cell_padding_y = padding
        }
    ; fonts =
        { header_cell_font_size = Private_skyline_theme.Typography.small_font_size
        ; body_cell_font_size = Private_skyline_theme.Typography.small_font_size
        }
    }
  |> Expert.add_attrs
       ~header_cell:
         [ {%css|
             white-space: nowrap;
             text-align: left;
           |}
         ]
       ~table:
         [ {%css|
             border: 1px solid %{Skyline_theme_v1.border#Css_gen.Color};
             border-radius: 4px;
           |}
         ; Private_skyline_theme.Stylesheet.step_nested_surface_ramp
         ]
;;
