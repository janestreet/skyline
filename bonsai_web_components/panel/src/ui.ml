open! Core
open! Import
open Vdom.Html_syntax

module Style_config = struct
  type t =
    { container_attr :
        drag_state:[ `Drag_in_progress | `Static ]
        -> direction:[ `Horizontal | `Vertical ]
        -> child_count:int
        -> Attr.t
    ; container_border :
        width:Css_gen.Length.t option
        * color:Css_gen.Color.t option
        * radius:Css_gen.Length.t option
    ; title_attr : [ `Collapsed_vertical | `Collapsed_horizontal | `Expanded ] -> Attr.t
    ; tab_attr :
        active:[ `Active | `Inactive ]
        -> collapsed:[ `Collapsed_vertical | `Collapsed_horizontal | `Expanded ]
        -> Attr.t
    ; tab_badge_attr : Attr.t
    ; divider_style :
        drag_state:[ `Drag_in_progress | `Static ]
        -> border_width:Css_gen.Length.t
           * border_color:Css_gen.Color.t
           * foreground_color:Css_gen.Color.t
           * background_color:Css_gen.Color.t
    ; divider_attr :
        drag_state:[ `Drag_in_progress | `Static ]
        -> direction:[ `Horizontal | `Vertical ]
        -> Attr.t
    ; icon_color : Css_gen.Color.t
    }
  [@@deriving fields ~getters]

  let title_attr_of_layout_direction = function
    | None -> `Expanded
    | Some Logic.Direction.Horizontal -> `Collapsed_horizontal
    | Some Logic.Direction.Vertical -> `Collapsed_vertical
  ;;

  let direction_of_layout_direction = function
    | Logic.Direction.Horizontal -> `Horizontal
    | Logic.Direction.Vertical -> `Vertical
  ;;
end

module Dragging_divider = struct
  type t =
    { index : int
    ; offset : int
    }
  [@@deriving fields ~getters]
end

module Styling =
  [%css
  stylesheet
    {|
      .header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        user-select: none;
      }

      .panel-stack-fixed {
        flex-grow: 1;
        flex-shrink: 1;
        flex-basis: 0;
        overflow: hidden;
      }

      .panel-expanded .chevron-expanded,
      .panel-collapsed .chevron-collapsed {
        display: block;
      }

      .panel-collapsed .chevron-expanded,
      .panel-expanded .chevron-collapsed {
        display: none;
      }

      .panel-collapsed .panel-expanded .chevron-expanded,
      .panel-expanded .panel-collapsed .chevron-collapsed {
        display: block;
      }

      .tab-stack {
        flex-grow: 1;

        display: flex;
        flex-direction: column;
        align-items: stretch;
      }

      .tab-stack-content {
        flex: 1 1 0;

        display: grid;
        grid-template-columns: minmax(0, 1fr);
        grid-template-rows: minmax(0, 1fr);

        overflow: hidden;
      }

      .panel-stack-horizontal > .panel-collapsed .tab-stack {
        flex-direction: column;
        writing-mode: vertical-lr;
      }

      .panel-expanded .tab-stack .tab-collapsed,
      .panel-stack-vertical > .panel-collapsed .tab-stack .tab-collapsed {
        display: none;
      }

      .panel-expanded .tab-stack-content {
        display: grid;
        flex-grow: 1;
      }

      .panel-collapsed .tab-stack-content,
      .panel-stack-horizontal > .panel-collapsed .tab-stack .tab-expanded {
        display: none;
      }

      .panel-stack-horizontal > .panel-collapsed .tab-stack .tab-collapsed {
        display: block;
      }

      .expanded {
        height: 100%;
      }

      .wrapper {
        display: flex;
        flex-direction: column;
        height: 100%;
        flex-grow: 1;
        overflow: hidden;
      }
    |}]

module Content = struct
  type 'a t = 'a Bonsai.t -> local_ Bonsai.graph -> Node.t Bonsai.t
end

type 'a flex_stack =
  | Horizontal_fixed of 'a Bonsai_web_panel_config.t
  | Vertical_fixed of 'a Bonsai_web_panel_config.t
  | Vertical_variable of 'a Bonsai_web_panel_config.t

let to_flex_stack (config : 'a Bonsai_web_panel_config.t) =
  match config.config with
  (* Internal type structure to make dealing with horizontal and vertical configs easier.
  *)
  | Content _ -> None
  | Horizontal_fixed _ -> Horizontal_fixed config |> Some
  | Vertical_fixed _ -> Vertical_fixed config |> Some
  | Vertical_variable _ -> Vertical_variable config |> Some
  | Tabbed _ -> None
;;

let flex_stack_children_to_float = function
  | Horizontal_fixed config | Vertical_fixed config | Vertical_variable config ->
    Bonsai_web_panel_config.child_float_layouts config |> Option.value_exn
;;

let flex_stack_child_configs config =
  Bonsai_web_panel_config.child_configs config |> Option.value_exn
;;

let container
  ~grid_template
  ~layout_direction
  ~parent_layout_type
  ~user_select
  ~is_being_dragged
  ~container_attr
  children
  =
  let base_grid_styles =
    [%css
      {|
        display: grid;
        user-select: %{user_select};
        height: 100%;
        width: 100%;

        /* to make client bounding box more accurate */
        box-sizing: border-box;
      |}]
  in
  let panel_stack_classes = Attr.classes (List.filter_opt [ Some "panel-stack" ]) in
  let layout_styling_attrs =
    Attr.many
      [ (match layout_direction with
         | Logic.Direction.Horizontal -> Styling.panel_stack_horizontal
         | Logic.Direction.Vertical -> Styling.panel_stack_vertical)
      ; (match parent_layout_type with
         | Logic.Parent_layout_type.Fixed -> Styling.panel_stack_fixed
         | Logic.Parent_layout_type.Variable -> Attr.empty)
      ]
  in
  let grid_template_attr =
    (* Note: something in how bonsai does css makes this cause a ton of relayouts when
       using ppx_css. Doing it this way is ugly but efficient. *)
    match layout_direction with
    | Horizontal ->
      Attr.style
        (Css_gen.of_string_css_exn ("grid-template-columns: " ^ grid_template ^ " ;"))
    | Vertical ->
      Attr.style
        (Css_gen.of_string_css_exn ("grid-template-rows: " ^ grid_template ^ " ;"))
  in
  let style_config_container_attr =
    container_attr
      ~drag_state:(if is_being_dragged then `Drag_in_progress else `Static)
      ~direction:
        (match layout_direction with
         | Horizontal -> `Horizontal
         | Vertical -> `Vertical)
      ~child_count:(List.length children)
  in
  {%html|
    <div
      %{base_grid_styles}
      %{panel_stack_classes}
      %{layout_styling_attrs}
      %{grid_template_attr}
      %{style_config_container_attr}
    >
      *{children}
    </div>
  |}
;;

let grid_template_from_sizes =
  let size_to_css = function
    | Bonsai_web_panel_config.Size.Px px -> sprintf "%2dpx" px
    | Bonsai_web_panel_config.Size.Percent pct -> sprintf "%2ffr" (Percent.to_mult pct)
  in
  function
  | Logic.Child_sizes.Horizontal_fixed sizes
  | Vertical_fixed sizes
  | Vertical_variable sizes ->
    List.map
      ~f:(function
        | None -> "1.55rem"
        | Some (~size, ..) -> size_to_css size)
      sizes
    |> String.concat ~sep:" "
;;

module Drag_handling = struct
  let capture_pointer e =
    Js_of_ocaml.Js.Opt.iter e##.target (fun target ->
      Js_of_ocaml.Js.Unsafe.meth_call
        target
        "setPointerCapture"
        [| e##.pointerId
           |> Int.to_float
           |> Js_of_ocaml.Js.number_of_float
           |> Js_of_ocaml.Js.Unsafe.coerce
        |])
  ;;

  let calculate_parent_rect_and_offset ~layout_direction ~sizes e =
    let target = Js.Opt.to_option e##.target in
    let%map.Option target in
    let rect = target##getBoundingClientRect in
    let size =
      match layout_direction with
      | Logic.Direction.Horizontal -> rect##.width
      | Vertical -> rect##.height
    in
    let offset =
      match layout_direction with
      | Horizontal -> e##.offsetX
      | Vertical -> e##.offsetY
    in
    let parent = target##closest (Js.string ".panel-stack") in
    let parent = Js.Opt.get parent (fun () -> target) in
    let parent_rect = parent##getBoundingClientRect in
    let parent_pos =
      match layout_direction with
      | Horizontal -> parent_rect##.left
      | Vertical -> parent_rect##.top
    in
    let parent_size =
      match layout_direction with
      | Horizontal -> parent_rect##.width
      | Vertical -> parent_rect##.height
    in
    let parent_size =
      let approx_spacing = 3.2 *. Float.of_int (List.length sizes) in
      Js.float_of_number parent_size -. approx_spacing |> Float.to_int
    in
    ( (parent_pos |> Js.float_of_number |> Int.of_float, parent_size)
    , Js.to_float size -. Js.to_float offset |> Float.to_int )
  ;;

  let create_pointerdown_handler
    ~layout_direction
    ~sizes
    ~is_expanded
    ~i
    ~set_dragging_divider
    ~set_parent_rect
    e
    =
    Effect.Many
      [ capture_pointer e |> Effect.return
      ; (Effect.Prevent_default [@alert "-deprecated"])
      ; Effect.Stop_propagation
      ; (let should_drag = e##.button = 0 && is_expanded in
         if should_drag
         then (
           let parent_rect, offset =
             let parentrect_offset =
               calculate_parent_rect_and_offset ~layout_direction ~sizes e
             in
             Option.map ~f:fst parentrect_offset, Option.map ~f:snd parentrect_offset
           in
           let create_drag_state offset = { Dragging_divider.index = i; offset } in
           Effect.Many
             [ set_dragging_divider (Option.map ~f:create_drag_state offset)
             ; set_parent_rect parent_rect
             ])
         else Effect.Ignore)
      ]
  ;;

  let create_pointermove_handler
    ~layout_direction
    ~drag_offset
    ~parent_pos
    ~parent_size
    ~update_size
    ~panel_id
    (e : Js_of_ocaml.Dom_html.pointerEvent Js_of_ocaml.Js.t)
    =
    match drag_offset with
    | Some drag_offset ->
      Effect.Many
        [ (Effect.Prevent_default [@alert "-deprecated"])
        ; Effect.Stop_propagation
        ; (let offset =
             Option.map
               (Js.Opt.to_option e##.currentTarget)
               ~f:(fun _ ->
                 let parent_pos = Option.value_exn parent_pos in
                 let mouse_pos =
                   ((match layout_direction with
                     | Logic.Direction.Horizontal -> e##.clientX
                     | Vertical -> e##.clientY)
                    |> Js.to_float
                    |> Float.to_int)
                   + drag_offset
                 in
                 let dpos = mouse_pos - parent_pos in
                 dpos)
           in
           Option.value_map
             ~f:(fun offset ->
               let parent_size = Option.value_exn parent_size in
               update_size ~offset ~parent_size panel_id)
             ~default:Effect.Ignore
             offset)
        ]
    | None -> Effect.Ignore
  ;;

  let create_pointerup_handler ~set_dragging_divider _ =
    Effect.Many
      [ (Effect.Prevent_default [@alert "-deprecated"])
      ; Effect.Stop_propagation
      ; set_dragging_divider None
      ]
  ;;
end

let divider
  ~sizes
  ~i
  ~panel_id
  ~drag_offset
  ~set_dragging_divider
  ~parent_pos
  ~parent_size
  ~set_parent_rect
  ~update_size
  ~layout_direction
  ~is_expanded
  ~divider_style
  ~divider_attr
  =
  let is_being_dragged = Option.is_some drag_offset in
  let hitbox_scale = 1.5 in
  let ~border_width, ~border_color, ~foreground_color, ~background_color =
    divider_style ~drag_state:(if is_being_dragged then `Drag_in_progress else `Static)
  in
  let divider_attr =
    divider_attr
      ~drag_state:(if is_being_dragged then `Drag_in_progress else `Static)
      ~direction:(Style_config.direction_of_layout_direction layout_direction)
  in
  let dot_attrs ~offset ~count =
    let dot_size = 3. in
    let count = Float.of_int (count - 1) in
    let position = Float.of_int offset -. (count *. 0.5) in
    let cx =
      (match layout_direction with
       | Logic.Direction.Horizontal -> 0.
       | Vertical -> position *. dot_size)
      |> Float.to_string_hum ~decimals:1
    in
    let cy =
      (match layout_direction with
       | Logic.Direction.Vertical -> 0.
       | Horizontal -> position *. dot_size)
      |> Float.to_string_hum ~decimals:1
    in
    [ Attr.class_ "resize-dot"
    ; Attr.create "cx" cx
    ; Attr.create "cy" cy
    ; Attr.create "r" "1"
    ; Attr.create "fill" (Css_gen.Color.to_string_css foreground_color)
    ; [%css {|transform: translate(50%, 50%);|}]
    ]
  in
  let on_pointerdown =
    Drag_handling.create_pointerdown_handler
      ~layout_direction
      ~sizes
      ~is_expanded
      ~i
      ~set_dragging_divider
      ~set_parent_rect
  in
  let on_pointermove =
    Drag_handling.create_pointermove_handler
      ~layout_direction
      ~drag_offset
      ~parent_pos
      ~parent_size
      ~update_size
      ~panel_id
  in
  let on_pointerup = Drag_handling.create_pointerup_handler ~set_dragging_divider in
  let cursor_and_scale_styles =
    let cursor =
      match layout_direction with
      | Horizontal -> "col-resize"
      | Vertical -> "row-resize"
    in
    let scale =
      match layout_direction with
      | Horizontal -> Float.to_string_hum ~decimals:2 hitbox_scale ^ ", 1"
      | Vertical -> "1, " ^ Float.to_string_hum ~decimals:2 hitbox_scale
    in
    [%css
      {|
        transform-origin: bottom right;
        transform: scale(%{scale});
        cursor: %{cursor};
        display: grid;
        overflow: visible;
        flex: 0 0 auto;
      |}]
  in
  let pointer_event_handlers =
    Attr.many
      [ Attr.on_pointerdown on_pointerdown
      ; Attr.on_pointerup on_pointerup
      ; Attr.on_pointermove on_pointermove
      ]
  in
  Node.div
    ~attrs:[ cursor_and_scale_styles; pointer_event_handlers; divider_attr ]
    [ (let svg_size_and_scale_styles =
         let divider_width = "6px" in
         let width =
           match layout_direction with
           | Horizontal -> divider_width
           | Vertical -> "100%"
         and height =
           match layout_direction with
           | Horizontal -> "100%"
           | Vertical -> divider_width
         and scale =
           match layout_direction with
           | Horizontal -> (1. /. hitbox_scale |> Float.to_string_hum ~decimals:2) ^ ", 1"
           | Vertical -> "1, " ^ (1. /. hitbox_scale |> Float.to_string_hum ~decimals:2)
         in
         [%css
           {|
             height: %{height};
             width: %{width};
             flex-shrink: 0;
             flex-grow: 0;
             transform-origin: bottom right;
             transform: scale(%{scale});
           |}]
       in
       let svg_border_styles =
         let border_left_width, border_top_width =
           match layout_direction with
           | Horizontal -> border_width, `Px 0
           | Vertical -> `Px 0, border_width
         in
         [%css
           {|
             border-left: %{border_left_width#Css_gen.Length} solid
               %{border_color#Css_gen.Color};
             border-top: %{border_top_width#Css_gen.Length} solid
               %{border_color#Css_gen.Color};
           |}]
       in
       let rect_fill_styles =
         [ [%css
             {|
               user-select: none;
               fill: %{background_color#Css_gen.Color};
             |}]
         ; A.create "height" "100%"
         ; A.create "width" "100%"
         ]
       in
       [%html.Virtual_dom_svg
         {|
           <svg %{svg_size_and_scale_styles} %{svg_border_styles}>
             <rect *{rect_fill_styles}></rect>
             <circle *{dot_attrs ~offset:0 ~count:4}></circle>
             <circle *{dot_attrs ~offset:1 ~count:4}></circle>
             <circle *{dot_attrs ~offset:2 ~count:4}></circle>
             <circle *{dot_attrs ~offset:3 ~count:4}></circle>
           </svg>
         |}])
    ]
;;

let chevron_buttons ?(on_click = Effect.Ignore) icon_color =
  let open Codicons in
  let cursor_style =
    [%css
      {|
        cursor: pointer;
        fill: currentcolor;
      |}]
  in
  let collapsed_svg =
    Codicons.svg
      ~extra_attrs:
        [ Styling.chevron_collapsed; cursor_style; Attr.on_click (fun _ -> on_click) ]
      ~color:icon_color
      ~size:(`Em_float 1.)
      Chevron_right
  in
  let expanded_svg =
    Codicons.svg
      ~extra_attrs:
        [ Styling.chevron_expanded; cursor_style; Attr.on_click (fun _ -> on_click) ]
      ~color:icon_color
      ~size:(`Em_float 1.)
      Chevron_down
  in
  {%html|<> %{collapsed_svg} %{expanded_svg} </>|}
;;

let config_editor_button ~open_open_config_editor ~icon_color =
  match%sub open_open_config_editor with
  | None -> Bonsai.return None
  | Some open_open_config_editor ->
    let%arr icon_color and open_open_config_editor in
    let click_handler =
      Attr.on_click (fun _ ->
        Effect.Many
          [ (Effect.Prevent_default [@alert "-deprecated"]); Effect.Stop_propagation ])
    in
    let gear_svg =
      Codicons.svg
        ~extra_attrs:[ [%css {|fill: currentcolor;|}] ]
        ~color:icon_color
        ~size:(`Em_float 1.)
        Codicons.Gear
    in
    {%html|<div %{click_handler} %{open_open_config_editor}>%{gear_svg}</div>|}
    |> Option.return
