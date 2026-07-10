open! Core
open Bonsai_web

(** An asynchronous filter implementation where the work of scoring and filtering is
    offloaded to a web worker.

    This has the same caching behavior as {!Incremental_cached_filter}: As long as the
    user keeps extending their query, filtering reuses the previous stage of results
    rather than reprocess a large input set from scratch. *)
val component
  :  items:'a iarray Bonsai.t
  -> max_suggestions:int option
  -> query_for_suggestions:string Bonsai.t
  -> to_search_string:('a -> string)
  -> Bonsai.graph @ local
  -> 'a iarray Bonsai.t
