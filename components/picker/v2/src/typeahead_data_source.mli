open! Core
open Bonsai_web

(** A data source produces a filtered list of suggestions given a query.
    [~query_for_suggestions] controls which items are fetched/filtered. *)
type 'a t =
  query_for_suggestions:string Bonsai.t -> local_ Bonsai.graph -> 'a list Bonsai.t

(** Data source backed by a list with client-side fuzzy matching.

    [~to_search_string] is used for filtering and scoring (ordering) results.

    [?fallback_items] produces extra items from the current query that are appended after
    all filtered results. Use this for "create new" actions (e.g. "Add email:
    foo@bar.com") where items are derived from the query text rather than selected from
    the list.

    [?max_suggestions] caps the total number of suggestions shown in the dropdown.
    Fallback items count toward the cap and take precedence over scored results — e.g.
    with [~max_suggestions:5] and 2 fallback items, at most 3 scored results are shown.
    When omitted, all matching suggestions are shown. *)
val create_from_list
  :  to_search_string:('a -> string)
  -> ?fallback_items:(query:string -> 'a list) Bonsai.t
  -> ?max_suggestions:int
  -> 'a list Bonsai.t
  -> 'a t

(** Data source backed by a server-side RPC. [fetch] is expected to come from
    [Rpc_effect.Rpc.dispatcher] and should return a list of matching items. Results are
    throttled so only the latest query is in-flight. Unlike [create_from_list], the server
    is responsible for filtering and ranking — [create_from_rpc] displays items in the
    order returned. Fuzzy match highlighting is still applied client-side based on
    [~highlight]. *)
val create_from_rpc
  :  ?on_error:('a list Or_error.t -> unit Effect.t) Bonsai.t
  -> fetch:(string -> 'a list Or_error.t Effect.t) Bonsai.t
  -> unit
  -> 'a t
