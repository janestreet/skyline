open! Core
open Bonsai_web

(** A data source produces a filtered list of suggestions given a query.
    [~query_for_suggestions] controls which items are fetched/filtered. *)
type 'a t =
  query_for_suggestions:string Bonsai.t -> local_ Bonsai.graph -> 'a list Bonsai.t

type ('a, 'collection) create_client_side :=
  to_search_string:('a -> string)
  -> ?fallback_items:(query:string -> 'a list) Bonsai.t
  -> ?max_suggestions:int
  -> ?worker_threshold:int
  -> 'collection Bonsai.t
  -> 'a t

(** Data source backed by a list with client-side fuzzy matching.

    [~to_search_string] is used for filtering and scoring (ordering) results.

    [?fallback_items] produces extra items from the current query that are appended after
    all filtered results. Use this for "create new" actions (e.g. "Add email:
    foo@bar.com") where items are derived from the query text rather than selected from
    the list.

    [?max_suggestions] caps the total number of suggestions shown in the dropdown.
    Fallback items count toward the cap and take precedence over scored results — e.g.
    with [~max_suggestions:5] and 2 fallback items, at most 3 scored results are shown.
    When omitted, all matching suggestions are shown.

    The list data source avoids scoring the list for an empty query, and caches fuzzy
    matches for the previous query so extending a query filters the previous result set
    rather than rescanning every item.

    [worker_threshold] sets the number of items beyond which the work of scoring is
    offloaded to a web worker; results are returned asynchronously to avoid blocking
    browser input handling (however, there may still be a noticeable pause at
    initialization when transferring inputs to the worker). Default is
    [default_worker_threshold]. *)
val create_from_list : ('a, 'a list) create_client_side

(** [create_from_iarray] behaves identically to [create_from_list], but avoids the
    overhead of internally converting to an iarray, which can reduce the pause at
    initialization for very large inputs. If your input is already an iarray or can be
    converted to an iarray cheaply (e.g
    [Set.to_array |> Iarray.unsafe_of_array__promise_no_mutation]) then this is
    preferable. *)
val create_from_iarray : ('a, 'a iarray) create_client_side

val default_worker_threshold : int

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
