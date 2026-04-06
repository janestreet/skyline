open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  module Colors = Private_skyline_theme.Colors.Constants

  let tooltip =
    Css_gen.(
      max_height (`Percent Percent.one_hundred_percent)
      @> uniform_padding (`Px 4)
      @> border_radius (`Px 2)
      @> border ~width:(`Px 1) ~color:Colors.border ~style:`Solid ()
      @> color Colors.primary
      @> background_color Colors.surface
      @> Private_skyline_theme.Shadows.raised_card
      @> overflow_x `Hidden
      @> overflow_y `Auto)
    |> Vdom.Attr.style
    |> Vdom.Attr.combine Private_skyline_theme.Stylesheet.step_nested_surface_ramp
  ;;

  let text = Css_gen.(max_width (`Px 400)) |> Vdom.Attr.style
end

module Position = struct
  type t = Bonsai_web_toplayer.Position.t =
    | Auto
    | Top
    | Bottom
    | Left
    | Right
  [@@deriving sexp_of, equal]
end

module Alignment = struct
  type t = Bonsai_web_toplayer.Alignment.t =
    | Center
    | Start
    | End
  [@@deriving sexp_of, equal]
end

let component
  ?(position = Position.Top)
  ?(alignment = Alignment.Center)
  ?(interactive = false)
  contents
  =
  Bonsai_web_toplayer.tooltip
    ~offset:{ main_axis = 4.; cross_axis = 0. }
    ~tooltip_attrs:[ Style.tooltip ]
    ~light_dismiss:false
    ~position
    ~alignment
    ~hoverable_inside:interactive
    ?hide_grace_period:(if interactive then Some (Time_ns.Span.of_sec 0.1) else None)
    (Skyline_flex_v1.column [ contents ])
;;

let text ?intent ?position ?alignment ?size contents =
  let contents = Skyline_text_v1.span ~attrs:[ Style.text ] ?intent ?size contents in
  component ?position ?alignment contents
;;
