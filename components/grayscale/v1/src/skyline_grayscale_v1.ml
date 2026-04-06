open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  include
    [%css
    stylesheet
      {|
        .grayscale {
          filter: grayscale(var(--percent));
        }

        .disable_interaction {
          pointer-events: none;
          user-select: none;
        }

        @keyframes skyline-fade-grayscale {
          0% {
            filter: grayscale(0);
          }
          100% {
            filter: grayscale(var(--percent));
          }
        }

        .fade {
          animation-name: skyline-fade-grayscale;
          animation-duration: var(--duration);
          animation-iteration-count: 1;
        }
      |}]

  let grayscale percent =
    Vdom.Attr.many [ Variables.set ~percent:[%string "%{percent#Int}%"] (); grayscale ]
  ;;

  let fade duration =
    let duration =
      Time_ns.Span.to_sec duration
      |> Float.to_string
      |> String.chop_suffix_if_exists ~suffix:"."
    in
    Vdom.Attr.many [ Variables.set ~duration:[%string "%{duration}s"] (); fade ]
  ;;
end

let attr ?(disable = false) ?fade ~percent () =
  Vdom.Attr.many
    [ Style.grayscale percent
    ; (if disable then Style.disable_interaction else Vdom.Attr.empty)
    ; Vdom.Attr.bool_property
        "inert" (* https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/inert *)
        disable
    ; Option.value_map fade ~f:Style.fade ~default:Vdom.Attr.empty
    ]
;;

let container ?disable ?fade ~percent view =
  Vdom.Node.div ~attrs:[ attr ?disable ?fade ~percent () ] [ view ]
;;
