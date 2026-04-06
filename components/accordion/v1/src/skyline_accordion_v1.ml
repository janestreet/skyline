open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  include
    [%css
    stylesheet
      ~dont_hash_prefixes:[ "--skyline" ]
      {|
        .accordion {
          box-sizing: border-box;
          margin: 0;
          padding: 0;
          display: flex;
          flex-direction: column;
          align-items: stretch;
        }

        .container {
          box-sizing: border-box;
          margin: 0;
          padding: 0;
          border-width: 0 1px 1px 1px;
          border-style: solid;
          border-color: var(--skyline-color-border);
          border-radius: 0;
          background-color: var(--skyline-color-background);
          overflow: hidden;
        }

        /* A nested accordion shows the child elements directly. */
        .container > .accordion > .container {
          border-width: 0 !important;
          border-radius: 0 !important;
          margin: 0 !important;
          background-color: var(--skyline-color-background);
        }

        .container:first-child {
          border-top-width: 1px;
        }

        .toggle_show_contents {
          box-sizing: border-box;
          margin: 0;
          padding: 0;

          display: flex;
          justify-content: flex-start;
          align-items: center;
          gap: 4px;
          flex-grow: 1;

          border-width: 0;
          border-style: solid;
          appearance: button;
          color: inherit;
          background-color: transparent;
          cursor: pointer;
        }

        /* Explode the container list if one of them is expanded. */

        .container.expanded + .container,
        .container:first-child {
          border-top-left-radius: 4px;
          border-top-right-radius: 4px;
        }

        .container:has(+ .container.expanded),
        .container:last-child {
          border-bottom-left-radius: 4px;
          border-bottom-right-radius: 4px;
        }

        .container.expanded {
          border-width: 1px;
          border-radius: 4px;
        }

        .container.expanded + .container {
          border-top-width: 1px;
          margin-top: 4px;
        }

        .container:has(+ .container.expanded):not(.expanded) {
          margin-bottom: 4px;
        }

        .title {
          box-sizing: border-box;
          margin: 0;
          padding: 4px;
          border-width: 0;
          border-radius: inherit; /* since we have a background */
          background-color: var(--skyline-color-background);
        }

        .title.sticky {
          z-index: 1000;
        }

        .container.expanded > .title {
          border-bottom-color: var(--skyline-color-border);
          border-bottom-width: 1px;
          border-bottom-left-radius: 0;
          border-bottom-right-radius: 0;
        }

        .container > .accordion > .container.expanded + .container > .title {
          border-top-color: var(--skyline-color-border);
          border-top-width: 1px;
        }

        .spinner {
          /* Match the icon button the spinner replaces. */
          width: 24px;
          height: 24px;
        }
      |}]
end

