open! Core
open Incremental.Let_syntax

module Make_nonempty_list_comparator (T : Comparator.S) = struct
  type t = T.t Nonempty_list.t

  let sexp_of_t = Nonempty_list.sexp_of_t (Comparator.sexp_of_t T.comparator)
  let comparator = Nonempty_list.comparator T.comparator

  type comparator_witness = T.comparator_witness Nonempty_list.comparator_witness
end

module Row = struct
  (* rows need to track the values from their ancestors in order for the sort on a tree
     structure to work. *)
  type ('key, 'data) t =
    { key : 'key
    ; data : 'data
    ; me_and_ancestors : (* [me; parent; grandparent; ...] *)
        ('key * 'data) list
    ; me_and_ancestors_reversed :
        (* lazy [...; grandparent; parent; me] *)
        ('key * 'data) list Lazy.t
    }

  let sexp_of_t sexp_of_key sexp_of_data { me_and_ancestors; key; data; _ } =
    match List.tl me_and_ancestors with
    | None | Some [] -> [%sexp (key : key), (data : data)]
    | Some ancestors ->
      [%sexp (key : key), (data : data), { ancestors : (key * data) list }]
  ;;

  let create ~key ~data ~ancestors =
    let me_and_ancestors = (key, data) :: ancestors in
    let me_and_ancestors_reversed = lazy (List.rev me_and_ancestors) in
    { key; data; me_and_ancestors; me_and_ancestors_reversed }
  ;;

  let lift_comparison f (_, a) (_, b) = f (a.key, a.data) (b.key, b.data)
  let key { key; _ } = key
  let data { data; _ } = data
  let ancestors { me_and_ancestors; _ } = List.drop me_and_ancestors 1
  let ancestor_count { me_and_ancestors; _ } = List.length me_and_ancestors - 1

  let sort_override compare_key compare =
    let lifted =
      Comparable.lexicographic
        [ Comparable.lift compare ~f:(fun (key, data) ->
            ( key
            , { key
              ; data
              ; me_and_ancestors = []
              ; me_and_ancestors_reversed = Lazy.from_val []
              } ))
        ; Comparable.lift compare_key ~f:(fun (key, _) -> key)
        ]
    in
    Comparable.lift
      (List.compare lifted)
      ~f:(fun (_, { me_and_ancestors_reversed = (lazy a); _ }) -> a)
  ;;

  let map_data { key; data; me_and_ancestors; me_and_ancestors_reversed = _ } ~f =
    let data = f data in
    let me_and_ancestors = List.map me_and_ancestors ~f:(fun (k, v) -> k, f v) in
    let me_and_ancestors_reversed = lazy (List.rev me_and_ancestors) in
    { key; data; me_and_ancestors; me_and_ancestors_reversed }
  ;;

  let map_data_skipping_ancestors_not_impacting_sorting t ~f = { t with data = f t.data }
end

