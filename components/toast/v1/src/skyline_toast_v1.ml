open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  let container ~position:toast_position =
    Css_gen.(
      (match toast_position with
       | `Top_left ->
         position
           ~top:(`Px 24)
           ~bottom:(`Raw "unset")
           ~left:(`Px 24)
           ~right:(`Raw "unset")
           `Fixed
       | `Top_right ->
         position
           ~top:(`Px 24)
           ~bottom:(`Raw "unset")
           ~left:(`Raw "unset")
           ~right:(`Px 24)
           `Fixed
       | `Bottom_left ->
         position
           ~top:(`Raw "unset")
           ~bottom:(`Px 24)
           ~left:(`Px 24)
           ~right:(`Raw "unset")
           `Fixed
       | `Bottom_right ->
         position
           ~top:(`Raw "unset")
           ~bottom:(`Px 24)
           ~left:(`Raw "unset")
           ~right:(`Px 24)
           `Fixed)
      @> box_sizing `Border_box
      @> uniform_margin (`Px 0)
      @> uniform_padding (`Px 0)
      @> flex_container ~direction:`Column ()
      @> max_width (`Raw "calc(100vw - 48px)")
      @> max_height (`Raw "calc(100vh - 48px)")
      @> border_radius (`Px 4)
      @> border ~width:(`Px 1) ~color:Skyline_theme_v1.border ~style:`Solid ()
      @> color Skyline_theme_v1.primary
      @> background_color Skyline_theme_v1.surface
      @> Private_skyline_theme.Shadows.floating_card)
    |> Vdom.Attr.style
  ;;

  let text_content =
    Css_gen.(
      box_sizing `Border_box
      @> max_width (`Px 400)
      @> uniform_margin (`Px 0)
      @> uniform_padding (`Px 8)
      @> flex_item ~grow:1. ())
    |> Vdom.Attr.style
  ;;

  let title =
    Css_gen.(
      box_sizing `Border_box
      @> uniform_margin (`Px 0)
      @> uniform_padding (`Px 0)
      @> min_height (`Px 16)
      @> line_height (`Px 16))
    |> Vdom.Attr.style
  ;;

  let leading_icon =
    Css_gen.(
      box_sizing `Border_box
      @> uniform_margin (`Px 0)
      @> uniform_padding (`Px 0)
      @> width (`Px 24)
      @> height (`Px 32)
      @> flex_container
           ~direction:`Column
           ~align_items:`Flex_end
           ~justify_content:`Center
           ()
      @> flex_item ~shrink:0. ~grow:0. ())
    |> Vdom.Attr.style
  ;;

  let close_button =
    Css_gen.(
      box_sizing `Border_box
      @> uniform_margin (`Px 0)
      @> uniform_padding (`Px 0)
      @> width (`Px 32)
      @> height (`Px 32)
      @> flex_container
           ~direction:`Column
           ~align_items:`Center
           ~justify_content:`Center
           ()
      @> flex_item ~shrink:0. ~grow:0. ()
      @> border ~width:(`Px 0) ~style:`Solid ()
      @> background_color (`Name "transparent")
      @> create ~field:"cursor" ~value:"pointer")
    |> Vdom.Attr.style
  ;;
end

type toast =
  { timeout : Time_ns.t
  ; intent : Skyline_theme_v1.Color.t
  ; icon : Codicons.t
  ; title : string
  ; message : string
  }

type custom_toast =
  { timeout : Time_ns.t
  ; content : close:unit Effect.t -> Vdom.Node.t
  }

let toast_content ~close toast =
  let%arr { intent; icon; title; message; _ } = toast
  and close in
  let maybe_icon =
    match icon with
    | Blank -> Vdom.Node.none
    | icon ->
      Vdom.Node.span ~attrs:[ Style.leading_icon ] [ Codicons.svg ~color:intent icon ]
  in
  let maybe_title =
    if String.is_empty (String.strip title)
    then Vdom.Node.none
    else Skyline_text_v1.heading ~size:Small ~intent ~attrs:[ Style.title ] title
  in
  Skyline_flex_v1.row
    ~align:Flex_start
    ~justify:Space_between
    [ maybe_icon
    ; Skyline_flex_v1.column
        ~attrs:[ Style.text_content ]
        [ maybe_title; Skyline_text_v1.span message ]
    ; Vdom.Node.button
        ~attrs:[ Style.close_button; Vdom.Attr.on_click (const close) ]
        [ Codicons.svg ~color:Skyline_theme_v1.primary Close ]
    ]
;;

let custom_toast_content ~close custom_toast =
  let%arr { content; _ } = custom_toast
  and close in
  let content = content ~close in
  Skyline_flex_v1.row
    ~align:Flex_start
    ~justify:Space_between
    [ content
    ; Vdom.Node.button
        ~attrs:[ Style.close_button; Vdom.Attr.on_click (const close) ]
        [ Codicons.svg ~color:Skyline_theme_v1.primary Close ]
    ]
;;

let make_show (type a) ~(init_toast : a) ~timeout ~toast_content graph =
  let current, set_current = Private_skyline_toast.component (return init_toast) graph in
  let timeout = timeout current in
  let close =
    let%arr set_current in
    set_current Dismiss
  in
  let extra_attrs =
    let%arr position = Bonsai.Dynamic_scope.lookup Private_skyline_toast.position graph in
    [ Style.container ~position ]
  in
  let is_open =
    match%arr Bonsai.Clock.at timeout graph with
    | After -> false
    | Before -> true
  in
  let%sub () =
    match%sub is_open with
    | true ->
      Bonsai_web_themed_toplayer.Popover.always_open_css
        ~extra_attrs
        ~content:(fun _ -> toast_content ~close current)
        graph;
      return ()
    | false -> return ()
  in
  let%arr set_current
  and now = Bonsai.Clock.get_current_time graph in
  fun current_toast ->
    let%bind.Effect now in
    let current = current_toast ~now in
    set_current (Replace current)
;;

let component graph =
  let show =
    make_show
      ~init_toast:
        { timeout = Time_ns.min_value_representable
        ; intent = `Inherit
        ; icon = Blank
        ; title = ""
        ; message = ""
        }
      ~timeout:(fun toast ->
        let%sub { timeout; _ } = toast in
        timeout)
      ~toast_content
      graph
  in
  let%arr show in
  fun ?(timeout = Time_ns.Span.of_int_sec 5)
    ?(intent = Skyline_theme_v1.primary)
    ?(icon = Codicons.Blank)
    ?(title = "")
    message ->
    let toast ~now =
      { timeout = Time_ns.add now timeout; intent; icon; title; message }
    in
    show toast
;;

let custom_component graph =
  let show =
    make_show
      ~init_toast:
        { timeout = Time_ns.min_value_representable
        ; content = (fun ~close:_ -> Vdom.Node.none)
        }
      ~timeout:(fun toast ->
        let%arr { timeout; _ } = toast in
        timeout)
      ~toast_content:custom_toast_content
      graph
  in
  let%arr show in
  fun ?(timeout = Time_ns.Span.of_int_sec 5) content ->
    let toast ~now = { timeout = Time_ns.add now timeout; content } in
    show toast
;;

let error graph =
  let%arr toast = component graph in
  fun error ->
    toast
      ~intent:Skyline_theme_v1.error
      ~icon:Error
      ~title:"Error"
      (Error.to_string_hum error)
;;
