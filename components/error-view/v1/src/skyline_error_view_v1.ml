open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

let component handler graph =
  match%sub Bonsai.map handler ~f:Skyline_errors_v1.errors with
  | [] -> Bonsai.return None
  | error :: more_errors ->
    let actions =
      let%arr error and handler in
      [ Skyline_context_menu_v1.Item.single
          ~on_click:(Error.to_string_hum error |> Bonsai_web_clipboard.copy_text)
          "Copy Error"
      ; Skyline_context_menu_v1.Item.single
          ~on_click:(Skyline_errors_v1.clear handler)
          "Clear"
      ]
    in
    let message =
      let%arr error and more_errors in
      let error = Error.to_string_hum error in
      let more_errors =
        match List.length more_errors with
        | 0 -> ""
        | num -> [%string " + %{num#Int} more"]
      in
      error ^ more_errors
    in
    let view =
      Skyline_banner_v1.with_actions
        ~dropdown:actions
        ~intent:(Bonsai.return Skyline_theme_v1.error)
        ~icon:(Bonsai.return Codicons.Error)
        message
        graph
    in
    let%arr view in
    Some view
;;
