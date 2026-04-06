open! Core

(** Compute matching sections from an array of matching indices (e.g. obtained from
    [Fuzzy_search.matching_indices]). [pos] is the start of [substring] in the original
    string that was matched on. *)
val matching_sections_in_substring
  :  matching_indices:int array
  -> pos:int
  -> substring:string
  -> ([> `Matching | `Not_matching ] * string) list
