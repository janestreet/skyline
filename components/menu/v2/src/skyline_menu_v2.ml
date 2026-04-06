open! Core
open! Private_skyline_prelude
module Options = Skyline_menu_v2_options

module Position = struct
  type t = Bonsai_web_toplayer.Position.t =
    | Auto
    | Top
    | Bottom
    | Left
    | Right
  [@@deriving sexp, equal, compare, enumerate, to_string]
end

module Alignment = struct
  type t = Bonsai_web_toplayer.Alignment.t =
    | Center
    | Start
    | End
  [@@deriving sexp_of, equal, to_string]
end

module State = struct
  type t =
    | Closed
    | Opened_at_position of (Options.t * Bonsai_web_toplayer.Anchor.t)
end

type t =
  { state : State.t
  ; set_state : State.t -> unit Effect.t
  }

(** Coerces an event to a [PointerEvent] if it is one, using [instanceof]. Returns [None]
    if the event is not a PointerEvent or if PointerEvent is not available in the current
    environment (e.g. jsdom). *)
let maybe_coerce_pointer_event event =
  let%bind.Option window = Browser_expert.Global.window () in
  let pointer_event_t = window##._PointerEvent_t in
  Browser_expert.coerce ~to_:pointer_event_t event
;;

(** Returns the page coordinates of a pointer event, or [None] if the event has no
    [pointerType] (e.g. keyboard-initiated clicks produce [PointerEvent]s with an empty
    [pointerType]). *)
let position_if_pointer_type_present event =
  let module Js = Browser_expert.Js in
  let%bind.Option pointer_event = maybe_coerce_pointer_event event in
  let pointer_type = Js.to_string pointer_event##.pointerType in
  if String.is_empty pointer_type
  then None
  else (
    let top = Js.float_of_number pointer_event##.pageY in
    let left = Js.float_of_number pointer_event##.pageX in
    Some (~top, ~left))
;;

let component
  ?(size : Skyline_size.t Bonsai.t option)
  ?(position = Bonsai.return Position.Auto)
  ?(alignment = Bonsai.return Alignment.Start)
  ?state
  (graph @ local)
  =
  let state, set_state = Option.value ~default:(Bonsai.state State.Closed graph) state in
  let close =
    let%arr set_state in
    set_state State.Closed
  in
  let autoclose =
    Bonsai_web_toplayer.Autoclose.create
      ~close
      ~close_on_click_outside:(return Bonsai_web_toplayer.Close_on_click_outside.Yes)
      ~close_on_right_click_outside:
        (return Bonsai_web_toplayer.Close_on_click_outside.Yes)
      ~close_on_esc:(return true)
      graph
  in
  let _ : unit Bonsai.t =
    match%sub state with
    | State.Closed -> return ()
    | State.Opened_at_position (items, anchor) ->
      Bonsai_web_toplayer.Popover.always_open_virtual
        ~attrs:(return [ Options.Styles.container ])
        ~autoclose
        ~position
        ~alignment
        ~overflow_auto_wrapper:(return false)
        ~content:(fun graph ->
          Options.Expert.component
            ?size
            ~focus_on_activate:(return true)
            items
            ~close
            graph)
        anchor
        graph;
      return ()
  in
  let%arr state and set_state in
  { state; set_state }
;;

let is_ctrl_held event =
  (* Check if ctrl is held - if so, allow browser's default behavior *)
  Js_of_ocaml.Js.to_bool event##.ctrlKey
;;

let menu_effect_of_event menu ~options ~event ~position_at_cursor =
  let effect event =
    if is_ctrl_held event
    then Effect.Ignore
    else (
      let anchor =
        let anchor_of_target () =
          let ~relative_to, ~top, ~left, ~bottom, ~right =
            Private_skyline_dom.Event.get_target_bounding_box
              (event :> Js_of_ocaml.Dom_html.event Js_of_ocaml.Js.t)
          in
          Bonsai_web_toplayer.Anchor.of_bounding_box
            ~relative_to
            ~top
            ~left
            ~bottom
            ~right
        in
        match position_at_cursor with
        | true ->
          (match position_if_pointer_type_present event with
           | Some (~top, ~left) ->
             Bonsai_web_toplayer.Anchor.of_coordinate
               ~relative_to:`Document
               ~x:left
               ~y:top
           | None -> anchor_of_target ())
        | false -> anchor_of_target ()
      in
      let%bind.Effect options in
      menu.set_state (State.Opened_at_position (options, anchor)))
  in
  effect event
;;

let on_click ?(position_at_cursor = true) menu ~options =
  Attr.on_click (fun event ->
    menu_effect_of_event menu ~options ~event ~position_at_cursor)
;;

let on_contextmenu ?(position_at_cursor = true) menu ~options =
  Attr.many
    [ (* We use `auxclick` to replicate the UX of the `contextmenu` event in a
         cross-platform way. The `contextmenu` event behaves differently across Linux and
         Windows. On Linux, contextmenu fires on mousedown, while on Windows it fires on
         mouseup. `auxclick` fires on mouseup consistently across platforms.
      *)
      Attr.on_contextmenu (fun event ->
        if not (is_ctrl_held event)
        then
          (* Suppress native context menu. We'll show it on auxclick *)
          Js_of_ocaml.Dom.preventDefault event;
        Effect.Ignore)
    ; Attr.on_auxclick (fun event ->
        let is_ctrl_held = is_ctrl_held event in
        let only_right_click = event##.button = 2 in
        match is_ctrl_held, only_right_click with
        | false, true -> menu_effect_of_event menu ~options ~event ~position_at_cursor
        | _, _ -> Effect.Ignore)
    ]
;;

module For_docs = struct
  let ml_filepath = __FILE__
end
