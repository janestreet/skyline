open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

type t = Bonsai_web_clipboard.With_status.t

let text = Bonsai_web_clipboard.With_status.copy_text
let html = Bonsai_web_clipboard.With_status.copy_html
let link = Bonsai_web_clipboard.With_status.copy_link
let text_effect = Bonsai_web_clipboard.copy_text
let html_effect = Bonsai_web_clipboard.copy_html
let link_effect = Bonsai_web_clipboard.copy_link

let icon_button ?test_selector ?tooltip ?(icon = Codicons.Copy) ?intent ~text:value graph =
  let effect = text value graph in
  let%arr effect
  and tooltip =
    match tooltip with
    | Some tooltip -> tooltip
    | None ->
      let%arr value in
      let snippet =
        if String.length value > 25 then String.prefix value 25 ^ "..." else value
      in
      [%string "Copy %{snippet}"]
  in
  match effect with
  | `Idle on_click ->
    Skyline_button_v1.icon' ?test_selector ~tooltip ~on_click ?intent icon
  | `Copied ->
    Skyline_button_v1.icon'
      ?test_selector
      ~tooltip:"Copied"
      ~on_click:(Effect.return ())
      ?intent
      Check
;;
