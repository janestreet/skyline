open! Core
open! Js_of_ocaml

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
    then sheet##insertRule (Js.string Embedded_files.stylesheet_dot_css) (Js.float 0.))
;;

let clear () =
  Option.iter (force stylesheet) ~f:(fun sheet ->
    if is_installed () then sheet##deleteRule (Js.float 0.))
;;

let step_nested_surface_ramp = Virtual_dom.Vdom.Attr.class_ "skyline-surface"