;;

let accordion
  ~collapsed
  ~toggle_expanded
  ~title
  ~content
  ~title_attr
  ~icon_color
  ~config_editor
  ~custom_header
  =
  let expanded = Option.is_none collapsed in
  let chevron_button = chevron_buttons icon_color in
  let title_attr_value =
    Attr.many
      [ title_attr (Style_config.title_attr_of_layout_direction collapsed)
      ; (match collapsed with
         | None -> A.empty
         | Some Logic.Direction.Vertical ->
           [%css
             {|
               writing-mode: horizontal-tb;
               flex-grow: 1;
             |}]
         | Some Logic.Direction.Horizontal ->
           [%css
             {|
               writing-mode: vertical-lr;
               flex-grow: 1;
             |}])
      ]
  in
  let title_flex_grow =
    if Option.is_none custom_header then Some [%css {|flex-grow: 1;|}] else None
  in
  let title_div = {%html|<div class="title-text" ?{title_flex_grow}>%{title}</div>|} in
  let custom_header =
    let%map.Option custom_header in
    {%html|
      <div
        style="
          flex-grow: 1;
          align-self: stretch;
          display: grid;
          align-items: center;
          grid-template-columns: 1fr;
          grid-template-rows: auto;
        "
      >
        %{custom_header}
      </div>
    |}
  in
  let header =
    {%html|
      <div %{Styling.header} %{Attr.on_click toggle_expanded} %{title_attr_value}>
        %{chevron_button} %{title_div} ?{custom_header} ?{config_editor}
      </div>
    |}
  in
  let expanded_styling = if expanded then Styling.expanded else Attr.empty in
  {%html|
    <div %{expanded_styling} %{Styling.wrapper}>
      %{header} ?{Option.some_if expanded content}
    </div>
  |}