module Sticky_scroll_hook = Vdom.Attr.Hooks.Make (struct
    open Js_of_ocaml

    module State = struct
      type t =
        { mutable on_scroll_event_listener : Dom_html.event_listener_id option
        ; mutable next_animation_frame : Dom_html.animation_frame_request_id option
        ; mutable current_transform : float
        }
    end

    module Input = struct
      type t = unit [@@deriving sexp_of]

      let combine () () = ()
    end

    let reposition ~(state : State.t) ~(element : Dom_html.element Js.t) =
      let element_height = Int.to_float element##.clientHeight in
      let parent_height =
        let parent =
          let%bind.Option parentNode = Js.Opt.to_option element##.parentNode in
          Dom_html.CoerceTo.element parentNode |> Js.Opt.to_option
        in
        Option.value_map
          parent
          ~f:(fun parent -> Int.to_float parent##.clientHeight)
          ~default:element_height
      in
      let offset =
        let total_offset = Js.float_of_number element##getBoundingClientRect##.top in
        total_offset -. state.current_transform
      in
      let transform =
        Float.min (Float.max 0. (0. -. offset)) (parent_height -. element_height)
      in
      element##.style##.transform
      := Js.string
           [%string
             "translate(0px, %{Css_gen.Length.to_string_css (`Px_float transform)})"];
      element##.style##.borderRadius
      := Js.string (if Float.equal transform 0. then "" else "0px");
      state.current_transform <- transform
    ;;

    let init () _ =
      { State.on_scroll_event_listener = None
      ; next_animation_frame = None
      ; current_transform = 0.
      }
    ;;

    let on_mount () (state : State.t) element =
      let handler =
        Dom_html.handler (fun _ ->
          let next_animation_frame =
            Dom_html.window##requestAnimationFrame
              (Js.wrap_callback (fun _ -> reposition ~state ~element))
          in
          state.next_animation_frame <- Some next_animation_frame;
          Js.bool true)
      in
      let on_scroll_event_listener =
        Dom_html.addEventListenerWithOptions
          Dom_html.document
          Dom_html.Event.scroll
          ~passive:Js._true
          handler
      in
      state.on_scroll_event_listener <- Some on_scroll_event_listener
    ;;

    let on_mount = `Schedule_animation_frame on_mount
    let update ~old_input:() ~new_input:() _ _ = ()

    let destroy () (state : State.t) element =
      Option.iter state.on_scroll_event_listener ~f:(fun event_listener_id ->
        Dom_html.removeEventListener event_listener_id);
      Option.iter state.next_animation_frame ~f:(fun animation_frame_request_id ->
        Dom_html.window##cancelAnimationFrame animation_frame_request_id);
      element##.style##.transform := Js.string "";
      element##.style##.borderRadius := Js.string ""
    ;;
  end)

type t = Vdom.Node.t

let component
  ?test_selector
  ?expanded
  ?(sticky_title = Bonsai.return false)
  ?(detail = fun ~expanded:_ (local_ _graph) -> Bonsai.return Vdom.Node.none)
  ~label
  contents
  (local_ graph)
  =
  let test_selector = Bonsai.transpose_opt test_selector in
  let expanded, set_expanded =
    match expanded with
    | Some (expanded, set_expanded) -> expanded, set_expanded
    | None -> Bonsai.state `Collapsed graph
  in
  let contents =
    match%sub expanded with
    | `Expanded ->
      let contents = contents graph in
      let%arr contents in
      (contents :> [ `Value of Vdom.Node.t | `Loading | `None ])
    | `Collapsed -> Bonsai.return `None
  in
  let detail =
    let expanded =
      let%arr contents in
      match contents with
      | `Value _ -> `Expanded
      | `Loading | `None -> `Collapsed
    in
    detail ~expanded graph
  in
  let sticky_scroll =
    let%arr sticky_title in
    if sticky_title
    then
      Vdom.Attr.many
        [ Style.sticky
        ; Vdom.Attr.create_hook "sticky_scroll" (Sticky_scroll_hook.create ())
        ]
    else Vdom.Attr.empty
  in
  let%arr expanded
  and set_expanded
  and label
  and detail
  and sticky_scroll
  and contents
  and test_selector in
  let title =
    let chevron_and_label =
      let on_click =
        set_expanded
          (match expanded with
           | `Collapsed -> `Expanded
           | `Expanded -> `Collapsed)
      in
      let chevron =
        match contents with
        | `Value _ -> Skyline_button_v1.icon' Chevron_down ~on_click
        | `None -> Skyline_button_v1.icon' Chevron_right ~on_click
        | `Loading ->
          Skyline_flex_v1.row
            ~align:Center
            ~justify:Center
            ~attrs:[ Style.spinner ]
            [ Skyline_loading_indicator_v1.spinner () ]
      in
      Vdom.Node.button
        ~attrs:
          [ Style.toggle_show_contents
          ; Vdom.Attr.on_click (const on_click)
          ; Test_selector.attr_of_opt test_selector
          ]
        [ chevron; label ]
    in
    Skyline_flex_v1.row
      ~align:Center
      ~justify:Space_between
      ~attrs:[ Style.title; sticky_scroll ]
      [ chevron_and_label; detail ]
  in
  match contents with
  | `Loading | `None ->
    Skyline_flex_v1.column ~attrs:[ Style.container ] ~align:Stretch [ title ]
  | `Value content ->
    Skyline_flex_v1.column
      ~attrs:[ Style.container; Style.expanded ]
      ~align:Stretch
      [ title; content ]
;;

let view rows = Vdom.Node.div ~attrs:[ Style.accordion ] rows
