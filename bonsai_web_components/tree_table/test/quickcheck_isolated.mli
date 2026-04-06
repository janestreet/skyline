open! Core
open! Util

val incrementally
  :  (module Incremental.S)
  -> ?max_incremental_recursion_depth:int
  -> ?map_to_tree_instrumentation:Incr_map.Instrumentation.t
  -> ?map_instrumentation:
       (depth:int -> step:[ `mapi' | `nonincremental ] -> Incr_map.Instrumentation.t)
  -> ?tree_to_map_instrumentation:
       (depth:int
        -> step:[ `mapi' | `filter_mapi' | `collapse_by | `nonincremental ]
        -> Incr_map.Instrumentation.t)
  -> 'a Nonempty_string_list.Map.t
  -> ( Nonempty_string_list.t
       , (Nonempty_string_list.t, 'a) Bonsai_web_ui_tree_table.Row.t
       , String.comparator_witness Nonempty_list.comparator_witness )
       Map.t
