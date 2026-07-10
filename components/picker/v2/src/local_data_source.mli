open! Core
open Bonsai_web

(** A client-local data source with fuzzy-match filtering and sorting.

    This is not part of the public api; see {!Typeahead_data_source} for documentation of
    parameters. *)

type 'a t

type ('a, 'collection) creator :=
  items:'collection Bonsai.t
  -> to_search_string:('a -> string)
  -> query_for_suggestions:string Bonsai.t
  -> max_suggestions:int option
  -> worker_threshold:int
  -> Bonsai.graph @ local
  -> 'a t

val of_iarray : ('a, 'a iarray) creator
val of_list : ('a, 'a list) creator

val merge_with_fallback
  :  'a t
  -> fallback_items:(query:string -> 'a list) Bonsai.t option
  -> Bonsai.graph @ local
  -> 'a list Bonsai.t
