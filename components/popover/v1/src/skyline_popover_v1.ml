open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  let popover ~padding:popover_padding =
    let style =
      Css_gen.(
        max_height (`Percent Percent.one_hundred_percent)
        @> uniform_padding (Option.value popover_padding ~default:(`Px 4))
        @> border_radius (`Px 4)
        @> border
             ~width:(`Px 1)
             ~style:`Solid
             ~color:Private_skyline_theme.Colors.Constants.border
             ()
        @> background_color Private_skyline_theme.Colors.Constants.surface
        @> overflow_x `Hidden
        @> overflow_y `Auto)
    in
    Vdom.Attr.many
      [ Vdom.Attr.style style
      ; Private_skyline_theme.Stylesheet.step_nested_surface_ramp
      ; Vdom.Attr.style Private_skyline_theme.Shadows.raised_card
      ]
  ;;

  (* We set a 4px offset for the popover, so we reduce the width by 8px to allow for the
     same amount of margin to either side of the viewport. *)

  let content_width =
    Vdom.Attr.style
      Css_gen.(
        create ~field:"width" ~value:"max-content"
        @> create ~field:"max-width" ~value:"max(300px, calc(100vw - 8px))")
  ;;
end

module Position = struct
  type t = Bonsai_web_themed_toplayer.Position.t =
    | Auto
    | Top
    | Bottom
    | Left
    | Right
  [@@deriving sexp_of, equal]
end

module Alignment = struct
  type t = Bonsai_web_themed_toplayer.Alignment.t =
    | Center
    | Start
    | End
  [@@deriving sexp_of, equal]
end

module Width = struct
  type t =
    | Content
    | Fixed of Css_gen.Length.t
    | Max of Css_gen.Length.t
  [@@deriving sexp_of]
end

type t =
  { anchor : Vdom.Attr.t
  ; is_open : bool
  ; set_is_open : bool -> unit Effect.t
  }

let anchor { anchor; _ } = anchor
let visible { is_open; _ } = is_open

(* [show], [hide], and [toggle] intentionally use state at time of effect construction,
   not at time of effect execution. This is so that user actions are consistent with the
   UI state at the time of the action happening. The main motivating example is:

   - There is a button _outside_ of the popover, which does [~on_click:(open popover)]
   - but the popover should close on click outside

   Now we want the UX to be that clicking on the button closes the popover because:
   - opening does nothing since it's already open
   - at the same time the click outside triggers a close, which does take effect. *)

let show { is_open; set_is_open; _ } =
  if not is_open then set_is_open true else Effect.Ignore
;;

let hide { is_open; set_is_open; _ } =
  if is_open then set_is_open false else Effect.Ignore
;;

let toggle { is_open; set_is_open; _ } = set_is_open (not is_open)

let component
  ?(attrs = return [])
  ?state
  ?(position = return Position.Auto)
  ?(alignment = return Alignment.Center)
  ?(focus_on_show = return true)
  ?(close_on_click_outside = return true)
  ?(width = return Width.Content)
  ?padding
  contents
  (local_ graph)
  =
  let is_open, set_is_open =
    match state with
    | Some (visible, set_visible) -> visible, set_visible
    | None -> Bonsai.state false graph
  in
  let extra_attrs =
    let%arr width
    and attrs
    and padding = Bonsai.transpose_opt padding in
    let width =
      match (width : Width.t) with
      | Content -> Style.content_width
      | Fixed width -> Vdom.Attr.style (Css_gen.width width)
      | Max width -> Vdom.Attr.style (Css_gen.max_width width)
    in
    [ Style.popover ~padding; width; Vdom.Attr.many attrs ]
  in
  let anchor =
    let close =
      let%arr set_is_open in
      set_is_open false
    in
    let close_on_click_outside =
      if%arr close_on_click_outside
      then Bonsai_web_themed_toplayer.Close_on_click_outside.Yes
      else No
    in
    let autoclose =
      Bonsai_web_themed_toplayer.Autoclose.create
        ~close
        ~close_on_click_outside
        ~close_on_right_click_outside:close_on_click_outside
        ~close_on_esc:(return true)
        graph
    in
    match%sub is_open with
    | true ->
      Bonsai_web_themed_toplayer.Popover.always_open
        ~extra_attrs
        ~autoclose
        ~position
        ~alignment
        ~focus_on_open:focus_on_show
        ~overflow_auto_wrapper:(return false)
        ~content:(fun graph -> contents ~hide:close graph)
        graph
    | false -> return Vdom.Attr.empty
  in
  let%arr anchor and is_open and set_is_open in
  { anchor; is_open; set_is_open }
;;
