open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Set_globals = struct
  open Js_of_ocaml
  module State = Unit

  module Input = struct
    type t =
      { theme : Skyline_theme_v1.Style.t
      ; accent : Skyline_theme_v1.Accent.t
      ; global_css : [ `Skyline_css_reset | `Skyline_base_styles | `None ]
      }
    [@@deriving sexp_of, equal]

    let combine fst _snd = fst
  end

  let update_css_and_theme { Input.theme; accent; global_css } =
    (match global_css with
     | `Skyline_base_styles -> Private_skyline_theme.Base_Styles.install ()
     | `Skyline_css_reset | `None -> Private_skyline_theme.Base_Styles.clear ());
    (match global_css with
     | `Skyline_css_reset -> Private_skyline_theme.Stylesheet.install ()
     | `Skyline_base_styles | `None -> Private_skyline_theme.Stylesheet.clear ());
    Private_skyline_theme.Colors.install theme ~accent
  ;;

  let init (input : Input.t) (_ : Dom_html.element Js.t) =
    Private_skyline_exn_handler.set_uncaught_exception_handler ();
    update_css_and_theme input
  ;;

  let on_mount = `Do_nothing

  let update ~old_input ~new_input () (_ : Dom_html.element Js.t) =
    if not (Input.equal old_input new_input) then update_css_and_theme new_input
  ;;

  let destroy (_ : Input.t) () (_ : Dom_html.element Js.t) =
    Private_skyline_theme.Base_Styles.clear ();
    Private_skyline_theme.Colors.clear ();
    Private_skyline_theme.Stylesheet.clear ();
    Private_skyline_exn_handler.remove_uncaught_exception_handler ()
  ;;

  include functor Vdom.Attr.Hooks.Make
end

let theme_scope =
  Bonsai.Dynamic_scope.create
    ~name:"skyline-theme"
    ~fallback:Skyline_theme_v1.Style.Light
    ()
;;

let accent_scope = Bonsai.Dynamic_scope.create ~name:"skyline-accent" ~fallback:`Blue ()

let set_scope scope ~value inside graph =
  Bonsai.Dynamic_scope.set scope value ~inside graph
;;

let install
  ?(global_css = return `Skyline_base_styles)
  ?(toast_position = return `Top_left)
  ?(theme = return Skyline_theme_v1.Style.Light)
  ?(accent = return `Blue)
  computation
  graph
  =
  let%arr global_css
  and theme
  and accent
  and vdom =
    (View.Theme.set_for_computation
       (let%arr theme in
        Private_skyline_view_compat.theme theme)
       computation
     |> set_scope theme_scope ~value:theme
     |> set_scope accent_scope ~value:accent
     |> set_scope Private_skyline_toast.position ~value:toast_position
     |> Private_skyline_keyboard_shortcut.install_listener ~mode:`Global)
      graph
  in
  let set_globals =
    Vdom.Attr.create_hook
      "skyline-globals"
      (Set_globals.create { theme; accent; global_css })
  in
  match (vdom : Vdom.Node.t) with
  | Element elem ->
    Vdom.Node.Element
      (Vdom.Node.Element.map_attrs elem ~f:(fun attr ->
         Vdom.Attr.combine attr set_globals))
  | vdom -> Vdom.Node.div ~attrs:[ set_globals ] [ vdom ]
;;

let theme graph = Bonsai.Dynamic_scope.lookup theme_scope graph
let accent graph = Bonsai.Dynamic_scope.lookup accent_scope graph
