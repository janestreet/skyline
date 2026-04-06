open! Core
open! Js_of_ocaml

let stylesheet_contents =
  let open Skyline_tokens_v2 in
  [%string
    {|
      @layer skyline_base_styles {
        :root {
          color-scheme: light dark;
          font-family: %{Font.Family.to_string_css Font.Family.sans};
          font-size: %{Css_gen.Length.to_string_css Font.size_base};
          line-height: %{Css_gen.Length.to_string_css Font.line_height_base};
        }

        body {
          background-color: %{Css_gen.Color.to_string_css Colors.Background.app};
        }
      }
    |}]
;;

let stylesheet =
  lazy
    (Js.Opt.case
       (Js.Unsafe.get Js.Unsafe.global "CSSStyleSheet")
       (const None)
       (fun constr ->
          let sheet = new%js constr in
          let () =
            (Js.Unsafe.coerce Dom_html.document)##.adoptedStyleSheets##push sheet
          in
          Some sheet))
;;

let is_installed () =
  match force stylesheet with
  | None -> false
  | Some style -> Float.(Js.to_float style##.cssRules##.length > 0.)
;;

let install () =
  Option.iter (force stylesheet) ~f:(fun sheet ->
    if not (is_installed ())
    then sheet##insertRule (Js.string stylesheet_contents) (Js.float 0.))
;;

let clear () =
  Option.iter (force stylesheet) ~f:(fun sheet ->
    if is_installed () then sheet##deleteRule (Js.float 0.))
;;
