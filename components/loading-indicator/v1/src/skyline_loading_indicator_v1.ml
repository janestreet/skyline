open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  include
    [%css
    stylesheet
      ~dont_hash_prefixes:[ "--skyline" ]
      {|
        .spinner-container {
          width: 16px;
          height: 16px;
          display: flex;
          align-items: center;
          justify-content: center;
          overflow: visible;
        }

        .spinner {
          animation: var(--spinner-speed, 1s) infinite linear spinner;
        }

        @keyframes spinner {
          0% {
            transform: rotate(0deg);
          }
          100% {
            transform: rotate(360deg);
          }
        }

        .progress {
          width: 100%;
          height: 2px;
          position: relative;
          margin-bottom: -2px;
          overflow: hidden;
        }

        .progress .runner {
          width: 2%;
          height: 2px;
          position: absolute;
          left: 0;
          background-color: var(--skyline-color-accent);
          animation: 4s infinite linear progress;
          z-index: 1000; /* place over container content */
        }

        @keyframes progress {
          0% {
            transform: translateX(0%) scaleX(1);
          }
          50% {
            transform: translateX(2500%) scaleX(3);
          }
          100% {
            transform: translateX(4900%) scaleX(1);
          }
        }
      |}]
end

let spinner ?(icon = Codicons.Loading) () =
  let spinner_speed =
    match icon with
    | Settings_gear | Gear | Sync | Refresh -> "2s"
    | Loading | _ -> "1s"
  in
  Vdom.Node.div
    ~attrs:[ Style.spinner_container ]
    [ Codicons.svg
        ~extra_attrs:[ Style.Variables.set ~spinner_speed (); Style.spinner ]
        icon
    ]
;;

let runner () =
  Vdom.Node.div ~attrs:[ Style.progress ] [ Vdom.Node.div ~attrs:[ Style.runner ] [] ]
;;