;;

type 'a recurse_state_record =
  { config : 'a Bonsai_web_panel_config.t
  ; inject : 'a Logic.Action.t -> unit Effect.t
  ; style_config : Style_config.t
  ; collapsed : Logic.Direction.t option
  }

type 'a recurse_state = 'a recurse_state_record Bonsai.t

let wrap_recurse_state ~config ~inject ~style_config ~collapsed : 'a recurse_state =
  let%arr config and inject and style_config and collapsed in
  { config; inject; style_config; collapsed }
;;

let recurse_state_config (recurse_state : 'a recurse_state) =
  let%arr { config; _ } = recurse_state in
  config
;;

let recurse_state_inject (recurse_state : 'a recurse_state) =
  let%arr { inject; _ } = recurse_state in
  inject
;;

let recurse_state_style_config (recurse_state : 'a recurse_state) =
  let%arr { style_config; _ } = recurse_state in
  style_config
;;

let recurse_state_collapsed (recurse_state : 'a recurse_state) =
  let%arr { collapsed; _ } = recurse_state in
  collapsed
;;

module Stack_rendering = struct
  let create_flex_direction_style flex_stack_config =
    match flex_stack_config with
    | Horizontal_fixed _ -> "row"
    | Vertical_fixed _ | Vertical_variable _ -> "column"
  ;;

  let create_panel_style ~child_layouts_length ~expanded ~container_border =
    let expansion_style =
      if child_layouts_length = 1
      then Attr.empty
      else if expanded
      then Styling.panel_expanded
      else Styling.panel_collapsed
    in
    let ~width, ~color, ~radius = container_border in
    let width = Option.value ~default:(`Px 0) width in
    let color = Option.value ~default:(`Hex "#000") color in
    let radius = Option.value ~default:(`Px 0) radius in
    let border_style =
      [%css
        {|
          border: %{width#Css_gen.Length} solid %{color#Css_gen.Color};
          border-radius: %{radius#Css_gen.Length};
        |}]
    in
    [ expansion_style; border_style ]
  ;;

  let create_child_content_with_title
    ~title
    ~child
    ~collapsed
    ~toggle_expanded
    ~title_attr
    ~icon_color
    ~config_editor
    ~custom_header
    =
    Option.value_map
      title
      ~f:(fun title ->
        let accordion_content =
          accordion
            ~collapsed
            ~toggle_expanded
            ~title:{%html|#{title}|}
            ~content:child
            ~title_attr
            ~icon_color
            ~config_editor
            ~custom_header
        in
        let content_with_title =
          {%html|
            <div style="display: flex; flex-grow: 1; overflow: hidden">
              %{accordion_content}
            </div>
          |}
        in
        Some (~content_with_title, ~custom_header:None))
      ~default:
        (Some
           ( ~content_with_title:{%html|<div style="display: flex; flex-grow: 1; overflow: hidden">%{child}</div>|}
           , (* If the custom header isn't used in the child, bubble it up to the parent. *)
           ~custom_header ))
  ;;

  let create_child_divider
    ~has_divider
    ~index
    ~size_values
    ~i
    ~panel_id
    ~drag_offset
    ~update_size
    ~set_dragging_divider
    ~layout_direction
    ~layout
    ~divider_style
    ~divider_attr
    ~set_parent_rect
    ~parent_rect
    =
    Option.some_if
      (has_divider ~index)
      (divider
         ~sizes:size_values
         ~i
         ~panel_id
         ~drag_offset
         ~update_size
         ~set_dragging_divider
         ~layout_direction
         ~is_expanded:(Bonsai_web_panel_config.Child_layout.expanded layout)
         ~divider_style
         ~divider_attr
         ~set_parent_rect
         ~parent_pos:(Option.map ~f:fst parent_rect)
         ~parent_size:(Option.map ~f:snd parent_rect))
  ;;

  let create_child_view
    ~index
    ~key:i
    ~panel_id
    ~data:((child, config_editor, custom_header), layout)
    ~dragging_divider
    ~layout_direction
    ~flex_stack_config
    ~child_layouts
    ~container_border
    ~has_divider
    ~size_values
    ~update_size
    ~set_dragging_divider
    ~divider_style
    ~divider_attr
    ~set_parent_rect
    ~parent_rect
    ~toggle_expanded
    ~title_attr
    ~icon_color
    =
    let drag_offset =
      Option.value_map
        ~f:(fun di ->
          if Dragging_divider.index di |> Int.equal i
          then Some (Dragging_divider.offset di)
          else None)
        ~default:None
        dragging_divider
    in
    let collapsed =
      if Bonsai_web_panel_config.Child_layout.expanded layout
      then None
      else Some layout_direction
    in
    let expanded = Option.is_none collapsed in
    let flex_direction = create_flex_direction_style flex_stack_config in
    let expansion_style, border_style =
      let panel_styles =
        create_panel_style
          ~child_layouts_length:(Map.length child_layouts)
          ~expanded
          ~container_border
      in
      match panel_styles with
      | [ expansion; border ] -> expansion, border
      | _ -> failwith "create_panel_style should return exactly 2 attributes"
    in
    let title = Bonsai_web_panel_config.Child_layout.title layout in
    let content_with_title, custom_header =
      match
        create_child_content_with_title
          ~title
          ~child
          ~collapsed
          ~toggle_expanded:(fun _ -> toggle_expanded panel_id)
          ~title_attr
          ~icon_color
          ~config_editor
          ~custom_header
      with
      | None -> None, None
      | Some (~content_with_title, ~custom_header) ->
        Some content_with_title, custom_header
    in
    let child_divider =
      create_child_divider
        ~has_divider
        ~index
        ~size_values
        ~i
        ~drag_offset
        ~update_size
        ~set_dragging_divider
        ~layout_direction
        ~layout
        ~divider_style
        ~divider_attr
        ~set_parent_rect
        ~parent_rect
        ~panel_id
    in
    let base_css =
      [%css
        {|
          display: flex;
          flex-direction: %{flex_direction};
          overflow: hidden;
          align-items: stretch;
        |}]
    in
    let children = [ content_with_title; child_divider ] |> List.filter_opt in
    ( {%html|<div %{base_css} %{expansion_style} %{border_style}>*{children}</div>|}
    , custom_header )
  ;;
end

(** A stack of panels. Should never be called with a single [Content] *)
let fixed_stack
  ~(recurse :
      'a recurse_state
      -> local_ Bonsai.graph
      -> (Node.t * A.t option * Node.t option) Bonsai.t)
  (recurse_state : 'a recurse_state)
  (local_ graph)
  : (view:Node.t * custom_header:Node.t option) Bonsai.t
  =
  let config = recurse_state_config recurse_state in
  let inject = recurse_state_inject recurse_state in
  let collapsed = recurse_state_collapsed recurse_state in
  let style_config = recurse_state_style_config recurse_state in
  let%sub flex_stack_config =
    Bonsai.map ~f:(fun config -> to_flex_stack config |> Option.value_exn) config
  in
  let layout_direction =
    let%arr config in
    Logic.Direction.of_config_exn config.config
  in
  let children_content (children : 'a Bonsai_web_panel_config.t list Bonsai.t) =
    let children_by_id =
      let%arr children and flex_stack_config in
      let child_layouts = flex_stack_children_to_float flex_stack_config in
      let children = List.zip_exn children child_layouts in
      List.filter_map children ~f:(fun (child, layout) ->
        if Bonsai_web_panel_config.Child_layout.hidden layout |> not
        then Some (Bonsai_web_panel_config.panel_id child, (child, layout))
        else None)
      |> Map.of_alist_exn (module Bonsai_web_panel_config.Panel_id)
    in
    let children_content =
      Bonsai.assoc
        (module Bonsai_web_panel_config.Panel_id)
        children_by_id
        ~f:(fun panel_id child ->
          let%sub content, layout = child in
          fun graph ->
            let inject =
              let%arr panel_id and inject in
              fun action -> inject (Logic.Action.Update_child_config (~panel_id, ~action))
            in
            let recurse_state =
              match%sub collapsed with
              | None ->
                wrap_recurse_state
                  ~config:content
                  ~inject
                  ~style_config
                  ~collapsed:
                    (let%arr layout_direction and layout in
                     if not (Bonsai_web_panel_config.Child_layout.expanded layout)
                     then Some layout_direction
                     else None)
              | Some _ ->
                wrap_recurse_state ~config:content ~inject ~style_config ~collapsed
            in
            let%sub view, open_open_config_editor, custom_header =
              recurse recurse_state graph
            in
            let%sub { icon_color; _ } = style_config in
            let config_editor_button =
              config_editor_button ~icon_color ~open_open_config_editor
            in
            let%arr view and config_editor_button and layout and custom_header in
            (view, config_editor_button, custom_header), config, layout)
        graph
    in
    children_content
  in
  let dragging_divider, inject_dragging_divider =
    Bonsai.state_machine
      ~default_model:(None : Dragging_divider.t option)
      ~apply_action:(fun _ctx _model -> function
        | `Set_dragging_divider divider -> divider)
      graph
  in
  let child_configs = Bonsai.map ~f:flex_stack_child_configs config in
  let parent_rect, set_parent_rect = Bonsai.state_opt graph in
  let%arr dragging_divider
  and inject_dragging_divider
  and update_model = inject
  and content = children_content child_configs
  and child_sizes = Logic.Child_sizes.of_config config
  and config
  and child_configs
  and flex_stack_config
  and { Style_config.title_attr
      ; divider_style
      ; divider_attr
      ; container_attr
      ; container_border
      ; icon_color
      ; _
      }
    =
    recurse_state_style_config recurse_state
  and parent_rect
  and set_parent_rect
  and layout_direction in
  let parent_layout_type = Logic.Parent_layout_type.of_config_exn config.config in
  let child_layouts = Map.map ~f:(fun (_, _, child_layout) -> child_layout) content in
  let child_layouts_in_config_order =
    List.filter_map child_configs ~f:(fun child ->
      Map.find child_layouts (Bonsai_web_panel_config.panel_id child))
  in
  let has_divider =
    Logic.child_has_divider
      ~child_layouts:child_layouts_in_config_order
      ~parent_layout_type
  in
  let size_values =
    List.map
      ~f:Bonsai_web_panel_config.Child_layout.current_size
      child_layouts_in_config_order
  in
  let set_dragging_divider divider =
    inject_dragging_divider (`Set_dragging_divider divider)
  in
  let user_select =
    Option.value_map ~f:(fun _ -> "none") ~default:"auto" dragging_divider
  in
  let children_child_layouts =
    Map.map ~f:(fun (child, _, child_layout) -> child, child_layout) content
  in
  let toggle_expanded_by_panel_id panel_id =
    update_model (Logic.Action.Toggle_expanded panel_id)
  in
  let update_size_by_panel_id ~offset ~parent_size panel_id =
    update_model (Logic.Action.Update_size (~panel_id, ~offset, ~parent_size))
  in
  let child_configs_list = child_configs in
  let child_view
    ~index
    ~key:i
    ~panel_id
    ~data:((child, config_editor, custom_header), layout)
    =
    Stack_rendering.create_child_view
      ~index
      ~key:i
      ~panel_id
      ~data:((child, config_editor, custom_header), layout)
      ~dragging_divider
      ~layout_direction
      ~flex_stack_config
      ~child_layouts
      ~container_border
      ~has_divider
      ~size_values
      ~update_size:update_size_by_panel_id
      ~set_dragging_divider
      ~divider_style
      ~divider_attr
      ~set_parent_rect
      ~parent_rect
      ~toggle_expanded:toggle_expanded_by_panel_id
      ~title_attr
      ~icon_color
  in
  let grid_template = grid_template_from_sizes (Option.value_exn child_sizes) in
  let children, custom_header =
    let children, custom_headers =
      List.filter
        ~f:(fun { Bonsai_web_panel_config.panel_id; _ } ->
          Map.mem children_child_layouts panel_id)
        child_configs_list
      |> List.mapi ~f:(fun index child ->
        let panel_id = Bonsai_web_panel_config.panel_id child in
        let data = Map.find_exn children_child_layouts panel_id in
        child_view ~index ~key:index ~panel_id ~data)
      |> List.unzip
    in
    children, List.filter_opt custom_headers |> List.hd
  in
  ( ~view:(container
             ~grid_template
             ~parent_layout_type
             ~layout_direction
             ~user_select
             ~is_being_dragged:(Option.is_some dragging_divider)
             ~container_attr
             children)
  , ~custom_header )
;;

let tabbed_stack
  ~(recurse :
      'a recurse_state
      -> local_ Bonsai.graph
      -> (Node.t * A.t option * Node.t option) Bonsai.t)
  ~tabs
  recurse_state
  graph
  =
  let%sub { Bonsai_web_panel_config.Tabbed.tabs; current_tab } = tabs in
  let inject = recurse_state_inject recurse_state in
  let style_config = recurse_state_style_config recurse_state in
  let collapsed = recurse_state_collapsed recurse_state in
  let content =
    let config =
      let%arr tabs and current_tab in
      Nonempty_list.nth_exn tabs current_tab |> fst
    in
    let inject =
      let%arr inject and tabs and current_tab in
      fun action ->
        let current_tab_panel_id =
          Nonempty_list.nth_exn tabs current_tab
          |> fst
          |> Bonsai_web_panel_config.panel_id
        in
        inject
          (Logic.Action.Update_child_config (~panel_id:current_tab_panel_id, ~action))
    in
    let recurse_state = wrap_recurse_state ~config ~inject ~style_config ~collapsed in
    recurse recurse_state graph
  in
  let%sub content_view, open_open_config_editor, custom_header = content in
  let%sub { icon_color; tab_attr; tab_badge_attr; title_attr; _ } = style_config in
  let config_editor_button = config_editor_button ~icon_color ~open_open_config_editor in
  let%arr tabs
  and inject
  and collapsed
  and current_tab
  and content_view
  and icon_color
  and tab_attr
  and tab_badge_attr
  and title_attr
  and config_editor_button
  and custom_header
  and theme = View.Theme.current graph in
  let toggle_expand = inject (Logic.Action.Bubble Logic.Event.Toggle_expanded) in
  let chevron_button = chevron_buttons icon_color ~on_click:toggle_expand in
  let tab_header_flex_style =
    [%css
      {|
        display: flex;
        flex-direction: row;
        align-items: center;
        user-select: none;
      |}]
  in
  let collapsed_state_title_attr =
    title_attr (Style_config.title_attr_of_layout_direction collapsed)
  in
  let tab_elements =
    Nonempty_list.mapi tabs ~f:(fun i (_, name) ->
      let inactive_tab_expanded_style =
        if current_tab = i then Attr.empty else Styling.tab_expanded
      in
      let tab_click_handler =
        Attr.on_click (fun _ ->
          let tab_panel_id =
            Nonempty_list.nth_exn tabs i |> fst |> Bonsai_web_panel_config.panel_id
          in
          if i = current_tab
          then inject (Logic.Action.Toggle_expanded tab_panel_id)
          else
            inject
              (Logic.Action.Change_tab (~panel_id:tab_panel_id, ~trigger_collapse:true)))
      in
      {%html|
        <div
          %{tab_attr
              ~active:(if current_tab = i then `Active else `Inactive)
              ~collapsed:
                (Style_config.title_attr_of_layout_direction collapsed)}
          %{inactive_tab_expanded_style}
          %{tab_click_handler}
        >
          <div class="title-text">#{name}</div>
        </div>
      |})
    |> Nonempty_list.to_list
  in
  let badge_text = "+" ^ (Nonempty_list.length tabs - 1 |> string_of_int) in
  let badge = View.badge ~attrs:[ tab_badge_attr ] theme badge_text in
  let badge_element = {%html|<div %{Styling.tab_collapsed}>%{badge}</div>|} in
  let custom_header =
    let%map.Option custom_header in
    {%html|
      <div
        style="
          flex-grow: 1;
          align-self: stretch;
          display: grid;
          align-items: center;
          grid-template-columns: 1fr;
          grid-template-rows: auto;
        "
      >
        %{custom_header}
      </div>
    |}
  in
  let config_editor_button =
    let%map.Option config_editor_button in
    let spacing_attr =
      if Option.is_none custom_header
      then
        Some
          [%css
            {|
              flex-grow: 1;
              display: flex;
              justify-content: flex-end;
            |}]
      else None
    in
    {%html|<div ?{spacing_attr}>%{config_editor_button}</div>|}
  in
  let header_children =
    (chevron_button :: tab_elements)
    @ [ badge_element ]
    @ Option.to_list custom_header
    @ Option.to_list config_editor_button
  in
  let header_element =
    {%html|
      <div %{tab_header_flex_style} %{collapsed_state_title_attr}>
        *{header_children}
      </div>
    |}
  in
  let content_element =
    match collapsed with
    | None -> Some {%html|<div %{Styling.tab_stack_content}>%{content_view}</div>|}
    | Some _ -> None
  in
  {%html|<div %{Styling.tab_stack}>%{header_element} ?{content_element}</div>|}
;;

let stack
  ?open_config_editor
  ?custom_header
  ~(content : 'a Content.t)
  ~(recurse :
      'a recurse_state
      -> local_ Bonsai.graph
      -> (Node.t * A.t option * Node.t option) Bonsai.t)
  (recurse_state : 'a recurse_state)
  (local_ graph)
  : (Node.t * A.t option * Node.t option) Bonsai.t
  =
  let config = recurse_state_config recurse_state in
  match%sub config with
  | { config = Content c; _ } ->
    let inject = recurse_state_inject recurse_state in
    let open_open_config_editor =
      let%bind.Option open_config_editor in
      open_config_editor
        ~update:
          (let%arr inject in
           fun content_config -> inject (Logic.Action.Set_content content_config))
        c
        graph
      |> Option.return
    in
    let collapsed = recurse_state_collapsed recurse_state in
    let%arr content = content c graph
    and open_open_config_editor = Bonsai.transpose_opt open_open_config_editor
    and { Style_config.container_attr; _ } = recurse_state_style_config recurse_state
    and custom_header =
      Bonsai.transpose_opt
        (let%map.Option custom_header in
         custom_header ~collapsed c graph)
    in
    let content_container_attr =
      container_attr ~drag_state:`Static ~direction:`Vertical ~child_count:0
    in
    ( {%html|
        <div
          style="
            flex-grow: 1;
            overflow: auto;
            flex-basis: 0;
            display: grid;
            grid-template-rows: 100%;
            grid-template-columns: 100%;
          "
          %{content_container_attr}
        >
          %{content}
        </div>
      |}
    , open_open_config_editor
    , custom_header )
  | { config = Vertical_fixed _; _ }
  | { config = Horizontal_fixed _; _ }
  | { config = Vertical_variable _; _ } ->
    let%arr ~view, ~custom_header = fixed_stack ~recurse recurse_state graph in
    view, None, custom_header
  | { config = Tabbed tabs; _ } ->
    let%arr view = tabbed_stack ~recurse ~tabs recurse_state graph in
    view, None, None
;;

let component
  ?open_config_editor
  ?custom_header
  ~(style_config : Style_config.t Bonsai.t)
  ~(logic : 'a Logic.t Bonsai.t)
  ~(content : 'a Content.t)
  (local_ graph)
  : Node.t Bonsai.t
  =
  let%sub.Bonsai { config; inject; _ } = logic in
  let recurse_state =
    wrap_recurse_state ~config ~inject ~style_config ~collapsed:(Bonsai.return None)
  in
  let%sub view, _, _ =
    Bonsai.fix ~f:(stack ?open_config_editor ?custom_header ~content) recurse_state graph
  in
  view
;;
