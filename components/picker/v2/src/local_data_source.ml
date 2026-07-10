open! Core
open! Private_skyline_prelude

type 'a t =
  { filtered : 'a iarray Bonsai.t
  ; query_for_suggestions : string Bonsai.t
  ; max_suggestions : int option
  }

let create
  (type collection elt)
  ~length
  ~(to_iarray_map : 'out. collection -> f:(elt -> 'out) @ local -> 'out iarray)
  ~is_iarray
  ~(items : collection Bonsai.t)
  ~to_search_string
  ~query_for_suggestions
  ~max_suggestions
  ~worker_threshold
  (graph @ local)
  : elt t
  =
  let use_worker =
    let%arr items in
    length items >= worker_threshold
  in
  { query_for_suggestions
  ; max_suggestions
  ; filtered =
      (match%sub use_worker with
       | false ->
         Incremental_cached_filter.component
           ~items
           ~query_for_suggestions
           ~to_search_string
           ~to_iarray:to_iarray_map
           graph
       | true ->
         Bonsai.delay graph ~f:(fun (graph @ local) ->
           let items : elt iarray Bonsai.t =
             match is_iarray with
             | Some (T : (collection, elt iarray) Type_equal.t) -> items
             | None ->
               let%arr items in
               to_iarray_map items ~f:Fn.id
           in
           Worker_filter.component
             ~items
             ~max_suggestions
             ~query_for_suggestions
             ~to_search_string
             graph))
  }
;;

let of_iarray
  ~items
  ~to_search_string
  ~query_for_suggestions
  ~max_suggestions
  ~worker_threshold
  (graph @ local)
  : 'a t
  =
  create
    ~length:Iarray.length
    ~to_iarray_map:Iarray.map
    ~is_iarray:(Some T)
    ~items
    ~to_search_string
    ~query_for_suggestions
    ~max_suggestions
    ~worker_threshold
    graph
;;

let of_list
  ~items
  ~to_search_string
  ~query_for_suggestions
  ~max_suggestions
  ~worker_threshold
  (graph @ local)
  : 'a t
  =
  create
    ~length:List.length
    ~to_iarray_map:Iarray.of_list_map
    ~is_iarray:None
    ~items
    ~to_search_string
    ~query_for_suggestions
    ~max_suggestions
    ~worker_threshold
    graph
;;

let merge_with_fallback
  { filtered; query_for_suggestions; max_suggestions }
  ~fallback_items
  (_ : Bonsai.graph @ local)
  =
  let fallback_items =
    match fallback_items with
    | None -> Bonsai.return []
    | Some fallback_items ->
      let%arr fallback_items and query_for_suggestions in
      let l = fallback_items ~query:query_for_suggestions in
      (match max_suggestions with
       | None -> l
       | Some n -> List.take l n)
  in
  let%arr filtered and fallback_items in
  let num_filtered =
    match max_suggestions with
    | None -> Iarray.length filtered
    | Some n ->
      let num_fallback = List.length fallback_items in
      Int.max 0 (Int.min (Iarray.length filtered) (n - num_fallback))
  in
  let mutable acc = fallback_items in
  for i = num_filtered - 1 downto 0 do
    acc <- Iarray.unsafe_get filtered i :: acc
  done;
  acc
;;
