open! Core

let matching_sections_in_substring ~matching_indices ~pos ~substring =
  let pos_end_exclusive = pos + String.length substring in
  let indices_in_substring =
    Array.filter_map
      ~f:(fun idx -> Option.some_if (idx >= pos && idx < pos_end_exclusive) (idx - pos))
      matching_indices
  in
  match indices_in_substring with
  | [||] -> [ `Not_matching, substring ]
  | indices ->
    let sections = Queue.create () in
    let add matches start end_inclusive =
      Queue.enqueue
        sections
        (matches, String.sub substring ~pos:start ~len:(end_inclusive - start + 1))
    in
    let first = indices.(0) in
    if first > 0 then add `Not_matching 0 (first - 1);
    let range_start = ref first in
    let range_end = ref first in
    Array.iter indices ~f:(fun idx ->
      if idx > !range_end + 1
      then (
        add `Matching !range_start !range_end;
        add `Not_matching (!range_end + 1) (idx - 1);
        range_start := idx);
      range_end := idx);
    add `Matching !range_start !range_end;
    if !range_end < String.length substring - 1
    then add `Not_matching (!range_end + 1) (String.length substring - 1);
    Queue.to_list sections
;;
