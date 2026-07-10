open! Core
open Skyline_picker_v2_typeahead_search_worker_protocol

module Scored_index = struct
  type t =
    { score : int
    ; original_index : int
    ; item : string [@compare.ignore]
    }
  [@@deriving compare, fields ~getters]

  let of_iarray x =
    Iarray.mapi x ~f:(stack_ fun original_index item ->
      { original_index; item; score = 1 })
    [@nontail]
  ;;
end

type t =
  { mutable search_strings : Scored_index.t iarray
  ; mutable prev_query : string
  ; mutable prev_indices : Scored_index.t iarray or_null
  ; mutable max_results : int or_null
  ; post_message : From_worker.t -> unit
  }

let create ~post_message () =
  { search_strings = Iarray.empty
  ; prev_query = ""
  ; prev_indices = Null
  ; max_results = Null
  ; post_message
  }
;;

let score_and_sort input ~fuzzy_query =
  let scored : Scored_index.t Queue.t = Queue.create () in
  for index = 0 to Iarray.length input - 1 do
    let%tydi { item; original_index; score = _ } : Scored_index.t =
      Iarray.unsafe_get input index
    in
    let score = Fuzzy_search.score fuzzy_query ~item in
    if score <> 0 then Queue.enqueue scored { item; original_index; score }
  done;
  let scored = Queue.to_array scored in
  Array.sort scored ~compare:Scored_index.compare;
  Iarray.unsafe_of_array__promise_no_mutation scored
;;

let search ~input ~query : _ iarray =
  let query = String.strip query in
  match String.is_empty query with
  | true -> input
  | false -> score_and_sort input ~fuzzy_query:(Fuzzy_search.Query.create query)
;;

let from_scratch t ~query : _ iarray = search ~query ~input:t.search_strings

let handle_message t (message : To_worker.message) =
  let%tydi { new_index; query; generation; max_results } = To_worker.parse message in
  t.max_results <- max_results;
  (match new_index with
   | Null -> ()
   | This data ->
     t.search_strings <- Scored_index.of_iarray data;
     (* Index cache is now invalid *)
     t.prev_indices <- Null);
  let all_indices =
    match t.prev_indices with
    | Null -> from_scratch t ~query
    | This prev_indices ->
      (match String.is_prefix query ~prefix:t.prev_query with
       | false -> from_scratch t ~query
       | true ->
         (* If the query is a strict suffix, just refine our existing search. *)
         search ~input:prev_indices ~query)
  in
  t.prev_query <- query;
  t.prev_indices <- This all_indices;
  let limited_indices =
    let len = Or_null.fold t.max_results ~f:Int.min ~init:(Iarray.length all_indices) in
    Indices.init len ~f:(stack_ fun i -> (Iarray.unsafe_get all_indices i).original_index)
  in
  t.post_message (Search_complete { generation; indices = limited_indices })
;;
