open! Core
open! Private_skyline_prelude

type 'a t =
  query_for_suggestions:string Bonsai.t -> local_ Bonsai.graph -> 'a list Bonsai.t

let default_worker_threshold = 10_000

let create_from_iarray
  ~to_search_string
  ?fallback_items
  ?max_suggestions
  ?(worker_threshold = default_worker_threshold)
  items
  : 'a t
  =
  fun ~query_for_suggestions (local_ graph) ->
  let filtered =
    Local_data_source.of_iarray
      ~items
      ~query_for_suggestions
      ~to_search_string
      ~max_suggestions
      ~worker_threshold
      graph
  in
  Local_data_source.merge_with_fallback filtered ~fallback_items graph
;;

let create_from_list
  ~to_search_string
  ?fallback_items
  ?max_suggestions
  ?(worker_threshold = default_worker_threshold)
  items
  : 'a t
  =
  fun ~query_for_suggestions (local_ graph) ->
  let filtered =
    Local_data_source.of_list
      ~items
      ~query_for_suggestions
      ~to_search_string
      ~max_suggestions
      ~worker_threshold
      graph
  in
  Local_data_source.merge_with_fallback filtered ~fallback_items graph
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
