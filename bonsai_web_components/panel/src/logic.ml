open! Core
open! Import

module Event = struct
  type t =
    | Toggle_expanded
    | Expand
  [@@deriving sexp_of]
end

module Action = struct
  type 'a t =
    | Toggle_expanded of Bonsai_web_panel_config.Panel_id.t
    | Expand of Bonsai_web_panel_config.Panel_id.t
    | Update_size of
        (panel_id:Bonsai_web_panel_config.Panel_id.t * offset:int * parent_size:int)
    | Change_tab of (panel_id:Bonsai_web_panel_config.Panel_id.t * trigger_collapse:bool)
    | Set_hidden of (panel_id:Bonsai_web_panel_config.Panel_id.t * hidden:bool)
    | Set_title of (panel_id:Bonsai_web_panel_config.Panel_id.t * title:string)
    | Bubble of Event.t
    | Set_content of 'a
    | Update_child_config of (panel_id:Bonsai_web_panel_config.Panel_id.t * action:'a t)
  [@@deriving sexp_of]
end

let find_child_index_by_panel_id (config : 'a Bonsai_web_panel_config.t) panel_id =
  match Bonsai_web_panel_config.child_configs config with
  | None -> None
  | Some child_configs ->
    List.findi child_configs ~f:(fun _i child_config ->
      Bonsai_web_panel_config.Panel_id.equal
        (Bonsai_web_panel_config.panel_id child_config)
        panel_id)
    |> Option.map ~f:fst
;;

let find_tab_index_by_panel_id (config : 'a Bonsai_web_panel_config.t) panel_id =
  match config.config with
  | Bonsai_web_panel_config.Tabbed { tabs; _ } ->
    Nonempty_list.to_list tabs
    |> List.findi ~f:(fun _i (child_config, _label) ->
      Bonsai_web_panel_config.Panel_id.equal
        (Bonsai_web_panel_config.panel_id child_config)
        panel_id)
    |> Option.map ~f:fst
  | _ -> None
;;

type 'a t =
  { config : 'a Bonsai_web_panel_config.t
  ; set_config : 'a Bonsai_web_panel_config.t -> unit Effect.t
  ; inject : 'a Action.t -> unit Effect.t
  }
[@@deriving fields ~getters]

module Parent_layout_type = struct
  type t =
    | Fixed
    | Variable
  [@@deriving sexp_of]

  let of_config_exn = function
    | Bonsai_web_panel_config.Horizontal_fixed _
    | Bonsai_web_panel_config.Vertical_fixed _ -> Fixed
    | Bonsai_web_panel_config.Vertical_variable _ -> Variable
    | Content _ | Tabbed _ ->
      raise_s [%message "Parent_layout_type.of_config_exn called on Content or Tabbed"]
  ;;
end

module Direction = struct
  type t =
    | Horizontal
    | Vertical
  [@@deriving sexp_of]

  let of_config_exn = function
    | Bonsai_web_panel_config.Horizontal_fixed _ -> Horizontal
    | Bonsai_web_panel_config.Vertical_fixed _
    | Bonsai_web_panel_config.Vertical_variable _ -> Vertical
    | Content _ | Tabbed _ ->
      raise_s [%message "Direction.of_config_exn called on Content or Tabbed"]
  ;;
end

let ensure_one_panel_expanded_with_configs child_configs target_panel_id =
  (* We really don't want to be in a state with no children expanded *)
  let non_hidden_configs =
    List.filter child_configs ~f:(fun (_, layout) ->
      not (Bonsai_web_panel_config.Child_layout.hidden layout))
  in
  let has_expanded =
    List.exists non_hidden_configs ~f:(fun (_, layout) ->
      Bonsai_web_panel_config.Child_layout.expanded layout)
  in
  if has_expanded
  then child_configs
  else (
    (* Find first non-hidden panel that's not the target and expand it *)
    let expanded_one = ref false in
    List.map child_configs ~f:(fun ((child_config, layout) as config) ->
      let child_panel_id = child_config.Bonsai_web_panel_config.panel_id in
      if (not !expanded_one)
         && (not (Bonsai_web_panel_config.Panel_id.equal child_panel_id target_panel_id))
         && not (Bonsai_web_panel_config.Child_layout.hidden layout)
      then (
        expanded_one := true;
        child_config, Bonsai_web_panel_config.Child_layout.toggle layout)
      else config))
;;

let get_children_with_layouts config =
  match config.Bonsai_web_panel_config.config with
  | Content _ -> None
  | Vertical_variable children | Vertical_fixed children | Horizontal_fixed children ->
    Some children
  | Tabbed _ -> None
;;

let set_children_with_layouts config children =
  match config.Bonsai_web_panel_config.config with
  | Content _ | Tabbed _ -> config
  | Vertical_variable _ | Vertical_fixed _ | Horizontal_fixed _ ->
    Bonsai_web_panel_config.set_child_layout_configs config children
;;

let map_child_layout ~f ~panel_id config =
  match get_children_with_layouts config with
  | None -> config
  | Some children ->
    let new_children =
      List.map children ~f:(fun ((child_config, layout) as config_pair) ->
        if Bonsai_web_panel_config.Panel_id.equal
             child_config.Bonsai_web_panel_config.panel_id
             panel_id
        then child_config, f layout
        else config_pair)
    in
    let new_children = ensure_one_panel_expanded_with_configs new_children panel_id in
    set_children_with_layouts config new_children
;;

let set_expanded_child_layouts_by_panel_id config panel_id expanded =
  map_child_layout
    ~f:(Bonsai_web_panel_config.Child_layout.set_expanded ~expanded)
    ~panel_id
    config
;;

let toggle_expand_child_layouts_by_panel_id config panel_id =
  map_child_layout ~f:Bonsai_web_panel_config.Child_layout.toggle ~panel_id config
;;

let child_sizes ~child_layouts =
  let without_hidden =
    List.filter ~f:(Bonsai_web_panel_config.Child_layout.hidden >> not) child_layouts
  in
  let pct_width_sum =
    List.fold
      ~init:0.
      ~f:(fun sum child_layout ->
        let size = Bonsai_web_panel_config.Child_layout.size child_layout in
        let expanded = Bonsai_web_panel_config.Child_layout.expanded child_layout in
        sum
        +.
        match expanded, size with
        | true, Bonsai_web_panel_config.Size.Percent pct -> Percent.to_mult pct
        | _ -> 0.)
      without_hidden
  in
  let grid_child_layouts =
    List.map
      ~f:(fun child_layout ->
        let size = Bonsai_web_panel_config.Child_layout.size child_layout in
        let min_size = Bonsai_web_panel_config.Child_layout.min_size child_layout in
        let normalized_size =
          match size with
          | Bonsai_web_panel_config.Size.Px px ->
            ~min_size, ~size:(Bonsai_web_panel_config.Size.Px px)
          | Bonsai_web_panel_config.Size.Percent pct ->
            ( ~min_size
            , ~size:(Bonsai_web_panel_config.Size.Percent
                       (Percent.of_mult (Percent.to_mult pct /. pct_width_sum))) )
        in
        let expanded = Bonsai_web_panel_config.Child_layout.expanded child_layout in
        Option.some_if expanded normalized_size)
      without_hidden
  in
  grid_child_layouts
;;

let update_size_child_layouts ~parent_layout_type ~child_layouts ~offset ~parent_size i =
  (* There are two different coordinate systems we're interested in: what's visible on the
     screen with collapsed panels and what it would look like if all the panels were
     expanded. We want to do operations in the "expanded panel" space. In order to do
     that, we first convert the offset from screen pixel space to screen percent space,
     then from screen percent space to "expanded panel" percent space. Sizes are stored in
     "expanded panel" space and the ui normalizes for collapsed panels.

     There is an intended quirk of doing it this way: min_size refers to expanded panel
     space. E.g. if you have three panels, each with a min_size of 0.33, and collapse the
     first panel, the other two panels will not be able to resize. If they were able to
     resize, then when the user expands the first panel, one of them would be smaller than
     its min_size.
  *)
  let open Bonsai_web_panel_config.Size in
  let offset = Px offset in
  let map_nth ~f index = List.mapi ~f:(fun i a -> if index = i then f a else a) in
  let offset_at_i
    ?(init = Percent Percent.zero)
    ?(replace_collapsed_with_title_size = false)
    i
    sizes
    =
    List.take sizes i
    |> (if replace_collapsed_with_title_size
        then
          List.mapi ~f:(fun i v ->
            if Bonsai_web_panel_config.Child_layout.expanded
                 (List.nth_exn child_layouts i)
            then v
            else Px 25)
        else Fn.id)
    |> List.fold ~init ~f:(add ~parent_size)
  in
  (* The stored sizes in "expanded panel" space *)
  let sizes_ignoring_expanded =
    List.map ~f:Bonsai_web_panel_config.Child_layout.size child_layouts
  in
  let new_sizes =
    match parent_layout_type with
    | Parent_layout_type.Variable ->
      let calced_size_value =
        sub
          ~parent_size
          offset
          (offset_at_i ~replace_collapsed_with_title_size:true i sizes_ignoring_expanded)
      in
      map_nth i ~f:(Fn.const calced_size_value) sizes_ignoring_expanded
    | Parent_layout_type.Fixed ->
      (* Mixing and matching pixel sizes with percents means we need to normalize them to
         percents *)
      let parent_size_size = Px parent_size in
      let percent_total =
        List.filter
          ~f:(function
            | Px _ -> false
            | Percent _ -> true)
          sizes_ignoring_expanded
        |> offset_at_i (List.length sizes_ignoring_expanded)
      in
      let pixel_total =
        List.filter
          ~f:(function
            | Px _ -> true
            | Percent _ -> false)
          sizes_ignoring_expanded
        |> offset_at_i (List.length sizes_ignoring_expanded) ~init:(Px 0)
      in
      let pixel_percent_of_parent =
        div_to_percent ~parent_size pixel_total parent_size_size
      in
      let non_pixel_percent_of_parent =
        sub ~parent_size (Percent (Percent.of_mult 1.)) pixel_percent_of_parent
      in
      let sizes_normalized_to_percent_of_parent =
        List.map sizes_ignoring_expanded ~f:(function
          | Px v -> Px v
          | Percent p ->
            div ~parent_size (Percent p) percent_total
            |> mul ~parent_size non_pixel_percent_of_parent)
      in
      let calced_size_value =
        let percent_visible =
          List.foldi
            ~init:(Percent Percent.zero)
            child_layouts
            ~f:(fun i acc { Bonsai_web_panel_config.Child_layout.expanded; _ } ->
              match expanded, List.nth_exn sizes_normalized_to_percent_of_parent i with
              | true, v -> add ~parent_size acc v
              | _ -> acc)
        in
        let offset = to_percent_size ~parent_size offset in
        let offset_at_i =
          offset_at_i
            i
            ~replace_collapsed_with_title_size:true
            sizes_normalized_to_percent_of_parent
        in
        let pure_offset =
          if i <= 0 then offset else sub ~parent_size offset offset_at_i
        in
        let scaled_offset = mul ~parent_size pure_offset percent_visible in
        scaled_offset
      in
      (* Make sure both this panel and the next conform to their min_size (which can be
         pixels or percent) *)
      let current_size = List.nth_exn sizes_normalized_to_percent_of_parent i in
      (* Dividers are shown between two panels, on the panel that comes first in the
         stack. i + 1 is safe because the last panel will never have a divider. *)
      let next_size = List.nth_exn sizes_normalized_to_percent_of_parent (i + 1) in
      let current_min_size =
        List.nth_exn child_layouts i |> Bonsai_web_panel_config.Child_layout.min_size
      in
      let next_min_size =
        List.nth_exn child_layouts (i + 1)
        |> Bonsai_web_panel_config.Child_layout.min_size
      in
      let clamp_size_at_min size min_size =
        if sub ~parent_size size min_size |> to_pixels ~parent_size >= 0
        then size
        else min_size
      in
      let calced_size_value = clamp_size_at_min calced_size_value current_min_size in
      let new_next_size =
        sub ~parent_size next_size (sub ~parent_size calced_size_value current_size)
      in
      let new_next_size = clamp_size_at_min new_next_size next_min_size in
      let calced_size_value =
        sub ~parent_size current_size (sub ~parent_size new_next_size next_size)
      in
      List.mapi
        ~f:(fun ii v ->
          if ii = i
          then to_percent_size ~parent_size calced_size_value
          else if ii = i + 1
          then to_percent_size ~parent_size new_next_size
          else v)
        sizes_normalized_to_percent_of_parent
  in
  let new_child_layouts_and_saved = List.zip_exn new_sizes child_layouts in
  let new_saved_child_layouts =
    List.map
      ~f:(fun (size, saved_width) ->
        Bonsai_web_panel_config.Child_layout.set_size ~size saved_width)
      new_child_layouts_and_saved
  in
  new_saved_child_layouts
;;

module Child_sizes = struct
  type size_tuple =
    min_size:Bonsai_web_panel_config.Size.t * size:Bonsai_web_panel_config.Size.t
  [@@deriving sexp, equal]

  type t =
    | Horizontal_fixed of size_tuple option list
    | Vertical_fixed of size_tuple option list
    | Vertical_variable of size_tuple option list
  [@@deriving sexp, equal]

  let of_config config =
    let%arr config in
    let%map.Option child_layouts = Bonsai_web_panel_config.child_float_layouts config in
    let sizes = child_sizes ~child_layouts in
    match config.config with
    | Vertical_variable _ -> Vertical_variable sizes
    | Horizontal_fixed _ -> Horizontal_fixed sizes
    | Vertical_fixed _ -> Vertical_fixed sizes
    | Content _ | Tabbed _ ->
      raise_s [%message "Child_sizes.of_config called on Content or Tabbed"]
  ;;
end

let child_has_divider
  ~(child_layouts : Bonsai_web_panel_config.Child_layout.t list)
  ~parent_layout_type
  ~index:i
  =
  let child_layout = List.nth_exn child_layouts i in
  match
    Bonsai_web_panel_config.Child_layout.expanded child_layout, parent_layout_type
  with
  | true, Parent_layout_type.Variable ->
    (* expanded variable children always have a divider *)
    true
  | false, _ -> false
  | _ ->
    let next_child_is_expanded =
      let%map.Option next_child_layout = List.nth child_layouts (i + 1) in
      Bonsai_web_panel_config.Child_layout.expanded next_child_layout
      && not next_child_layout.hidden
    in
    Option.value ~default:false next_child_is_expanded
;;

let inject_action config action =
  let rec inject (config : 'a Bonsai_web_panel_config.t) action =
    match config.Bonsai_web_panel_config.config with
    | Content _ ->
      (match action with
       | Action.Set_content content ->
         ( ~config:(Bonsai_web_panel_config.create_content
                      ~panel_id:config.Bonsai_web_panel_config.panel_id
                      content)
         , ~bubbled_events:[] )
       | _ -> ~config, ~bubbled_events:[])
    | _ ->
      (* Ok to use value_exn here as we know we're in a stack *)
      let child_configs =
        Bonsai_web_panel_config.child_configs config |> Option.value_exn
      in
      let child_layouts = Bonsai_web_panel_config.child_float_layouts config in
      let non_hidden_child_layouts =
        let%map.Option child_layouts in
        List.filter ~f:(Bonsai_web_panel_config.Child_layout.hidden >> not) child_layouts
      in
      (match action with
       | Action.Bubble event -> ~config, ~bubbled_events:[ event ]
       | Toggle_expanded panel_id ->
         if Option.value_map ~f:List.length ~default:0 non_hidden_child_layouts > 1
         then
           ( ~config:(toggle_expand_child_layouts_by_panel_id config panel_id)
           , ~bubbled_events:[] )
         else ~config, ~bubbled_events:[ Event.Toggle_expanded ]
       | Expand panel_id ->
         if Option.value_map ~f:List.length ~default:0 non_hidden_child_layouts > 1
         then
           ( ~config:(set_expanded_child_layouts_by_panel_id config panel_id true)
           , ~bubbled_events:[] )
         else ~config, ~bubbled_events:[ Event.Expand ]
       | Update_size (~panel_id, ~offset, ~parent_size) ->
         (match find_child_index_by_panel_id config panel_id with
          | None ->
            print_s
              [%message
                "Update_size called with non-existant"
                  (panel_id : Bonsai_web_panel_config.Panel_id.t)];
            ~config, ~bubbled_events:[]
          | Some i ->
            let child_layouts = Option.value_exn child_layouts in
            let parent_layout_type =
              Parent_layout_type.of_config_exn config.Bonsai_web_panel_config.config
            in
            ( ~config:(let new_child_layouts =
                         update_size_child_layouts
                           ~parent_layout_type
                           ~child_layouts
                           ~offset
                           ~parent_size
                           i
                       in
                       Bonsai_web_panel_config.set_child_layouts config new_child_layouts)
            , ~bubbled_events:[] ))
       | Set_hidden (~panel_id, ~hidden) ->
         (match find_child_index_by_panel_id config panel_id with
          | None ->
            print_s
              [%message
                "Set_hidden called with non-existant"
                  (panel_id : Bonsai_web_panel_config.Panel_id.t)];
            ~config, ~bubbled_events:[]
          | Some child_index ->
            let child_layouts = Option.value_exn child_layouts in
            ( ~config:(Bonsai_web_panel_config.set_child_layouts
                         config
                         (List.mapi
                            ~f:(fun i c ->
                              if i = child_index then { c with hidden } else c)
                            child_layouts))
            , ~bubbled_events:[] ))
       | Set_title (~panel_id, ~title) ->
         (match find_child_index_by_panel_id config panel_id with
          | None ->
            print_s
              [%message
                "Set_title called with non-existant"
                  (panel_id : Bonsai_web_panel_config.Panel_id.t)];
            ~config, ~bubbled_events:[]
          | Some child_index ->
            (match config.config with
             | Tabbed tabbed ->
               let tab_titles =
                 Nonempty_list.mapi tabbed.tabs ~f:(fun i tab ->
                   if i = child_index then title else snd tab)
               in
               ( ~config:(Bonsai_web_panel_config.set_tab_titles config tab_titles)
               , ~bubbled_events:[] )
             | _ ->
               let child_layouts = Option.value_exn child_layouts in
               ( ~config:(Bonsai_web_panel_config.set_child_layouts
                            config
                            (List.mapi
                               ~f:(fun i c ->
                                 if i = child_index
                                 then { c with layout_type = Accordion { title } }
                                 else c)
                               child_layouts))
               , ~bubbled_events:[] )))
       | Change_tab (~panel_id, ~trigger_collapse) ->
         (match find_tab_index_by_panel_id config panel_id with
          | None ->
            print_s
              [%message
                "Change_tab called with non-existant"
                  (panel_id : Bonsai_web_panel_config.Panel_id.t)];
            ~config, ~bubbled_events:[]
          | Some i ->
            (match config.config with
             | Tabbed tabbed ->
               if tabbed.tabs |> Nonempty_list.length <= i
               then raise_s [%message "Invalid tab index" (i : int)]
               else if not (tabbed.current_tab = i)
               then
                 ( ~config:(Bonsai_web_panel_config.create_stack_tabbed
                              ~panel_id:config.Bonsai_web_panel_config.panel_id
                              ~initial_active_tab:i
                              tabbed.tabs)
                 , ~bubbled_events:[ Event.Expand ] )
               else
                 ( ~config
                 , ~bubbled_events:(if trigger_collapse
                                    then [ Event.Toggle_expanded ]
                                    else []) )
             | _ -> raise_s [%message "Change_tab called on non-tabbed config"]))
       | Update_child_config (~panel_id, ~action) ->
         (match find_child_index_by_panel_id config panel_id with
          | None ->
            print_s
              [%message
                "Update_child_config called with non-existant"
                  (panel_id : Bonsai_web_panel_config.Panel_id.t)];
            ~config, ~bubbled_events:[]
          | Some child_index ->
            let old_child_config = List.nth child_configs child_index in
            let ~config:new_child_config, ~bubbled_events =
              match old_child_config with
              | None -> ~config, ~bubbled_events:[]
              | Some child_config -> inject child_config action
            in
            let config =
              List.mapi
                ~f:(fun i config -> if i = child_index then new_child_config else config)
                child_configs
              |> Bonsai_web_panel_config.set_child_configs config
            in
            List.fold
              ~init:(~config, ~bubbled_events:[])
              ~f:(fun (~config, ~bubbled_events) -> function
                | Event.Toggle_expanded ->
                  let ~config, ~bubbled_events:new_events =
                    inject config (Action.Toggle_expanded panel_id)
                  in
                  ~config, ~bubbled_events:(List.append bubbled_events new_events)
                | Event.Expand ->
                  let ~config, ~bubbled_events:new_events =
                    inject config (Action.Expand panel_id)
                  in
                  ~config, ~bubbled_events:(List.append bubbled_events new_events))
              bubbled_events)
       | Set_content _ -> ~config, ~bubbled_events:[])
  in
  let ~config, .. = inject config action in
  config
;;

let create ?set_config ~equal ~sexp_of ~config graph =
  let config, set_config =
    match set_config with
    | None ->
      let local_config, local_set_config =
        Bonsai_extra.State_machine.state_dynamic_model
          ~sexp_of_model:(Bonsai_web_panel_config.sexp_of_t sexp_of)
          ~equal:(Bonsai_web_panel_config.equal equal)
          ~model:(`Given config)
          graph
      in
      let config =
        Bonsai_helpers.last_value
          ~equal:(Bonsai_web_panel_config.equal equal)
          config
          local_config
          graph
      in
      config, local_set_config
    | Some set_config -> config, set_config
  in
  let inject =
    let%arr set_config and config in
    fun action -> set_config (inject_action config action)
  in
  let%arr config and inject and set_config in
  { config; inject; set_config }
;;

module For_testing = struct
  let child_sizes = child_sizes
end
