open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  include
    [%css
    stylesheet
      ~dont_hash_prefixes:[ "--skyline" ]
      {|
        .glimmer {
          background: var(--skyline-color-border);
          animation: 2s ease-in-out infinite pulse;
        }

        @keyframes pulse {
          0%,
          100% {
            opacity: 10%;
          }
          50% {
            opacity: 100%;
          }
        }
      |}]
end

let component ?(rounded = `Px 0) ~width ~height () =
  let attr =
    Vdom.Attr.many
      [ Vdom.Attr.style (Css_gen.width width)
      ; Vdom.Attr.style (Css_gen.height height)
      ; Vdom.Attr.style (Css_gen.border_radius rounded)
      ; Style.glimmer
      ]
  in
  Vdom.Node.div ~attrs:[ attr ] []
;;

let text ~width = component ~rounded:(`Px 4) ~width ~height:(`Px 12) ()