module Tree0 = struct
  type ('k, 'v, 'cmp) branch =
    { path : 'k Nonempty_list.t
    ; data : 'v
    ; children : ('k, 'v, 'cmp) children
    }

  and ('k, 'v, 'cmp) children = ('k, ('k, 'v, 'cmp) branch, 'cmp) Map.t

  and ('k, 'v, 'cmp) t =
    { comparator : ('k, 'cmp) Comparator.Module.t
    ; top_level : ('k, 'v, 'cmp) children
    }

  let top_level { top_level; _ } = top_level
  let comparator { comparator; _ } = comparator
  let data { data; _ } = data

  let rec set branches cmp ~key ~path_prefix ~remaining_keys ~data =
    let path = key :: path_prefix in
    Map.update branches key ~f:(fun branch ->
      let branch =
        match branch with
        | Some branch -> branch
        | None ->
          { path = Nonempty_list.of_list_exn (List.rev path)
          ; data = None
          ; children = Map.empty cmp
          }
      in
      let branch =
        match remaining_keys with
        | [] -> { branch with data = Some data }
        | next_key :: remaining_keys ->
          let children =
            set branch.children cmp ~key:next_key ~path_prefix:path ~remaining_keys ~data
          in
          { branch with children }
      in
      branch)
  ;;

  let set branches ~key ~remaining_keys ~data =
    let cmp = Map.comparator_s branches in
    set branches cmp ~key ~remaining_keys ~data ~path_prefix:[]
  ;;

  (* Remove a path from the tree, being careful to prune empty branches on the way back
     up. *)
  let rec remove branches ~key ~remaining_keys =
    Map.change branches key ~f:(function
      | None -> None
      | Some branch ->
        (match remaining_keys with
         | [] ->
           if Map.is_empty branch.children then None else Some { branch with data = None }
         | next_key :: remaining_keys ->
           let new_children = remove branch.children ~key:next_key ~remaining_keys in
           if Map.is_empty new_children && Option.is_none branch.data
           then None
           else Some { branch with children = new_children }))
  ;;
end

let map_to_tree ?instrumentation comparator map =
  let add_and_update ~key ~data acc =
    let (key :: remaining_keys : _ Nonempty_list.t) = key in
    { acc with
      Tree0.top_level = Tree0.set acc.Tree0.top_level ~key ~remaining_keys ~data
    }
  in
  Incr_map.unordered_fold
    ?instrumentation
    map
    ~init:{ Tree0.comparator; top_level = Map.empty comparator }
    ~add:add_and_update
    ~update:(fun ~key ~old_data:_ ~new_data:data acc -> add_and_update ~key ~data acc)
    ~remove:(fun ~key ~data:_ acc ->
      let (key :: remaining_keys : _ Nonempty_list.t) = key in
      { acc with top_level = Tree0.remove acc.top_level ~key ~remaining_keys })
;;

let rec fill_holes_non_incremental branches ~f =
  Map.mapi branches ~f:(fun ~key:_ ~data:branch ->
    let { Tree0.children; data; path } = branch in
    let children = fill_holes_non_incremental children ~f in
    let data = f ~key:path ~data ~children in
    { Tree0.children; data; path })
;;

let rec fill_holes_incremental
  ~instrumentation
  ~comparator_opt
  ~depth
  ~incremental_recursion_budget
  branches
  ~f_incr
  ~f_non_incr
  =
  let open Incremental.Let_syntax in
  match incremental_recursion_budget > 0 with
  | true ->
    let incremental_recursion_budget = incremental_recursion_budget - 1 in
    Incr_map.mapi'
      ?instrumentation:(instrumentation ~depth ~step:`mapi')
      branches
      ~f:(fun ~key:_ ~data:branch ->
        let%pattern_bind { Tree0.children; data; path } = branch in
        let%bind path in
        let children =
          fill_holes_incremental
            ~instrumentation
            ~comparator_opt
            ~depth:(depth + 1)
            ~incremental_recursion_budget
            children
            ~f_incr
            ~f_non_incr
        in
        let%mapn children
        and data = f_incr ~key:path ~data ~children in
        { Tree0.children; data; path })
  | false ->
    let { Incr_map.Instrumentation.f } =
      instrumentation ~depth ~step:`nonincremental
      |> Option.value ~default:{ f = (fun f -> f ()) }
    in
    let%mapn branches in
    f (fun () -> fill_holes_non_incremental branches ~f:f_non_incr)
;;

module How_to_map = struct
  type ('k, 'v, 'cmp) branches = ('k, ('k, 'v, 'cmp) Tree0.branch, 'cmp) Map.t

  type ('path_elt, 'cmp, 'a, 'b, 'w) t =
    | Nonincrementally of
        { f :
            key:'path_elt Nonempty_list.t
            -> data:'a
            -> children:('path_elt, 'b, 'cmp) branches
            -> 'b
        }
    | Incrementally of
        { f :
            key:'path_elt Nonempty_list.t
            -> data:('a, 'w) Incremental.t
            -> children:(('path_elt, 'b, 'cmp) branches, 'w) Incremental.t
            -> ('b, 'w) Incremental.t
        ; comparator : ('path_elt, 'cmp) Comparator.Module.t option
        }
    | Switch_when_depth_exceeded of
        { switch_from_incremental_to_nonincremental_at_this_depth : int option
        ; nonincremental :
            key:'path_elt Nonempty_list.t
            -> data:'a
            -> children:('path_elt, 'b, 'cmp) branches
            -> 'b
        ; incremental :
            key:'path_elt Nonempty_list.t
            -> data:('a, 'w) Incremental.t
            -> children:(('path_elt, 'b, 'cmp) branches, 'w) Incremental.t
            -> ('b, 'w) Incremental.t
        ; comparator : ('path_elt, 'cmp) Comparator.Module.t option
        }

  let nonincrementally callback = Nonincrementally { f = callback }
  let incrementally ?comparator callback = Incrementally { f = callback; comparator }

  let incrementally_with_nonincremental_fallback
    ?switch_from_incremental_to_nonincremental_at_this_depth
    ?comparator
    ~nonincremental
    ~incremental
    ()
    =
    Switch_when_depth_exceeded
      { switch_from_incremental_to_nonincremental_at_this_depth
      ; nonincremental
      ; incremental
      ; comparator
      }
  ;;
end

let map ?instrumentation t ~how_to_map =
  let instrumentation ~depth ~step =
    let%map.Option instrumentation in
    instrumentation ~depth ~step
  in
  let max_incremental_recursion_depth =
    match (how_to_map : _ How_to_map.t) with
    | Nonincrementally _ -> 8
    | Incrementally _ -> Int.max_value
    | Switch_when_depth_exceeded
        { switch_from_incremental_to_nonincremental_at_this_depth; _ } ->
      Option.value switch_from_incremental_to_nonincremental_at_this_depth ~default:8
  in
  let f_incr, f_non_incr, comparator_opt =
    match (how_to_map : _ How_to_map.t) with
    | Nonincrementally { f = f_non_incr } ->
      let f_incr ~key ~data ~children =
        let%mapn data and children in
        f_non_incr ~key ~data ~children
      in
      f_incr, f_non_incr, None
    | Incrementally { f; comparator } ->
      let f_non_incr ~key:_ ~data:_ ~children:_ = raise_s [%message "BUG" [%here]] in
      f, f_non_incr, comparator
    | Switch_when_depth_exceeded { nonincremental; incremental; comparator; _ } ->
      incremental, nonincremental, comparator
  in
  let%mapn top_level =
    fill_holes_incremental
      ~instrumentation
      ~comparator_opt
      ~depth:0
      ~incremental_recursion_budget:max_incremental_recursion_depth
      (t >>| Tree0.top_level)
      ~f_incr
      ~f_non_incr
  and t in
  { t with top_level }
;;

type (_, _) how_to_deal_with_nones =
  | Preserve : ('a, 'a) how_to_deal_with_nones
  | Remove_and_also_remove_descendants : ('a option, 'a) how_to_deal_with_nones

let rec tree_to_map_common_nonincremental branches ~comparator g ~ancestors ~f =
  let recurse ~path ~data ~children =
    let ancestors = (path, data) :: ancestors in
    tree_to_map_common_nonincremental children ~comparator g ~ancestors ~f
  in
  Map.fold
    (g branches ~f:(fun ~key:_ ~data:branch ->
       let this_row ~path ~data = Row.create ~key:path ~data ~ancestors in
       f ~recurse ~this_row branch))
    ~init:(Map.empty comparator)
    ~f:(fun ~key:_ ~data acc ->
      Map.merge_skewed acc data ~combine:(fun ~key:_ -> raise_s [%message "BUG" [%here]]))
;;

let tree_to_map_common_incremental
  ~comparator
  ~recurse
  ~g
  ~f
  ~branches
  ~ancestors
  ~instrumentation
  ~depth
  =
  Incr_map.collapse_by
    ?instrumentation:(instrumentation ~depth ~step:`collapse_by)
    (g ~depth branches ~f:(fun ~key:_ ~data:branch ->
       let this_row =
         let%mapn ancestors in
         fun ~path ~data -> Row.create ~key:path ~data ~ancestors
       in
       f ~recurse ~this_row branch))
    ~merge_keys:(fun _outer_key inner_key -> inner_key)
    ~comparator
;;

let rec tree_to_map_common
  ~max_incremental_recursion_depth
  ~depth
  branches
  ~comparator
  g
  g'
  ~ancestors
  ~f_incr
  ~f_non_incr
  ~instrumentation
  =
  match max_incremental_recursion_depth > 0 with
  | true ->
    let max_incremental_recursion_depth = max_incremental_recursion_depth - 1 in
    let recurse ~path ~data ~children =
      let ancestors =
        let%mapn path and data and ancestors in
        (path, data) :: ancestors
      in
      tree_to_map_common
        ~depth:(depth + 1)
        ~max_incremental_recursion_depth
        children
        ~comparator
        g
        g'
        ~ancestors
        ~f_incr
        ~f_non_incr
        ~instrumentation
    in
    tree_to_map_common_incremental
      ~comparator
      ~recurse
      ~g
      ~f:f_incr
      ~branches
      ~ancestors
      ~instrumentation
      ~depth
  | false ->
    let { Incr_map.Instrumentation.f } =
      instrumentation ~depth ~step:`nonincremental
      |> Option.value ~default:{ f = (fun f -> f ()) }
    in
    let%mapn branches and ancestors in
    f (fun () ->
      tree_to_map_common_nonincremental branches ~comparator g' ~ancestors ~f:f_non_incr)
;;

let tree_to_map_common
  branches
  ~max_incremental_recursion_depth
  ~comparator
  g
  g'
  ~f_incr
  ~f_non_incr
  ~instrumentation
  =
  let state = Incremental.state branches in
  tree_to_map_common
    ~max_incremental_recursion_depth
    branches
    ~comparator
    g
    g'
    ~f_incr
    ~f_non_incr
    ~ancestors:(Incremental.return state [])
    ~instrumentation
    ~depth:0
;;

let tree_to_map_preserving_nones
  branches
  ~max_incremental_recursion_depth
  ~comparator
  ~instrumentation
  =
  let g ~depth a =
    Incr_map.mapi' ?instrumentation:(instrumentation ~depth ~step:`mapi') a
  in
  let g' a = Map.mapi a in
  let f_incr ~recurse ~this_row branch =
    let%pattern_bind { Tree0.children; data; path } = branch in
    let%mapn children = recurse ~path ~data ~children
    and data
    and path
    and this_row in
    Map.add_exn children ~key:path ~data:(this_row ~path ~data)
  in
  let f_non_incr ~recurse ~this_row branch =
    let { Tree0.children; data; path } = branch in
    let children = recurse ~path ~data ~children in
    Map.add_exn children ~key:path ~data:(this_row ~path ~data)
  in
  tree_to_map_common
    branches
    ~max_incremental_recursion_depth
    ~comparator
    g
    g'
    ~f_incr
    ~f_non_incr
    ~instrumentation
;;

let tree_to_map_removing_nones_and_their_descendants
  branches
  ~max_incremental_recursion_depth
  ~comparator
  ~instrumentation
  =
  let g ~depth a =
    Incr_map.filter_mapi' ?instrumentation:(instrumentation ~depth ~step:`filter_mapi') a
  in
  let g' a = Map.filter_mapi a in
  let f_incr ~recurse ~this_row branch =
    let state = Incremental.state branch in
    let%pattern_bind { Tree0.children; data; path } = branch in
    match%pattern_bind data with
    | None -> Incremental.return state None
    | Some data ->
      let%mapn children = recurse ~path ~data ~children
      and data
      and path
      and this_row in
      Some (Map.add_exn children ~key:path ~data:(this_row ~path ~data))
  in
  let f_non_incr ~recurse ~this_row branch =
    let { Tree0.children; data; path } = branch in
    Option.map data ~f:(fun data ->
      let children = recurse ~path ~data ~children in
      Map.add_exn children ~key:path ~data:(this_row ~path ~data))
  in
  tree_to_map_common
    branches
    ~max_incremental_recursion_depth
    ~comparator
    g
    g'
    ~f_incr
    ~f_non_incr
    ~instrumentation
;;

let branches_to_map
  : type k i o cmp.
    (k, cmp) Comparator.Module.t
    -> max_incremental_recursion_depth:int
    -> how_to_deal_with_nones:(i, o) how_to_deal_with_nones
    -> instrumentation:
         (depth:int
          -> step:[ `mapi' | `filter_mapi' | `collapse_by | `nonincremental ]
          -> Incr_map.Instrumentation.t option)
    -> ((k, i, cmp) Tree0.children, 'w) Incremental.t
    -> ( ( k Nonempty_list.t
           , (k Nonempty_list.t, o) Row.t
           , cmp Nonempty_list.comparator_witness )
           Map.t
         , 'w )
         Incremental.t
  =
  fun item_comparator
    ~max_incremental_recursion_depth
    ~how_to_deal_with_nones
    ~instrumentation
    branches ->
  let module C = struct
    type t = k Nonempty_list.t
    type comparator_witness = cmp Nonempty_list.comparator_witness

    module T = (val item_comparator)

    let comparator = Nonempty_list.comparator T.comparator
  end
  in
  match how_to_deal_with_nones with
  | Preserve ->
    tree_to_map_preserving_nones
      branches
      ~max_incremental_recursion_depth
      ~comparator:(module C)
      ~instrumentation
  | Remove_and_also_remove_descendants ->
    tree_to_map_removing_nones_and_their_descendants
      branches
      ~max_incremental_recursion_depth
      ~comparator:(module C)
      ~instrumentation
;;

let tree_to_map
  ?instrumentation
  ?(max_incremental_recursion_depth = 8)
  ~how_to_deal_with_nones
  tree
  =
  let instrumentation ~depth ~step =
    let%map.Option instrumentation in
    instrumentation ~depth ~step
  in
  let branches = tree >>| Tree0.top_level in
  let%bind comparator = tree >>| Tree0.comparator in
  branches_to_map
    comparator
    ~max_incremental_recursion_depth
    ~how_to_deal_with_nones
    ~instrumentation
    branches
;;

module Tree = struct
  include Tree0

  let empty comparator = { comparator; top_level = Map.empty comparator }

  let set t ~key ~data =
    let Nonempty_list.(key :: remaining_keys) = key in
    { t with top_level = set ~key ~remaining_keys ~data t.top_level }
  ;;

  let remove t key =
    let Nonempty_list.(key :: remaining_keys) = key in
    { t with top_level = remove ~key ~remaining_keys t.top_level }
  ;;
end
