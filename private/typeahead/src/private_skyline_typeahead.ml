open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Suggestion_state = struct
  type 'a t =
    { filtered : 'a Iarray.t
    ; offset : int
    ; limit : int
    ; current : int
    ; active : bool
    }
  [@@deriving sexp_of]

  type 'a action =
    | Update of
        { filtered : 'a Iarray.t
        ; limit : int
        }
    | Activate
    | Deactivate
    | Move_to of int
    | Move_up
    | Move_down
    | Select of int
    | Select_current
    | Tab_complete_current
  [@@deriving sexp_of]

  let component ~limit ~score ~on_select ~on_tab_complete ~suggestions graph =
    let apply_action ctx input model action =
      let on_select idx =
        match (input : _ Bonsai.Computation_status.t) with
        | Active (on_select, _) when idx >= 0 && idx < Iarray.length model.filtered ->
          Iarray.get model.filtered idx
          |> on_select
          |> Bonsai.Apply_action_context.schedule_event ctx
        | _ -> ()
      in
      let on_tab_complete idx =
        match (input : _ Bonsai.Computation_status.t) with
        | Active (_, on_tab_complete) when idx >= 0 && idx < Iarray.length model.filtered
          ->
          Iarray.get model.filtered idx
          |> on_tab_complete
          |> Bonsai.Apply_action_context.schedule_event ctx
        | _ -> ()
      in
      let next_model =
        match model.active, action with
        | _, Update { filtered; limit } ->
          { model with filtered; limit; offset = 0; current = 0 }
        | _, Activate -> { model with active = true }
        | _, Deactivate -> { model with active = false }
        | true, Move_to current ->
          let is_in_view =
            model.offset <= current && current <= model.offset + model.limit
          in
          if is_in_view
          then { model with current }
          else { model with current; offset = current }
        | true, Move_up ->
          let length = Iarray.length model.filtered in
          if model.current = 0
          then
            { model with
              offset = Int.max 0 (length - model.limit)
            ; current = Int.max 0 (length - 1)
            }
          else (
            let current = model.current - 1 in
            { model with offset = Int.min model.offset current; current })
        | true, Move_down ->
          let length = Iarray.length model.filtered in
          let current = model.current + 1 in
          if current = length
          then { model with offset = 0; current = 0 }
          else
            { model with
              offset = Int.max model.offset (current + 1 - model.limit)
            ; current
            }
        | _, Select idx ->
          on_select idx;
          { model with active = false }
        | true, Select_current ->
          on_select model.current;
          { model with active = false }
        | true, Tab_complete_current ->
          on_tab_complete model.current;
          model
        | false, _ -> model
      in
      next_model
    in
    let state, inject =
      Bonsai.state_machine_with_input
        ~default_model:
          { filtered = Iarray.empty; offset = 0; limit = 0; current = 0; active = false }
        ~apply_action
        (Bonsai.both on_select on_tab_complete)
        graph
    in
    let filtered =
      let%arr score and suggestions in
      List.filter_map suggestions ~f:(fun item ->
        match score item with
        | 0 -> None
        | score ->
          (* Tie break using existing ordering. *)
          Some (score, item))
      |> List.sort ~compare:[%compare: int * _]
      |> Iarray.of_list_map ~f:(fun (_, item) -> item)
    in
    Bonsai.Edge.on_change
      ~trigger:`After_display
      ~equal:phys_equal
      ~callback:
        (let%arr inject and limit in
         fun filtered -> inject (Update { limit; filtered }))
      filtered
      graph;
    state, inject
  ;;
end

let default_suggestion ~to_string query =
  let%arr query and to_string in
  let query = Fuzzy_search.Query.create query in
  fun item ->
    let item = to_string item in
    match Fuzzy_search.split_by_matching_sections query ~item with
    | None -> Skyline_flex_v1.row [ Skyline_text_v1.span item ]
    | Some sections ->
      let attrs = [ Vdom.Attr.style (Css_gen.white_space `Pre) ] in
      List.map sections ~f:(function
        | `Matching, text ->
          Skyline_text_v1.span ~attrs ~intent:Skyline_theme_v1.accent ~style:Bold text
        | `Not_matching, text -> Skyline_text_v1.span ~attrs text)
      |> Skyline_flex_v1.row ~align:Baseline
;;

