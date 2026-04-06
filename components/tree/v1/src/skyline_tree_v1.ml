open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
module Layout = Layout

module Decoration = struct
  type t =
    | Primary
    | Foreground of Skyline_theme_v1.Color.t
    | Background of Skyline_theme_v1.Color.t
    | Secondary
    | Inherit
  [@@deriving sexp_of]
end

module Path = struct
  type t = string Nonempty_list.t [@@deriving sexp, compare]

  let to_string path = String.concat ~sep:"/" (Nonempty_list.to_list path)
  let of_string path = Nonempty_list.of_list_exn (String.split path ~on:'/')

  let string_length path =
    Nonempty_list.foldi path ~init:0 ~f:(fun idx accum elem ->
      if idx = 0 then String.length elem else accum + 1 + String.length elem)
  ;;

  type comparator_witness = String.comparator_witness Nonempty_list.comparator_witness

  let comparator = Nonempty_list.comparator String.comparator

  include functor Comparable.Make_using_comparator

  module Segment = struct
    include Path_segment

    let path_elements { segments; _ } = segments

    let component ?(should_handle_indentation = true) segment =
      component
        { segment with
          indent_tree_leaf = should_handle_indentation && segment.indent_tree_leaf
        }
    ;;
  end
end

module Branch = struct
  type 'a t =
    | Parent of Path.t
    | Empty of Path.t
    | Leaf_parent of Path.t * 'a
    | Leaf of Path.t * 'a

  let item = function
    | Parent _ | Empty _ -> None
    | Leaf_parent (_, item) | Leaf (_, item) -> Some item
  ;;
end

