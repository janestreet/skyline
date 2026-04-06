open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  let chip ~border_color =
    Css_gen.(
      Css_gen.box_sizing `Border_box
      @> height (`Px 16)
      @> width (`Raw "max-content")
      @> Css_gen.uniform_margin (`Px 0)
      @> padding ~top:(`Px 0) ~right:(`Px 4) ~bottom:(`Px 0) ~left:(`Px 4) ()
      @> border ~width:(`Px 1) ~style:`Solid ~color:border_color ()
      @> border_radius (`Px 2)
      @> white_space `Nowrap)
    |> Vdom.Attr.style
  ;;

  let secondary ~border_color =
    Css_gen.border ~width:(`Px 1) ~style:`Dashed ~color:border_color () |> Vdom.Attr.style
  ;;
end

let component ?(secondary = false) ?intent label =
  let border_color =
    match intent with
    | None ->
      if secondary
      then Skyline_theme_v1.fade Skyline_theme_v1.primary (Percent.of_percentage 40.)
      else Skyline_theme_v1.border
    | Some intent -> intent
  in
  Skyline_flex_v1.row
    ~align:Center
    ~attrs:
      [ Style.chip ~border_color
      ; (if secondary then Style.secondary ~border_color else Vdom.Attr.empty)
      ]
    [ Skyline_text_v1.span ?intent ~secondary ~size:Small label ]
;;