let suggestion_list ~inject ~filtered ~suggestion ~offset ~limit ~current =
  let suggestion ~idx_in_view ~idx ~is_current item =
    let style =
      Css_gen.(
        box_sizing `Border_box
        @> flex_container ()
        @> height (`Raw "max-content")
        @> border ~width:(`Px 0) ~style:`Solid ()
        @> border_radius (`Px 4)
        @> uniform_margin (`Px 0)
        @> uniform_padding (`Px 0)
        @> color Skyline_theme_v1.primary
        @> background_color `Inherit
        @> create ~field:"font-family" ~value:"var(--skyline-font-sans, sans-serif)"
        @> line_height (`Raw "1.2"))
    in
    Vdom.Node.button
      ~key:(Int.to_string idx_in_view)
      ~attrs:
        [ Vdom.Attr.style style
        ; (if is_current
           then Vdom.Attr.style (Css_gen.background_color Skyline_theme_v1.border)
           else Vdom.Attr.empty)
        ; Vdom.Attr.on_mouseenter (fun _ -> inject (Suggestion_state.Move_to idx))
        ; Vdom.Attr.on_mousedown (fun _ -> inject (Suggestion_state.Select idx))
        ]
      [ suggestion item ]
  in
  let limit_or_end_of_array = Int.min (offset + limit) (Iarray.length filtered) in
  let num_items = Int.max 0 (limit_or_end_of_array - offset) in
  List.init num_items ~f:(fun idx_in_view ->
    let idx = idx_in_view + offset in
    Iarray.get filtered idx |> suggestion ~idx_in_view ~is_current:(current = idx) ~idx)
  |> Skyline_flex_v1.column ~align:Stretch
;;

let suggestion_popover ~input_width suggestions (local_ _graph) =
  let%arr suggestions and input_width in
  let contents =
    let style =
      Css_gen.(
        box_sizing `Border_box
        @> min_width (`Px_float input_width)
        @> max_width (`Vw (Percent.of_percentage 95.))
        @> max_height (`Percent Percent.one_hundred_percent)
        @> uniform_padding (`Px 4)
        @> uniform_margin (`Px 0)
        @> overflow_x `Hidden
        @> overflow_y `Auto
        @> border ~width:(`Px 1) ~style:`Solid ~color:Skyline_theme_v1.border ()
        @> border_radius (`Px 2)
        @> background_color Skyline_theme_v1.surface
        @> Private_skyline_theme.Shadows.raised_card)
    in
    Skyline_flex_v1.column
      ~attrs:
        [ Vdom.Attr.style style
        ; Private_skyline_theme.Stylesheet.step_nested_surface_ramp
        ]
      ~align:Stretch
      [ suggestions ]
  in
  Bonsai_web_toplayer.vdom_popover
    ~popover_attrs:
      [ Vdom.Attr.style
          Css_gen.(
            background_color (`Name "none")
            @> border ~style:`None ()
            @> uniform_padding (`Px 0))
      ]
    ~restore_focus_on_close:Bonsai_web_toplayer.Restore_focus_on_close.No
    ~overflow_auto_wrapper:false
    ~position:Bottom
    ~alignment:Start
    ~offset:{ main_axis = 2.; cross_axis = 0. }
    contents
;;

type t =
  [ `Idle
  | `Matches of Vdom.Node.t
  | `Empty of Vdom.Node.t
  ]

let component
  ~query
  ~to_string
  ~limit
  ~score
  ~on_select
  ~on_tab_complete
  ~suggestion
  ~no_matching_suggestions
  suggestions
  graph
  =
  let model, inject =
    Suggestion_state.component
      ~limit
      ~score
      ~on_select
      ~on_tab_complete
      ~suggestions
      graph
  in
  let suggestion_list =
    match%sub model with
    | { active = false; _ } -> return `Idle
    | { filtered = [::]; active = true; _ } ->
      let%arr no_matching_suggestions in
      (match no_matching_suggestions with
       | Vdom.Node.None -> `Idle
       | none when phys_equal none Vdom.Node.none -> `Idle
       | placeholder -> `Empty placeholder)
    | { filtered; offset; limit; current; active = true } ->
      let%arr inject
      and filtered
      and suggestion =
        match suggestion with
        | Some suggestion -> suggestion
        | None -> default_suggestion ~to_string query
      and offset
      and limit
      and current in
      `Matches (suggestion_list ~inject ~filtered ~suggestion ~offset ~limit ~current)
  in
  suggestion_list, inject
;;
