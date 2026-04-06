open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  include
    [%css
    stylesheet
      ~dont_hash_prefixes:[ "--skyline" ]
      {|
        .relative_container_for_buttons {
          position: relative;
        }

        .container {
          min-height: 32px; /* 24 + 4 + 4 so that the actions always fit. */
          width: 100%;
          padding: 4px;
          display: flex;
          flex-direction: column;

          border-radius: 4px;
          color: var(--skyline-color-background);
          background-color: var(--skyline-color-primary);

          font-family: monospace;
          font-size: 0.8rem;
          line-height: 0.9rem;

          overflow: auto;
        }

        .container.vertial-scroll {
          white-space: pre;
        }

        .container.wrapped {
          white-space: pre-wrap;
        }

        .relative_container_for_buttons .actions {
          position: absolute;
          display: flex;
          flex-direction: row;

          top: 4px;
          right: 4px;

          border-radius: 4px;
          background: var(--skyline-color-background);
          opacity: 0;
        }

        .relative_container_for_buttons:hover .actions {
          opacity: 0.5;
          &:hover {
            opacity: 1;
          }
        }
      |}]
end

let component
  ?test_selector
  ?(initial_line_wrap = false)
  ?(max_height = Some (`Px 400))
  logs
  graph
  =
  let wrap, toggle_wrap = Bonsai.toggle ~default_model:initial_line_wrap graph in
  let%arr logs
  and wrap
  and toggle_wrap
  and copy_logs = Bonsai_web_clipboard.With_status.copy_text logs graph in
  let toggle_wrap =
    Skyline_button_v1.icon'
      ~tooltip:(if wrap then "Don't Wrap Lines" else "Wrap Lines")
      ~on_click:toggle_wrap
      Word_wrap
  in
  let copy_logs =
    match copy_logs with
    | `Idle on_click ->
      Skyline_button_v1.icon' ?test_selector ~tooltip:"Copy Logs" ~on_click Copy
    | `Copied ->
      Skyline_button_v1.icon' ~tooltip:"Copied" ~on_click:(Effect.return ()) Check
  in
  let max_height_attr =
    match max_height with
    | None -> Vdom.Attr.empty
    | Some (`Px px) ->
      let px_string = [%string "%{px#Int}px"] in
      [%css {|max-height: %{px_string};|}]
  in
  Vdom.Node.div
    ~attrs:[ Style.relative_container_for_buttons ]
    [ Vdom.Node.div
        ~attrs:
          [ Style.container
          ; max_height_attr
          ; (if wrap then Style.wrapped else Style.vertial_scroll)
          ; Test_selector.attr_of_opt test_selector
          ]
        [ Vdom.Node.text logs ]
    ; Vdom.Node.div ~attrs:[ Style.actions ] [ toggle_wrap; copy_logs ]
    ]
;;