module Style = struct
  include
    [%css
    stylesheet
      ~dont_hash_prefixes:[ "--skyline" ]
      {|
        .container {
          box-sizing: border-box;
          width: 100%;
        }

        .row {
          width: 100%;
          box-sizing: border-box;
          min-height: 24px;
          display: flex;
          flex-direction: row;
          flex-wrap: wrap;
          align-items: center;
          justify-content: start;
          column-gap: 8px;
          row-gap: 2px;
          margin: 0;
          padding: 0 4px;

          font-family: var(--skyline-font-sans, sans-serif);
          line-height: 1.2;
          text-align: left;

          border-width: 0;
          border-style: solid;
          border-radius: 4px;
          background-color: inherit;

          -webkit-appearance: button;
          appearance: button;
          outline: none;
        }

        .row:nth-child(odd) {
          background-color: var(--alternate-background-color);
        }

        .row:hover,
        .row.highlighted {
          background-color: var(--skyline-color-border);
        }

        .row:focus {
          outline-color: var(--skyline-color-accent);
          outline-width: 1px;
          outline-style: solid;
          outline-offset: -1px;
        }

        .chevron {
          box-sizing: border-box;
          width: 16px;
          height: 16px;
          display: flex;
          margin: 0;
          padding: 0;

          border: none;
          border-radius: 2px;
          color: var(--skyline-color-primary, inherit);
          background-color: inherit;
        }
        .chevron:hover {
          background-color: var(--skyline-color-border);
        }

        .path-indent {
          box-sizing: border-box;
          min-height: 24px;
          width: var(--width);
          padding: 0;
          margin: 0;
          flex-shrink: 0;
          background-image: repeating-linear-gradient(
            90deg,
            transparent 0px,
            transparent 11px,
            #9993 11px,
            #9993 12px,
            transparent 12px
          );
          background-size: 12px;
        }

        .row-flex-grow {
          flex-grow: 1;
        }
      |}]

  let row ~alternating_row_background =
    let alternate_background_color =
      if alternating_row_background
      then Skyline_theme_v1.surface |> Css_gen.Color.to_string_css
      else "inherit"
    in
    Vdom.Attr.many
      [ Vdom.Attr.tabindex 0; Variables.set ~alternate_background_color (); row ]
  ;;

  let path_indent parents =
    let width = Css_gen.Length.to_string_css (`Px (1 + (12 * parents))) in
    Vdom.Attr.many [ Variables.set ~width (); path_indent ]
  ;;
end

let tree_row_path_segment ~matching_indices key row : Path_segment.t =
  let _, intent, branch = Bonsai_web_ui_tree_table.Row.data row in
  let segments =
    List.fold_until
      (Bonsai_web_ui_tree_table.Row.ancestors row)
      ~init:[ Nonempty_list.last key ]
      ~f:(fun acc (_, (_, _, branch)) ->
        match (branch : _ Branch.t) with
        | Empty path -> Continue (Nonempty_list.last path :: acc)
        | Parent _ | Leaf_parent _ | Leaf _ -> Stop acc)
      ~finish:Fn.id
    |> Nonempty_list.of_list_exn
  in
  let parent_path_length =
    Bonsai_web_ui_tree_table.Row.ancestors row
    |> List.hd
    |> Option.value_map ~f:(fun (key, _) -> Path.string_length key + 1) ~default:0
  in
  let indent_tree_leaf =
    match branch with
    | Leaf _ -> true
    | Empty _ | Parent _ | Leaf_parent _ -> false
  in
  { layout = Tree
  ; parent_path_length
  ; matching_indices
  ; intent
  ; segments
  ; indent_tree_leaf
  }
;;

let list_row_path_segment ~decoration ~matching_indices key : Path_segment.t =
  let intent =
    match (decoration : Decoration.t) with
    | Primary | Secondary | Inherit -> `Primary `None
    | Foreground intent -> `Primary (`Foreground intent)
    | Background intent -> `Primary (`Background intent)
  in
  { layout = List
  ; parent_path_length = 0
  ; matching_indices
  ; intent
  ; segments = key
  ; indent_tree_leaf = false
  }
;;

let is_child_of_collapsed ~collapsed_paths row =
  Bonsai_web_ui_tree_table.Row.ancestors row
  |> List.exists ~f:(fun (key, (_, _, branch)) ->
    match branch with
    | Branch.Empty _ ->
      (* If the parent is empty, we don't care that it's been collapsed since it's never
         rendered. *)
      false
    | Parent _ | Leaf_parent _ | Leaf _ -> Set.mem collapsed_paths key)
;;

let tree_row_contents ~collapsed ~toggle_collapsed ~content key row =
  let indent =
    let non_empty_parents =
      List.count
        (Bonsai_web_ui_tree_table.Row.ancestors row)
        ~f:(fun (_, (_, _, branch)) ->
          match (branch : _ Branch.t) with
          | Parent _ | Leaf_parent _ | Leaf _ -> true
          | Empty _ -> false)
    in
    Vdom.Node.div ~attrs:[ Style.path_indent non_empty_parents ] []
  in
  let toggle =
    match collapsed with
    | Some collapsed ->
      let toggle_on_click =
        Vdom.Attr.on_click (fun event ->
          Js_of_ocaml.Dom_html.stopPropagation event;
          Js_of_ocaml.Dom.preventDefault event;
          toggle_collapsed key)
      in
      Vdom.Node.button
        ~attrs:[ Style.chevron; toggle_on_click ]
        [ Codicons.svg (if collapsed then Chevron_right else Chevron_down) ]
    | None -> None
  in
  Skyline_flex_v1.row
    ~gap:(`Px 4)
    ~align:Stretch
    ~justify:Flex_start
    ~attrs:[ Style.row_flex_grow ]
    [ indent
    ; Skyline_flex_v1.row
        ~gap:(`Px 4)
        ~align:Center
        ~justify:Flex_start
        ~attrs:[ Style.row_flex_grow ]
        [ toggle; content ]
    ]
;;

let tree_row
  ~collapsed_paths
  ~toggle_collapsed
  ~search
  ~on_click
  ~on_contextmenu
  ~highlight
  ~render_segment
  ~render_item
  ~alternating_row_background
  ~disable_keyboard_navigation
  key
  row
  graph
  =
  let branch : _ Branch.t Bonsai.t =
    let%arr collapsed_paths and key and row in
    match Bonsai_web_ui_tree_table.Row.data row with
    | _, _, (Branch.Empty _ as empty) -> empty
    | _, _, branch ->
      if is_child_of_collapsed ~collapsed_paths row then Empty key else branch
  in
  let matching_indices =
    let%arr search and key in
    let%bind.Option search in
    Fuzzy_search.matching_indices search ~item:(Path.to_string key)
  in
  let highlight =
    let%arr key
    and highlight = Bonsai.transpose_opt highlight in
    Option.value_map highlight ~f:(Path.equal key) ~default:false
  in
  let container ~on_click ~on_contextmenu ~highlight contents =
    let attrs =
      [ Style.row ~alternating_row_background
      ; (if highlight then Style.highlighted else Vdom.Attr.empty)
      ; (if disable_keyboard_navigation
         then Vdom.Attr.empty
         else Keyboard_navigation.row_attr ~on_enter:on_click)
      ; Vdom.Attr.on_contextmenu on_contextmenu
      ]
    in
    match on_click with
    | Effect.Open { url; target } ->
      Vdom.Node.a
        ~attrs:
          (Vdom.Attr.href url
           :: Vdom.Attr.target (Effect.Open_url_target.to_target target)
           :: attrs)
        contents
    | _ -> Vdom.Node.button ~attrs:(Vdom.Attr.on_click (const on_click) :: attrs) contents
  in
  match%sub branch with
  | Empty _ -> Bonsai.return None
  | Parent key ->
    let%arr content =
      render_segment
        key
        (let%arr matching_indices and key and row in
         tree_row_path_segment ~matching_indices key row)
        graph
    and collapsed_paths
    and toggle_collapsed
    and on_click
    and on_contextmenu
    and highlight
    and key
    and row in
    container
      ~on_click:(on_click key None)
      ~on_contextmenu:(fun event -> on_contextmenu event key None)
      ~highlight
      [ tree_row_contents
          ~collapsed:(Some (Set.mem collapsed_paths key))
          ~toggle_collapsed
          ~content
          key
          row
      ]
    |> Option.return
  | Leaf_parent (key, item) ->
    let%arr content =
      render_item
        key
        (let%arr matching_indices and key and row in
         tree_row_path_segment ~matching_indices key row)
        item
        graph
    and collapsed_paths
    and toggle_collapsed
    and on_click
    and on_contextmenu
    and highlight
    and key
    and item
    and row in
    container
      ~on_click:(on_click key (Some item))
      ~on_contextmenu:(fun event -> on_contextmenu event key (Some item))
      ~highlight
      [ tree_row_contents
          ~collapsed:(Some (Set.mem collapsed_paths key))
          ~toggle_collapsed
          ~content
          key
          row
      ]
    |> Option.return
  | Leaf (key, item) ->
    let%arr content =
      render_item
        key
        (let%arr matching_indices and key and row in
         tree_row_path_segment ~matching_indices key row)
        item
        graph
    and toggle_collapsed
    and on_click
    and on_contextmenu
    and highlight
    and key
    and item
    and row in
    container
      ~on_click:(on_click key (Some item))
      ~on_contextmenu:(fun event -> on_contextmenu event key (Some item))
      ~highlight
      [ tree_row_contents ~collapsed:None ~toggle_collapsed ~content key row ]
    |> Option.return
;;

let list_row
  ~search
  ~highlight
  ~decoration
  ~render_item
  ~on_click
  ~on_contextmenu
  ~alternating_row_background
  ~disable_keyboard_navigation
  key
  item
  graph
  =
  let matching_indices =
    let%arr search and key in
    let%bind.Option search in
    Fuzzy_search.matching_indices search ~item:(Path.to_string key)
  in
  let%arr on_click
  and on_contextmenu
  and highlight = Bonsai.transpose_opt highlight
  and content =
    render_item
      key
      (let%arr matching_indices and key and item in
       let decoration = decoration key (Some item) in
       list_row_path_segment ~decoration ~matching_indices key)
      item
      graph
  and key
  and item in
  let highlight =
    match highlight with
    | Some key' when Path.equal key' key -> Style.highlighted
    | _ -> Vdom.Attr.empty
  in
  let on_click = on_click key (Some item) |> Option.value ~default:Effect.Ignore in
  Vdom.Node.button
    ~attrs:
      [ Style.row ~alternating_row_background
      ; highlight
      ; Vdom.Attr.on_click (const on_click)
      ; Vdom.Attr.on_contextmenu (fun event -> on_contextmenu event key (Some item))
      ; (if disable_keyboard_navigation
         then Vdom.Attr.empty
         else Keyboard_navigation.row_attr ~on_enter:on_click)
      ]
    [ content ]
;;

let tree_of_items' filter_and_items_by_path =
  let filter = Incr.map filter_and_items_by_path ~f:fst in
  let items_by_path = Incr.map filter_and_items_by_path ~f:snd in
  let add_item_to_tree ~filter ~key ~item tree =
    match filter with
    | Some query ->
      let score = Fuzzy_search.score query ~item:(Path.to_string key) in
      if score > 0
      then Bonsai_web_ui_tree_table.Tree.set tree ~key ~data:(score, item)
      else tree
    | None -> Bonsai_web_ui_tree_table.Tree.set tree ~key ~data:(0, item)
  in
  let build_non_incr ~filter items_by_path =
    Map.fold
      items_by_path
      ~init:(Bonsai_web_ui_tree_table.Tree.empty (module String))
      ~f:(fun ~key ~data tree -> add_item_to_tree ~filter ~key ~item:data tree)
  in
  Incr.Map.unordered_fold_with_extra
    ~init:(Bonsai_web_ui_tree_table.Tree.empty (module String))
    ~add:(fun ~key ~data tree filter -> add_item_to_tree ~filter ~key ~item:data tree)
    ~remove:(fun ~key ~data:_ tree _filter ->
      Bonsai_web_ui_tree_table.Tree.remove tree key)
    ~extra_changed:(fun ~old_extra:_ ~new_extra:filter ~input _ ->
      build_non_incr ~filter input)
    items_by_path
    filter
;;

type child_intent =
  { error : int
  ; warning : int
  ; success : int
  ; accent : int
  }

let tree_of_items ~merge_empty_paths ~decoration ~search items_by_path graph =
  let how_to_map =
    let score_of_branch branch =
      let score, _, _ = Bonsai_web_ui_tree_table.Tree.data branch in
      score
    in
    let intent_of_color color =
      if phys_equal color Skyline_theme_v1.error
      then Some `Error
      else if phys_equal color Skyline_theme_v1.warning
      then Some `Warning
      else if phys_equal color Skyline_theme_v1.success
      then Some `Success
      else if phys_equal color Skyline_theme_v1.accent
      then Some `Accent
      else None
    in
    let intent_of_branch branch : _ option =
      let _, intent, _ = Bonsai_web_ui_tree_table.Tree.data branch in
      match intent with
      | `Primary `None | `Secondary None -> None
      | `Primary (`Foreground intent) | `Primary (`Background intent) ->
        intent_of_color intent
      | `Secondary (Some intent) -> intent_of_color intent
    in
    let counts_to_intent { error; warning; success; accent } : _ option =
      if error > 0
      then Some Skyline_theme_v1.error
      else if warning > 0
      then Some Skyline_theme_v1.warning
      else if success > 0
      then Some Skyline_theme_v1.success
      else if accent > 0
      then Some Skyline_theme_v1.accent
      else None
    in
    let common ~children_total_score ~children_intent ~has_leaf_child ~key ~data =
      let intent =
        match decoration key (Option.map data ~f:snd) with
        | Decoration.Primary -> `Primary `None
        | Secondary -> `Secondary None
        | Foreground intent -> `Primary (`Foreground intent)
        | Background intent -> `Primary (`Background intent)
        | Inherit -> `Secondary children_intent
      in
      match data, has_leaf_child with
      | Some (score, item), `No_children -> score, intent, Branch.Leaf (key, item)
      | Some (score, item), _ ->
        score + children_total_score, intent, Leaf_parent (key, item)
      | None, `Single_non_leaf_child ->
        (* Mark paths with a single non leaf child as empty if we want them to be elided
           (i.e. collapsed into a single branch) in the rendered tree. *)
        children_total_score, intent, if merge_empty_paths then Empty key else Parent key
      | None, _ -> children_total_score, intent, Parent key
    in
    let has_leaf_child children =
      if Map.length children <= 1
      then (
        match Map.data children with
        | [ branch ] ->
          let _, _, branch = Bonsai_web_ui_tree_table.Tree.data branch in
          (match branch with
           | Branch.Leaf _ | Leaf_parent _ -> `Single_leaf_child
           | Parent _ | Empty _ -> `Single_non_leaf_child)
        | _ -> `No_children)
      else `Many_children
    in
    let incremental ~key ~data ~children =
      let%map.Incr children_total_score =
        Incr_map.sum children (module Int) ~f:score_of_branch
      and has_leaf_child = Incr.map children ~f:has_leaf_child
      and children_intent =
        Incr_map.unordered_fold
          children
          ~init:{ error = 0; warning = 0; success = 0; accent = 0 }
          ~add:(fun ~key:_ ~data:branch count ->
            match intent_of_branch branch with
            | Some `Error -> { count with error = count.error + 1 }
            | Some `Warning -> { count with warning = count.warning + 1 }
            | Some `Success -> { count with success = count.success + 1 }
            | Some `Accent -> { count with accent = count.accent + 1 }
            | None -> count)
          ~remove:(fun ~key:_ ~data:branch count ->
            match intent_of_branch branch with
            | Some `Error -> { count with error = count.error - 1 }
            | Some `Warning -> { count with warning = count.warning - 1 }
            | Some `Success -> { count with success = count.success - 1 }
            | Some `Accent -> { count with accent = count.accent - 1 }
            | None -> count)
      and data in
      common
        ~children_total_score
        ~has_leaf_child
        ~children_intent:(counts_to_intent children_intent)
        ~key
        ~data
    in
    let nonincremental ~key ~data ~children =
      let children_total_score = Map.sum (module Int) children ~f:score_of_branch in
      let children_intent =
        Map.fold
          children
          ~init:{ error = 0; warning = 0; success = 0; accent = 0 }
          ~f:(fun ~key:_ ~data:branch count ->
            match intent_of_branch branch with
            | Some `Error -> { count with error = count.error + 1 }
            | Some `Warning -> { count with warning = count.warning + 1 }
            | Some `Success -> { count with success = count.success + 1 }
            | Some `Accent -> { count with accent = count.accent + 1 }
            | None -> count)
      in
      common
        ~children_total_score
        ~has_leaf_child:(has_leaf_child children)
        ~children_intent:(counts_to_intent children_intent)
        ~key
        ~data
    in
    Bonsai_web_ui_tree_table.How_to_map.incrementally_with_nonincremental_fallback
      ~incremental
      ~nonincremental
      ()
  in
  Bonsai.Incr.compute
    (Bonsai.both search items_by_path)
    ~f:(fun filter_and_items_by_path ->
      tree_of_items' filter_and_items_by_path
      |> Bonsai_web_ui_tree_table.map ~how_to_map
      |> Bonsai_web_ui_tree_table.tree_to_map ~how_to_deal_with_nones:Preserve)
    graph
;;

let compare_tree_rows ~compare =
  let key = Bonsai_web_ui_tree_table.Row.key in
  let compare_row = Bonsai_web_ui_tree_table.Row.lift_comparison compare in
  let compare = Bonsai_web_ui_tree_table.Row.sort_override Path.compare compare_row in
  fun lhs rhs -> compare (key lhs, lhs) (key rhs, rhs)
;;

let compare_tree_rows_by_score ~compare_key =
  let compare (_, (score, _, _)) (_, (score', _, _)) =
    (* Ascending here translates to best total score first in the list. *)
    Int.ascending score score'
  in
  let compare =
    Comparable.lexicographic [ compare; Comparable.lift compare_key ~f:(fun (k, _) -> k) ]
  in
  compare_tree_rows ~compare
;;

let compare_tree_rows_by_item ~compare_item ~compare_key =
  let compare (key, (_, _, branch)) (key', (_, _, branch')) =
    match Branch.item branch, Branch.item branch' with
    | Some item, Some item' ->
      let cmp = compare_item item item' in
      if cmp = 0 then compare_key key key' else cmp
    | _ -> compare_key key key'
  in
  compare_tree_rows ~compare
;;

let collapsed_state graph =
  let collapsed, set_collapsed = Bonsai.state' Path.Set.empty graph in
  let toggle =
    let%arr set_collapsed in
    fun path ->
      set_collapsed (fun collapsed ->
        if Set.mem collapsed path
        then Set.remove collapsed path
        else Set.add collapsed path)
  in
  collapsed, toggle
;;

let component
  (type a)
  ?collapsed:external_collapsed_state
  ?(layout = Bonsai.return Layout.Tree)
  ?(merge_empty_paths = true)
  ?compare_path
  ?compare
  ?(filter = Bonsai.return "")
  ?on_click
  ?on_contextmenu
  ?highlight
  ?(decoration =
    fun _ data : Decoration.t -> if Option.is_some data then Primary else Secondary)
  ?(alternating_row_background = false)
  ?(disable_keyboard_navigation = false)
  ?segment:(render_segment =
      fun _ segment (local_ _graph) ->
        let%arr segment in
        Path_segment.component segment)
  ?item:(render_item = fun path segment _ graph -> render_segment path segment graph)
  (items_by_path : a Path.Map.t Bonsai.t)
  (local_ graph)
  =
  let collapsed_paths, toggle_collapsed =
    match external_collapsed_state with
    | None -> collapsed_state graph
    | Some state -> state
  in
  let on_contextmenu =
    match on_contextmenu with
    | None -> return (fun _ _ _ -> Effect.Ignore)
    | Some on_contextmenu ->
      let menu, set_menu = Bonsai.state [] graph in
      let%arr on_contextmenu
      and set_menu
      and show_menu = Skyline_context_menu_v1.manual_position menu graph in
      fun event path item ->
        (match%bind.Effect on_contextmenu path item with
         | [] -> Effect.Ignore
         | _ :: _ as menu ->
           Js_of_ocaml.Dom.preventDefault event;
           Js_of_ocaml.Dom_html.stopPropagation event;
           let get num_opt ~default =
             Js_of_ocaml.Js.Optdef.to_option num_opt
             |> Option.value ~default
             |> Js_of_ocaml.Js.to_float
           in
           let top = get event##.pageY ~default:event##.clientY in
           let left = get event##.pageX ~default:event##.clientX in
           let%bind.Effect () = set_menu menu in
           show_menu ~top ~left)
  in
  let search =
    let%arr filter in
    if String.is_empty (String.strip filter)
    then None
    else Some (Fuzzy_search.Query.create filter)
  in
  match%sub layout with
  | Tree ->
    let tree =
      let on_click =
        (* If there is [Some on_click] and [on_click path item] resolves to [Some effect],
           then attach the effect to the row, which means you have to click exactly the
           little chevron to [toggle_collapsed]. Else [toggle_collapsed path] when
           clicking any part of the row. *)
        match on_click with
        | Some on_click ->
          let%arr on_click and toggle_collapsed in
          fun path elt ->
            (match on_click path elt with
             | None -> toggle_collapsed path
             | Some on_click -> on_click)
        | None ->
          let%arr toggle_collapsed in
          fun path _ -> toggle_collapsed path
      in
      Bonsai.assoc
        (module Path)
        (tree_of_items ~merge_empty_paths ~search ~decoration items_by_path graph)
        ~f:(fun key row (local_ graph) ->
          let%arr row
          and view =
            tree_row
              ~collapsed_paths
              ~toggle_collapsed
              ~search
              ~on_click
              ~on_contextmenu
              ~highlight
              ~render_segment
              ~render_item
              ~alternating_row_background
              ~disable_keyboard_navigation
              key
              row
              graph
          in
          row, view)
        graph
    in
    (match%sub search with
     | Some _ ->
       let%arr tree in
       let sorted_rows =
         let compare_key = Option.value compare_path ~default:Path.compare in
         let compare = compare_tree_rows_by_score ~compare_key in
         List.filter_map (Map.data tree) ~f:(function
           | row, Some view -> Some (row, view)
           | _, None -> None)
         |> List.sort ~compare:(fun (row, _) (row', _) -> compare row row')
         |> List.map ~f:snd
       in
       if List.is_empty sorted_rows
       then Skyline_placeholder_v1.component ~icon:Search_stop "No matching items"
       else View.vbox ~attrs:[ Style.container ] sorted_rows
     | None ->
       let%arr tree in
       let rows =
         let custom_compare =
           match compare with
           | None ->
             let%map.Option compare_path in
             compare_tree_rows_by_item
               ~compare_item:(fun _ _ -> 0)
               ~compare_key:compare_path
           | Some compare_item ->
             let compare_key = Option.value compare_path ~default:Path.compare in
             Some (compare_tree_rows_by_item ~compare_item ~compare_key)
         in
         match custom_compare with
         | None -> List.filter_map (Map.data tree) ~f:snd
         | Some compare ->
           List.filter_map (Map.data tree) ~f:(function
             | row, Some view -> Some (row, view)
             | _, None -> None)
           |> List.sort ~compare:(fun (row, _) (row', _) -> compare row row')
           |> List.map ~f:snd
       in
       View.vbox ~attrs:[ Style.container ] rows)
  | List ->
    let list =
      let on_click =
        match on_click with
        | Some on_click -> on_click
        | None -> Bonsai.return (fun _ _ -> None)
      in
      Bonsai.assoc
        (module Path)
        items_by_path
        ~f:(fun key item graph ->
          Bonsai.both
            (list_row
               ~search
               ~highlight
               ~decoration
               ~render_item
               ~on_click
               ~on_contextmenu
               ~alternating_row_background
               ~disable_keyboard_navigation
               key
               item
               graph)
            item)
        graph
    in
    (match%sub search with
     | Some query ->
       let%arr query and list in
       let compare =
         match compare with
         | Some compare ->
           (* If we are searching, the custom compare function should be a tiebreaker. *)
           fun (score1, (_, x)) (score2, (_, y)) ->
           (match [%compare: int] score1 score2 with
            | 0 -> compare x y
            | r -> r)
         | None -> [%compare: int * _]
       in
       let sorted_rows =
         List.filter_map (Map.to_alist list) ~f:(fun (key, row) ->
           let%map.Option score =
             Fuzzy_search.score_opt query ~item:(Path.to_string key)
           in
           score, row)
         |> List.sort ~compare
         |> List.map ~f:snd
         |> List.map ~f:fst
       in
       View.vbox
         ~attrs:[ Style.container ]
         (if List.is_empty sorted_rows
          then [ Skyline_placeholder_v1.component ~icon:Search_stop "No matching items" ]
          else sorted_rows)
     | None ->
       let%arr list in
       let sorted_rows =
         match compare with
         | None -> Map.data list
         | Some compare ->
           let compare (_, x) (_, y) = compare x y in
           List.sort ~compare (Map.data list)
       in
       View.vbox
         ~attrs:[ Style.container ]
         ~cross_axis_alignment:Stretch
         (List.map ~f:fst sorted_rows))
;;
