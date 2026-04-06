open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

let component ?action ?intent ~icon label =
  let action =
    match action with
    | Some (label, on_click) -> View.hbox [ Skyline_button_v1.regular' ~on_click label ]
    | None -> Vdom.Node.none
  in
  Skyline_flex_v1.column
    ~gap:(`Px 16)
    ~align:Center
    ~justify:Center
    ~attrs:
      [ Css_gen.(
          box_sizing `Border_box
          @> uniform_margin (`Px 0)
          @> padding ~top:(`Px 16) ~bottom:(`Px 16) ~left:(`Px 8) ~right:(`Px 8) ())
        |> Vdom.Attr.style
      ]
    [ Skyline_flex_v1.column
        ~gap:(`Px 8)
        ~align:Center
        ~justify:Center
        ~attrs:[ Vdom.Attr.style (Css_gen.box_sizing `Border_box) ]
        [ Codicons.svg ~size:(`Px 24) ?color:intent icon
        ; Skyline_text_v1.span ?intent label
        ]
    ; action
    ]
;;

let error ?action ?(intent = Skyline_theme_v1.error) ?(icon = Codicons.Error) error =
  component ?action ~intent ~icon (Error.to_string_hum error)
;;
