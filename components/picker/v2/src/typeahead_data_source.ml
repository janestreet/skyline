open! Core
open! Private_skyline_prelude

type 'a t =
  query_for_suggestions:string Bonsai.t -> local_ Bonsai.graph -> 'a list Bonsai.t

let fuzzy_filter_and_score ~to_string ~items ~query =
  let fuzzy_query = Fuzzy_search.Query.create (String.strip query) in
  let scored =
    List.filter_map items ~f:(fun value ->
      let item_string = to_string value in
      let score = Fuzzy_search.score fuzzy_query ~item:item_string in
      match score with
      | 0 -> None
      | n -> Some (value, n))
  in
  List.sort scored ~compare:(fun (_, score_a) (_, score_b) -> Int.compare score_a score_b)
;;

let create_from_list ~to_search_string ?fallback_items ?max_suggestions items : 'a t =
  fun ~query_for_suggestions (local_ _graph) ->
  let filtered =
    let%arr items and query_for_suggestions in
    fuzzy_filter_and_score ~to_string:to_search_string ~items ~query:query_for_suggestions
  in
  let fallback_items =
    match fallback_items with
    | None -> Bonsai.return []
    | Some fallback_items ->
      let%arr fallback_items and query_for_suggestions in
      fallback_items ~query:query_for_suggestions
  in
  let%arr filtered and fallback_items in
  let fallback_items =
    match max_suggestions with
    | None -> fallback_items
    | Some n -> List.take fallback_items n
  in
  let filtered =
    match max_suggestions with
    | None -> filtered
    | Some n ->
      let num_fallback = List.length fallback_items in
      List.take filtered (Int.max 0 (n - num_fallback))
  in
  List.map filtered ~f:fst @ fallback_items
;;

let create_from_rpc ?on_error ~fetch () : 'a t =
  fun ~query_for_suggestions (local_ graph) ->
  let on_error =
    match on_error with
    | Some on_error -> on_error
    | None -> Bonsai.return (fun (_ : _ Or_error.t) -> Effect.Ignore)
  in
  let fetched_items =
    Bonsai_kernel_throttle.effect_throttle
      (let%arr query_for_suggestions and fetch and on_error in
       query_for_suggestions, fetch, on_error)
      ~equal:(fun (query_for_suggestions, fetch, _) (query_for_suggestions', fetch', _) ->
        String.equal query_for_suggestions query_for_suggestions'
        && phys_equal fetch fetch')
      ~wait:Time_ns.Span.zero
      ~effect:
        (Bonsai.return (fun (query, fetch, on_error) ->
           let%bind.Effect result = fetch query in
           let%bind.Effect () =
             match result with
             | Error _ -> on_error result
             | Ok _ -> Effect.Ignore
           in
           Effect.return result))
      graph
  in
  match%arr fetched_items with
  | None | Some (Error _) -> []
  | Some (Ok items) -> items
;;
