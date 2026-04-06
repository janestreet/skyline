open! Core
open Js_of_ocaml
open! Private_skyline_prelude

module Element = struct
  type t = Dom_html.element Js.t

  let get_by_selector sel =
    Js_of_ocaml.Dom_html.document##querySelector (Js_of_ocaml.Js.string sel)
    |> Js_of_ocaml.Js.Opt.to_option
  ;;

  module Scroll_into_view_options = struct
    module Behavior = struct
      type t =
        | Smooth
        | Instant
        | Auto
      [@@deriving variants]

      let to_name t = Variants.to_name t |> String.lowercase
    end

    module Alignment = struct
      type t =
        | Start
        | Center
        | End
        | Nearest
      [@@deriving variants]

      let to_name t = Variants.to_name t |> String.lowercase
    end

    type t =
      { behavior : Behavior.t
      ; block : Alignment.t
      ; inline : Alignment.t
      }

    let default : t = { behavior = Auto; block = Start; inline = Start }

    let to_js_object t =
      let behavior = Behavior.to_name t.behavior in
      let inline = Alignment.to_name t.inline in
      let block = Alignment.to_name t.block in
      Js_of_ocaml.Js.Unsafe.inject
        (object%js
           val behavior = Js_of_ocaml.Js.string behavior
           val inline = Js_of_ocaml.Js.string inline
           val block = Js_of_ocaml.Js.string block
        end)
    ;;
  end

  let scroll_into_view
    ?(options = Scroll_into_view_options.default)
    (t : Js_of_ocaml.Dom_html.element Js_of_ocaml.Js.t)
    =
    match Am_running_how_js.am_running_how with
    | `Node_test | `Node_jsdom_test -> Effect.Ignore
    | `Browser | `Browser_test | `Browser_benchmark | `Node | `Node_benchmark ->
      let options_js = options |> Scroll_into_view_options.to_js_object in
      Effect.of_thunk (fun () ->
        Js_of_ocaml.Js.Unsafe.meth_call t "scrollIntoView" [| options_js |])
  ;;
end

module Event = struct
  let get_target_bounding_box (event : Dom_html.event Js.t) =
    match Js.Opt.to_option event##.currentTarget with
    | None -> ~relative_to:`Viewport, ~top:0., ~left:0., ~bottom:0., ~right:0.
    | Some target ->
      let rect = target##getBoundingClientRect in
      ( ~relative_to:`Document
      , ~top:(Js.float_of_number rect##.top)
      , ~left:(Js.float_of_number rect##.left)
      , ~bottom:(Js.float_of_number rect##.bottom)
      , ~right:(Js.float_of_number rect##.right) )
  ;;
end
