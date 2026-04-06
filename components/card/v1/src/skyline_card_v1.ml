open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  module Colors = Private_skyline_theme.Colors.Constants

  let ( @> ) = Css_gen.( @> )

  let card ~intent ~border_radius =
    let style ~foreground ~background ~border ~border_radius =
      Css_gen.color foreground
      @> Css_gen.background_color background
      @> Css_gen.border_radius border_radius
      @> Css_gen.border ~width:(`Px 1) ~style:`Solid ~color:border ()
      |> Vdom.Attr.style
    in
    let foreground = Option.value intent ~default:Colors.primary in
    let border =
      match intent with
      | Some _ -> foreground
      | None -> Colors.border
    in
    Vdom.Attr.many
      [ style ~foreground ~background:Colors.surface ~border ~border_radius
      ; Private_skyline_theme.Stylesheet.step_nested_surface_ramp
      ]
  ;;
end

let row
  ?(attrs = [])
  ?reverse
  ?wrap
  ?justify
  ?align
  ?gap
  ?(padding = `Px 4)
  ?(border_radius = `Px 4)
  ?intent
  children
  =
  Skyline_flex_v1.row
    ~attrs:(Style.card ~intent ~border_radius :: attrs)
    ?reverse
    ?wrap
    ?justify
    ?align
    ?gap
    ~padding
    children
;;

let column
  ?(attrs = [])
  ?reverse
  ?wrap
  ?justify
  ?align
  ?gap
  ?(padding = `Px 4)
  ?(border_radius = `Px 4)
  ?intent
  children
  =
  Skyline_flex_v1.column
    ~attrs:(Style.card ~intent ~border_radius :: attrs)
    ?reverse
    ?wrap
    ?justify
    ?align
    ?gap
    ~padding
    children
;;
