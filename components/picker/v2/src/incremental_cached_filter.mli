open! Core
open Bonsai_web

(** A synchronous filter implementation with incremental refinement: As long as the user
    keeps extending their query, filtering reuses the previous stage of results rather
    than reprocess a large input set from scratch. *)

val component
  :  items:'collection Bonsai.t
  -> query_for_suggestions:string Bonsai.t
  -> to_search_string:('elt -> string)
  -> to_iarray:('out. 'collection -> f:('elt -> 'out) @ local -> 'out iarray)
  -> Bonsai.graph @ local
  -> 'elt iarray Bonsai.t
