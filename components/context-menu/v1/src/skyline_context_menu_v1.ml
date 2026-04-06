open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  let ( @> ) = Css_gen.( @> )

  let clear_popover_styles =
    Css_gen.background_color (`Name "transparent")
    @> Css_gen.border ~style:`None ()
    @> Css_gen.uniform_padding (`Px 0)
  ;;

  let clear_popover_styles_config =
    Bonsai_web_ui_toplayer.Popover.Config.create
      ~popover_attrs:[ Vdom.Attr.style clear_popover_styles ]
      ~arrow:Vdom.Node.none
      ()
  ;;

  let menu =
    Css_gen.box_sizing `Border_box
    @> Css_gen.flex_container
         ~direction:`Column
         ~justify_content:`Flex_start
         ~align_items:`Stretch
         ()
    @> Css_gen.padding ~top:(`Px 4) ~bottom:(`Px 4) ~left:(`Px 0) ~right:(`Px 0) ()
    @> Css_gen.uniform_margin (`Px 0)
    @> Css_gen.color Skyline_theme_v1.primary
    @> Css_gen.background_color
         (* Note: Side-step surface nesting for the context menu, so that menus have a
            consistent look, even when e.g. spawned from a popover that itself has a
            surface ramp step. *)
         (`Var_with_default
           ("--skyline-color-surface-nested-first", Skyline_theme_v1.surface))
    @> Css_gen.border_radius (`Px 4)
    @> Css_gen.border ~width:(`Px 1) ~style:`Solid ~color:Skyline_theme_v1.border ()
    @> Css_gen.overflow_x `Hidden
    @> Css_gen.overflow_y `Auto
    @> Private_skyline_theme.Shadows.raised_card
  ;;

  let section =
    Css_gen.box_sizing `Border_box
    @> Css_gen.uniform_margin (`Px 0)
    @> Css_gen.uniform_padding (`Px 0)
    @> Css_gen.flex_container
         ~direction:`Column
         ~justify_content:`Flex_start
         ~align_items:`Stretch
         ()
  ;;

  let section_top_border =
    Css_gen.margin_top (`Px 4)
    @> Css_gen.padding_top (`Px 4)
    @> Css_gen.border_top ~width:(`Px 1) ~style:`Solid ~color:Skyline_theme_v1.border ()
  ;;

  let section_title =
    Css_gen.box_sizing `Border_box
    @> Css_gen.uniform_margin (`Px 0)
    @> Css_gen.uniform_padding (`Px 0)
    @> Css_gen.max_width (`Px 360)
    @> Css_gen.margin ~top:(`Px 4) ~right:(`Px 8) ~bottom:(`Px 4) ~left:(`Px 28) ()
    @> Css_gen.create ~field:"text-transform" ~value:"uppercase"
    @> Css_gen.color
         (Skyline_theme_v1.ramp Skyline_theme_v1.primary (Percent.of_percentage 50.))
  ;;

  let menu_item ~intent =
    (* Button CSS reset styles *)
    Css_gen.box_sizing `Border_box
    @> Css_gen.uniform_margin (`Px 0)
    @> Css_gen.uniform_padding (`Px 0)
    @> Css_gen.border ~style:`None ()
    @> Css_gen.color
         (match intent with
          | None -> Skyline_theme_v1.primary
          | Some intent -> intent)
    @> Css_gen.background_color `Inherit
    (* Regular styles *)
    @> Css_gen.flex_container
         ~direction:`Row
         ~justify_content:`Flex_start
         ~align_items:`Center
         ~row_gap:(`Px 4)
         ~column_gap:(`Px 4)
         ()
    @> Css_gen.margin ~top:(`Px 0) ~right:(`Px 4) ~bottom:(`Px 0) ~left:(`Px 4) ()
    @> Css_gen.uniform_padding (`Px 4)
    @> Css_gen.border_radius (`Px 4)
  ;;

  let menu_item_active ~intent =
    Css_gen.color Skyline_theme_v1.background
    @> Css_gen.background_color
         (match intent with
          | None -> Skyline_theme_v1.accent
          | Some intent -> intent)
  ;;

  let menu_item_disabled =
    Css_gen.color
      (Skyline_theme_v1.ramp Skyline_theme_v1.primary (Percent.of_percentage 50.))
    @> Css_gen.create ~field:"cursor" ~value:"not-allowed"
  ;;

  let menu_item_title =
    Css_gen.box_sizing `Border_box
    @> Css_gen.uniform_margin (`Px 0)
    @> Css_gen.uniform_padding (`Px 0)
    @> Css_gen.max_width (`Px 300)
    @> Css_gen.flex_item ~grow:1. ()
    @> Css_gen.text_align `Left
    @> Css_gen.overflow `Hidden
    @> Css_gen.create ~field:"text-overflow" ~value:"ellipsis"
    @> Css_gen.white_space `Nowrap
  ;;

  let menu_item_detail ~active ~disabled =
    let color =
      let percent = if disabled then 25. else 50. in
      if active
      then
        Skyline_theme_v1.fade Skyline_theme_v1.background (Percent.of_percentage percent)
      else Skyline_theme_v1.ramp Skyline_theme_v1.primary (Percent.of_percentage 50.)
    in
    Css_gen.box_sizing `Border_box
    @> Css_gen.max_width (`Px 150)
    @> Css_gen.uniform_padding (`Px 0)
    @> Css_gen.margin ~top:(`Px 0) ~right:(`Px 0) ~bottom:(`Px 0) ~left:(`Px 12) ()
    @> Css_gen.flex_item ~grow:1. ()
    @> Css_gen.overflow `Hidden
    @> Css_gen.create ~field:"text-overflow" ~value:"ellipsis"
    @> Css_gen.text_align `Right
    @> Css_gen.white_space `Nowrap
    @> Css_gen.color color
  ;;

  let menu_item_submenu_arrow =
    Css_gen.flex_item ~grow:1. ()
    @> Css_gen.flex_container ~direction:`Row ~justify_content:`Flex_end ()
  ;;
end

module Item = struct
  include Bonsai_web_menu.Item

  module Data = struct
    type t =
      { icon : Codicons.t
      ; title : string
      ; detail : string
      ; intent : Css_gen.Color.t option
      }
    [@@deriving sexp_of]
  end

  type nonrec 'a t = ('a, Data.t) t [@@deriving sexp_of]

  let single
    ?key
    ?(disabled = false)
    ?(icon = Codicons.Blank)
    ?intent
    ?(detail = "")
    ~on_click
    title
    =
    Single
      { key = Option.value key ~default:title
      ; disabled
      ; item = { Data.icon; title; detail; intent }
      ; on_click
      }
  ;;

  let section ?title items = Section { title; items }

  let submenu ?key ?(disabled = false) ?(icon = Codicons.Blank) ?intent ~title items =
    Submenu
      { key = Option.value key ~default:title
      ; item = { Data.icon; title; detail = ""; intent }
      ; items = (if disabled then [] else items)
      }
  ;;

  module Expert = struct
    let map_actions = map_actions
  end
end

type 'a t = 'a Item.t list [@@deriving sexp_of]

let disable_browser_context_menu_within =
  Vdom.Attr.on_contextmenu (const (Effect.Prevent_default [@alert "-deprecated"]))
;;

let child_menu_container ~submenu_id contents =
  Vdom.Node.div
    ~attrs:
      [ Vdom.Attr.id submenu_id
      ; Vdom.Attr.style Style.menu
      ; disable_browser_context_menu_within
      ]
    contents
;;

let single_menu_item
  ?(attrs = [])
  ?(disabled = false)
  ?(submenu = false)
  ?(detail = "")
  ~icon
  ~intent
  ~on_click
  ~on_mouseenter
  ~active
  title
  =
  let style =
    let and_if cond ~add ~to_ = if cond then Css_gen.combine to_ add else to_ in
    let style = Style.menu_item ~intent in
    let style = and_if disabled ~add:Style.menu_item_disabled ~to_:style in
    let style = and_if active ~add:(Style.menu_item_active ~intent) ~to_:style in
    style
  in
  let right_hand_side =
    if submenu
    then
      [ Vdom.Node.span
          ~attrs:[ Vdom.Attr.style Style.menu_item_submenu_arrow ]
          [ Skyline_icon_v1.component Chevron_right ]
      ]
    else if not (String.is_empty detail)
    then
      [ Skyline_text_v1.span
          ~attrs:[ Vdom.Attr.style (Style.menu_item_detail ~active ~disabled) ]
          detail
      ]
    else []
  in
  Vdom.Node.button
    ~attrs:
      (Vdom.Attr.style style
       :: (if not disabled
           then Vdom.Attr.on_mouseenter (const on_mouseenter)
           else Vdom.Attr.empty)
       :: (if not disabled then Vdom.Attr.on_click (const on_click) else Vdom.Attr.empty)
       :: Vdom.Attr.tabindex (-1)
       :: (if not (String.is_empty detail)
           then Vdom.Attr.title detail
           else Vdom.Attr.empty)
       :: attrs)
    (Skyline_icon_v1.component icon
     :: Skyline_text_v1.span ~attrs:[ Vdom.Attr.style Style.menu_item_title ] title
     :: right_hand_side)
;;

let rec contents'
  ~path_id
  ~set_active_path_rev
  ~current_path_rev
  ~active_path
  (items : unit Item.t list)
  =
  let is_active (item : unit Item.t) =
    match active_path with
    | [ active ] ->
      (match item with
       | Single { key; _ } | Submenu { key; _ } -> String.equal key active
       | _ -> false)
    | _ -> false
  in
  let has_prev_items = ref false in
  List.filter_map items ~f:(function
    | Inert _ -> None (* [Inert] is not supported in v1. *)
    | Single { key; disabled; on_click; item = { title; detail; icon; intent } } as item
      ->
      has_prev_items := true;
      single_menu_item
        ~disabled
        ~icon
        ~intent
        ~detail
        ~on_click
        ~on_mouseenter:(set_active_path_rev (key :: current_path_rev))
        ~active:(is_active item)
        title
      |> Option.some
    | Section { items = []; _ } -> None
    | Section { title; items } ->
      let contents =
        let items =
          contents' ~path_id ~set_active_path_rev ~current_path_rev ~active_path items
        in
        match title with
        | Some title ->
          Skyline_text_v1.span
            ~size:Small
            ~style:Bold
            ~attrs:[ Vdom.Attr.style Style.section_title ]
            title
          :: items
        | None -> items
      in
      if List.is_empty contents
      then None
      else (
        let section =
          Vdom.Node.div
            ~attrs:
              [ Vdom.Attr.style
                  (if !has_prev_items
                   then Css_gen.combine Style.section Style.section_top_border
                   else Style.section)
              ]
            contents
        in
        has_prev_items := true;
        Some section)
    | Submenu { items = []; item = { icon; title; intent; _ }; _ } ->
      has_prev_items := true;
      single_menu_item
        ~disabled:true
        ~submenu:true
        ~icon
        ~intent
        ~on_click:Effect.Ignore
        ~on_mouseenter:Effect.Ignore
        ~active:false
        title
      |> Option.some
    | Submenu { key; item = { icon; title; intent; _ }; items } as item ->
      has_prev_items := true;
      let submenu =
        match active_path with
        | active_key :: active_path when String.equal key active_key ->
          let submenu_id = [%string "%{path_id}/%{key}"] in
          let safe_triangle =
            if List.is_empty active_path
            then
              Bonsai_web_toplayer_private_vdom.For_bonsai_web_menu.safe_triangle
                ~submenu_id
            else Vdom.Attr.empty
          in
          let contents =
            child_menu_container
              ~submenu_id
              (contents'
                 ~path_id
                 ~set_active_path_rev
                 ~current_path_rev:(key :: current_path_rev)
                 ~active_path
                 items)
          in
          Vdom.Attr.combine
            (Bonsai_web_toplayer.vdom_popover
               ~popover_attrs:[ Vdom.Attr.style Style.clear_popover_styles ]
               ~overflow_auto_wrapper:false
               ~position:Right
               ~alignment:Start
               ~offset:{ main_axis = 2.; cross_axis = 0. }
               contents)
            safe_triangle
        | _ -> Vdom.Attr.empty
      in
      let open_submenu = set_active_path_rev (key :: current_path_rev) in
      single_menu_item
        ~attrs:[ submenu ]
        ~submenu:true
        ~icon
        ~intent
        ~on_click:open_submenu
        ~on_mouseenter:open_submenu
        ~active:(is_active item)
        title
      |> Option.some)
;;

let on_keydown ~close ~state (event : Js_of_ocaml.Dom_html.keyboardEvent Js_of_ocaml.Js.t)
  =
  let key_down key =
    Js_of_ocaml.Dom.preventDefault event;
    Js_of_ocaml.Dom_html.stopPropagation event;
    Bonsai_web_menu.key_down state key
  in
  match Js_of_ocaml.Dom_html.Keyboard_code.of_event event with
  | Escape ->
    Js_of_ocaml.Dom.preventDefault event;
    Js_of_ocaml.Dom_html.stopPropagation event;
    close
  | Enter -> key_down `Enter
  | ArrowUp -> key_down `Up
  | ArrowDown -> key_down `Down
  | ArrowLeft -> key_down `Left
  | ArrowRight -> key_down `Right
  | _ -> Effect.Ignore
;;

let contents ~close items graph =
  let items =
    let%arr close and items in
    List.map items ~f:(fun item ->
      Bonsai_web_menu.Item.map_actions item ~f:(fun on_click ->
        let%bind.Effect () = close in
        on_click))
  in
  let state, reset =
    Bonsai.with_model_resetter ~f:(Bonsai_web_menu.component items) graph
  in
  Bonsai.Edge.lifecycle ~on_deactivate:reset graph;
  let%arr path_id = Bonsai.path_id graph
  and close
  and state
  and items in
  let on_keydown =
    Vdom.Attr.Global_listeners.keydown ~phase:Capture ~f:(on_keydown ~close ~state)
  in
  Vdom.Node.div
    ~attrs:[ Vdom.Attr.style Style.menu; disable_browser_context_menu_within; on_keydown ]
    (contents'
       ~path_id
       ~set_active_path_rev:(fun path ->
         Bonsai_web_menu.set_active_path state (List.rev path))
       ~current_path_rev:[]
       ~active_path:(Bonsai_web_menu.active_path state)
       items)
;;

let component' ~position ~alignment items graph =
  let position =
    match%arr position with
    | Skyline_popover_v1.Position.Auto -> Bonsai_web_ui_toplayer.Position.Auto
    | Top -> Top
    | Bottom -> Bottom
    | Left -> Left
    | Right -> Right
  in
  let alignment =
    match%arr alignment with
    | Skyline_popover_v1.Alignment.Center -> Bonsai_web_ui_toplayer.Alignment.Center
    | Start -> Start
    | End -> End
  in
  let visible, set_visible = Bonsai.state `Hidden graph in
  let close =
    let%arr set_visible in
    set_visible `Hidden
  in
  let anchor =
    match%sub visible with
    | `Hidden -> return Vdom.Attr.empty
    | `Virtual anchor ->
      Bonsai_web_ui_toplayer.Popover.always_open_virtual
        ~config:(`This_one (return Style.clear_popover_styles_config))
        ~autoclose:
          (Bonsai_web_ui_toplayer.Autoclose.create
             ~close_on_right_click_outside:
               (Bonsai.return Bonsai_web_ui_toplayer.Close_on_click_outside.Yes)
             ~close
             graph)
        ~position
        ~alignment
        ~overflow_auto_wrapper:(return false)
        ~content:(contents ~close items)
        anchor
        graph;
      return Vdom.Attr.empty
    | `Anchored ->
      Bonsai_web_ui_toplayer.Popover.always_open
        ~config:(`This_one (return Style.clear_popover_styles_config))
        ~autoclose:
          (Bonsai_web_ui_toplayer.Autoclose.create
             ~close_on_right_click_outside:
               (Bonsai.return Bonsai_web_ui_toplayer.Close_on_click_outside.Yes)
             ~close
             graph)
        ~position
        ~alignment
        ~overflow_auto_wrapper:(return false)
        ~content:(contents ~close items)
        graph
  in
  anchor, visible, set_visible
;;

let component
  ?(position_at_cursor = return true)
  ?(on_contextmenu = return true)
  ?(on_click = return false)
  items
  graph
  =
  let anchor, visible, set_visible =
    component'
      ~position:(return Skyline_popover_v1.Position.Bottom)
      ~alignment:(return Skyline_popover_v1.Alignment.Start)
      items
      graph
  in
  let%arr on_contextmenu
  and on_click
  and visible
  and set_visible
  and position_at_cursor
  and anchor in
  let show_at event =
    Js_of_ocaml.Dom.preventDefault event;
    Js_of_ocaml.Dom_html.stopPropagation event;
    match visible, position_at_cursor with
    | `Hidden, true ->
      let get x =
        Js_of_ocaml.Js.Optdef.to_option x
        |> Option.value_map ~f:Js_of_ocaml.Js.float_of_number ~default:0.
      in
      let top = get event##.pageY in
      let left = get event##.pageX in
      set_visible
        (`Virtual
          (Bonsai_web_ui_toplayer.Anchor.of_coordinate
             ~relative_to:`Document
             ~x:left
             ~y:top))
    | `Hidden, false -> set_visible `Anchored
    | `Virtual _, _ | `Anchored, _ -> Effect.Ignore
  in
  Vdom.Attr.many
    [ (* Suppress native context menu *)
      (if on_contextmenu
       then
         Vdom.Attr.on_contextmenu (fun e ->
           Js_of_ocaml.Dom.preventDefault e;
           Effect.Ignore)
       else Vdom.Attr.empty)
    ; (* Show menu on right auxclick. We use auxclick instead of contextmenu because
         contextmenu fires on mousedown on Linux but mouseup on Windows. auxclick fires
         consistently on mouseup across platforms, and only fires if mousedown and mouseup
         occur on the same element (providing built-in cancel-by-dragging-away). *)
      (if on_contextmenu
       then
         Vdom.Attr.on_auxclick (fun e ->
           if e##.button = 2 then show_at e else Effect.Ignore)
       else Vdom.Attr.empty)
    ; (if on_click then Vdom.Attr.on_click show_at else Vdom.Attr.empty)
    ; anchor
    ]
;;

let manual_popover
  ?(position = return Skyline_popover_v1.Position.Bottom)
  ?(alignment = return Skyline_popover_v1.Alignment.Start)
  items
  graph
  =
  let anchor, visible, set_visible = component' ~position ~alignment items graph in
  let show =
    let%arr visible and set_visible in
    match visible with
    | `Hidden -> set_visible `Anchored
    | `Anchored -> Effect.Ignore
    | `Virtual _ -> raise_s [%message "BUG: Please report this to Skyline devs" [%here]]
  in
  anchor, show
;;

let manual_position items graph =
  let _anchor, visible, set_visible =
    component'
      ~position:(return Skyline_popover_v1.Position.Bottom)
      ~alignment:(return Skyline_popover_v1.Alignment.Start)
      items
      graph
  in
  let%arr visible and set_visible in
  fun ~top ~left ->
    match visible with
    | `Hidden | `Virtual _ ->
      set_visible
        (`Virtual
          (Bonsai_web_ui_toplayer.Anchor.of_coordinate
             ~relative_to:`Document
             ~x:left
             ~y:top))
    | `Anchored -> raise_s [%message "BUG: Please report this to Skyline devs" [%here]]
;;
