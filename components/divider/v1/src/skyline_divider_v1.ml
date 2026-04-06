open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  let ( @> ) = Css_gen.( @> )

  let horizontal ~width =
    Css_gen.box_sizing `Border_box
    @> Css_gen.width width
    @> Css_gen.height (`Px 1)
    @> Css_gen.uniform_margin (`Px 0)
    @> Css_gen.uniform_padding (`Px 0)
    @> Css_gen.border ~width:(`Px 0) ~style:`Solid ()
    @> Css_gen.border_top ~width:(`Px 1) ~style:`Solid ()
    @> Css_gen.color Skyline_theme_v1.border
    |> Vdom.Attr.style
  ;;

  let vertical ~height =
    Css_gen.box_sizing `Border_box
    @> Css_gen.width (`Px 1)
    @> Css_gen.height height
    @> Css_gen.uniform_margin (`Px 0)
    @> Css_gen.uniform_padding (`Px 0)
    @> Css_gen.border ~width:(`Px 0) ~style:`Solid ()
    @> Css_gen.border_left ~width:(`Px 1) ~style:`Solid ()
    @> Css_gen.color Skyline_theme_v1.border
    |> Vdom.Attr.style
  ;;

  let symbol ~line_height =
    Css_gen.color
      (Skyline_theme_v1.ramp Skyline_theme_v1.primary (Percent.of_percentage 50.))
    @> Css_gen.line_height line_height
    @> Css_gen.user_select `None
    |> Vdom.Attr.style
  ;;
end

let horizontal ?(length = `Percent Percent.one_hundred_percent) () =
  Vdom.Node.hr ~attrs:[ Style.horizontal ~width:length ] ()
;;

let vertical ?(length = `Percent Percent.one_hundred_percent) () =
  Vdom.Node.hr ~attrs:[ Style.vertical ~height:length ] ()
;;

let interpunct =
  Vdom.Node.span
    ~attrs:
      [ Style.symbol
        (* Set small line height so that the interpunct is centered correctly e.g. when in
           a flex container with [Small] text. *)
          ~line_height:(`Px 4)
      ]
    [ Vdom.Node.text "\u{00B7}" ]
;;

let slash =
  Vdom.Node.span ~attrs:[ Style.symbol ~line_height:(`Em 1) ] [ Vdom.Node.text "/" ]
;;
