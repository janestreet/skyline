open! Core
open! Util
module Tree_table = Bonsai_web_ui_tree_table

let compute
  ?map_to_tree_instrumentation
  ?map_instrumentation
  ?tree_to_map_instrumentation
  ?(incr = (module Incr : Incremental.S))
  ?max_incremental_recursion_depth
  alist
  =
  alist
  |> Map.of_alist_exn (module Nonempty_string_list)
  |> Quickcheck_isolated.incrementally
       ?map_to_tree_instrumentation
       ?map_instrumentation
       ?tree_to_map_instrumentation
       incr
       ?max_incremental_recursion_depth
  |> Map.to_alist
;;

type 'a out =
  (string Nonempty_list.t * (string Nonempty_list.t, 'a) Tree_table.Row.t) list
[@@deriving sexp_of]

let run_test
  ?incr
  ?(print_only = Int.max_value)
  ?max_incremental_recursion_depth
  ?compare
  ?(post_compute = Fn.id)
  ?map_to_tree_instrumentation
  ?map_instrumentation
  ?tree_to_map_instrumentation
  sexp_of_a
  values
  =
  let out =
    compute
      ?map_to_tree_instrumentation
      ?map_instrumentation
      ?tree_to_map_instrumentation
      ?incr
      ?max_incremental_recursion_depth
      values
  in
  let out = List.map ~f:post_compute out in
  let maybe_sorted =
    match compare with
    | None -> out
    | Some compare ->
      let compare =
        Comparable.lift compare ~f:(fun (_, row) -> Tree_table.Row.data row)
        |> Tree_table.Row.sort_override [%compare: string Nonempty_list.t]
      in
      List.sort ~compare out
  in
  List.iter (List.take maybe_sorted print_only) ~f:(fun (_, row) ->
    print_s ([%sexp_of: (string Nonempty_list.t, a) Tree_table.Row.t] row));
  if List.length maybe_sorted > print_only then print_endline "..."
;;

let%expect_test "empty tree" =
  run_test [%sexp_of: unit] [];
  [%expect {| |}]
;;

let%expect_test "singleton" =
  run_test [%sexp_of: int] [ [ "a" ], 0 ];
  [%expect {| ((a) 0) |}]
;;

let%expect_test "two top level nodes" =
  run_test [%sexp_of: int] [ [ "a" ], 1; [ "b" ], 2 ];
  [%expect
    {|
    ((a) 1)
    ((b) 2)
    |}]
;;

let%expect_test "nesting" =
  run_test [%sexp_of: int] [ [ "a" ], 1; [ "a"; "b" ], 2; [ "c" ], 3 ];
  [%expect
    {|
    ((a) 1)
    ((a b) 2 ((ancestors (((a) 1)))))
    ((c) 3)
    |}]
;;

let%expect_test "two top level nodes - sorted " =
  let compare = Comparable.reverse [%compare: int] in
  run_test ~compare [%sexp_of: int] [ [ "a" ], 1; [ "b" ], 2 ];
  [%expect
    {|
    ((b) 2)
    ((a) 1)
    |}]
;;

let%expect_test "nesting - sorted" =
  let compare = Comparable.reverse [%compare: int] in
  run_test ~compare [%sexp_of: int] [ [ "a" ], 1; [ "a"; "b" ], 2; [ "c" ], 3 ];
  [%expect
    {|
    ((c) 3)
    ((a) 1)
    ((a b) 2 ((ancestors (((a) 1)))))
    |}]
;;

let%expect_test "instrumentation" =
  let instrumented = Queue.create () in
  let map_to_tree_instrumentation =
    { Incr_map.Instrumentation.f =
        (fun f ->
          Queue.enqueue instrumented [%sexp { api_fn = "map_to_tree" }];
          f ())
    }
  in
  let map_instrumentation ~depth ~step =
    { Incr_map.Instrumentation.f =
        (fun f ->
          Queue.enqueue
            instrumented
            [%sexp { api_fn = "map"; step : [ `mapi' | `nonincremental ]; depth : int }];
          f ())
    }
  in
  let tree_to_map_instrumentation ~depth ~step =
    { Incr_map.Instrumentation.f =
        (fun f ->
          Queue.enqueue
            instrumented
            [%sexp
              { api_fn = "tree_to_map"
              ; step : [ `mapi' | `filter_mapi' | `collapse_by | `nonincremental ]
              ; depth : int
              }];
          f ())
    }
  in
  run_test
    ~max_incremental_recursion_depth:2
    ~map_to_tree_instrumentation
    ~map_instrumentation
    ~tree_to_map_instrumentation
    [%sexp_of: int]
    [ [ "a" ], 1; [ "a"; "b" ], 2; [ "a"; "b"; "c" ], 3; [ "d" ], 4 ];
  [%expect
    {|
    ((a) 1)
    ((a b) 2 ((ancestors (((a) 1)))))
    ((a b c) 3 ((ancestors (((a b) 2) ((a) 1)))))
    ((d) 4)
    |}];
  Expectable.print (Queue.to_list instrumented);
  [%expect
    {|
    ┌─────────────┬────────────────┬───────┐
    │ api_fn      │ step           │ depth │
    ├─────────────┼────────────────┼───────┤
    │ map_to_tree │                │       │
    │ map         │ mapi'          │ 0     │
    │ map         │ mapi'          │ 1     │
    │ map         │ mapi'          │ 1     │
    │ map         │ nonincremental │ 2     │
    │ tree_to_map │ filter_mapi'   │ 0     │
    │ tree_to_map │ filter_mapi'   │ 1     │
    │ tree_to_map │ filter_mapi'   │ 1     │
    │ tree_to_map │ collapse_by    │ 1     │
    │ tree_to_map │ nonincremental │ 2     │
    │ tree_to_map │ collapse_by    │ 1     │
    │ tree_to_map │ collapse_by    │ 0     │
    └─────────────┴────────────────┴───────┘
    |}]
;;

let%expect_test "Regression Test: sort ignores path" =
  let compare = [%compare: int] in
  run_test
    ~compare
    [%sexp_of: int]
    [ [ "a" ], 0
    ; [ "a"; "b" ], 0
    ; [ "a"; "b"; "x" ], 0
    ; [ "a"; "c" ], 0
    ; [ "a"; "c"; "y" ], 0
    ];
  [%expect
    {|
    ((a) 0)
    ((a b) 0 ((ancestors (((a) 0)))))
    ((a b x) 0 ((ancestors (((a b) 0) ((a) 0)))))
    ((a c) 0 ((ancestors (((a) 0)))))
    ((a c y) 0 ((ancestors (((a c) 0) ((a) 0)))))
    |}]
;;

let%expect_test "Regression Test: max incremental depth" =
  (* Use a separate [Incr] so that the max state depth is not effected by other tests. *)
  let (module Incr : Incremental.S) = (module Incremental.Make ()) in
  let () = Incr.State.set_max_height_allowed Incr.State.t 100 in
  let compare = [%compare: int] in
  let tree =
    List.init 1000 ~f:(fun idx ->
      let path = Nonempty_list.init (idx + 1) ~f:Int.to_string in
      path, 0)
  in
  run_test
    ~incr:(module Incr)
    ~print_only:5
    ~max_incremental_recursion_depth:6
    ~compare
    [%sexp_of: int]
    tree;
  [%expect
    {|
    ((0) 0)
    ((0 1) 0 ((ancestors (((0) 0)))))
    ((0 1 2) 0 ((ancestors (((0 1) 0) ((0) 0)))))
    ((0 1 2 3) 0 ((ancestors (((0 1 2) 0) ((0 1) 0) ((0) 0)))))
    ((0 1 2 3 4) 0 ((ancestors (((0 1 2 3) 0) ((0 1 2) 0) ((0 1) 0) ((0) 0)))))
    ...
    |}];
  let max_height_seen = Incremental.State.max_height_seen Incr.State.t in
  print_s [%message (max_height_seen : int)];
  [%expect {| (max_height_seen 61) |}];
  Expect_test_helpers_base.require_does_raise ~hide_positions:true (fun () ->
    run_test
      ~incr:(module Incr)
      ~print_only:5
      ~max_incremental_recursion_depth:Int.max_value
      ~compare
      [%sexp_of: int]
      tree);
  [%expect
    {|
    ("node with too large height"
      ((Height 101)
       (Max    100))
      lib/incremental/src/adjust_heights_heap.ml:LINE:COL)
    |}]
;;

module%test [@name "Row.map_data"] _ = struct
  let nested_data : (Nonempty_string_list.t * int) list =
    [ [ "a" ], 1; [ "a"; "b" ], 2; [ "c" ], 3 ]
  ;;

  let compute_map_data (k, row) = k, Tree_table.Row.map_data row ~f:Int.neg

  let compute_map_data_skipping_ancestors_not_impacting_sorting (k, row) =
    k, Tree_table.Row.map_data_skipping_ancestors_not_impacting_sorting row ~f:Int.neg
  ;;

  let%expect_test "Row.map_data" =
    run_test ~post_compute:compute_map_data [%sexp_of: int] nested_data;
    [%expect
      {|
      ((a) -1)
      ((a b) -2 ((ancestors (((a) -1)))))
      ((c) -3)
      |}]
  ;;

  let%expect_test "Row.map_data_skipping_ancestors_not_impacting_sorting" =
    run_test
      ~post_compute:compute_map_data_skipping_ancestors_not_impacting_sorting
      [%sexp_of: int]
      nested_data;
    [%expect
      {|
      ((a) -1)
      ((a b) -2 ((ancestors (((a) 1)))))
      ((c) -3)
      |}]
  ;;

  module%test Compare_sorting_between_compute_map_data_and_compute_map_data_skipping_ancestors_not_impacting_sorting =
  struct
    let%expect_test "Row.map_data - sorted" =
      let compare = [%compare: int] in
      run_test ~post_compute:compute_map_data ~compare [%sexp_of: int] nested_data;
      [%expect
        {|
        ((c) -3)
        ((a) -1)
        ((a b) -2 ((ancestors (((a) -1)))))
        |}]
    ;;

    let%expect_test "Row.map_data_skipping_ancestors_not_impacting_sorting - sorted" =
      let compare = [%compare: int] in
      run_test
        ~post_compute:compute_map_data_skipping_ancestors_not_impacting_sorting
        ~compare
        [%sexp_of: int]
        nested_data;
      (* It is expected that (a b) would be positioned oddly as the ancestor did not get
         remapped. This is why this function is named that way! *)
      [%expect
        {|
        ((a) -1)
        ((a b) -2 ((ancestors (((a) 1)))))
        ((c) -3)
        |}]
    ;;
  end
end
