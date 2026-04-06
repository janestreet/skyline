open! Core
open! Util

(* These tests go through the incremental code path, but without any incremental reuse *)

let incrementally
  (module Incr : Incremental.S)
  ?max_incremental_recursion_depth
  ?map_to_tree_instrumentation
  ?map_instrumentation
  ?tree_to_map_instrumentation
  feature_map
  =
  let var = Incr.Var.create feature_map in
  let instrumented_map =
    match map_instrumentation with
    | None -> Fn.id
    | Some instrumentation ->
      Bonsai_web_ui_tree_table.map
        ~instrumentation
        ~how_to_map:
          (Bonsai_web_ui_tree_table.How_to_map.incrementally_with_nonincremental_fallback
             ?switch_from_incremental_to_nonincremental_at_this_depth:
               max_incremental_recursion_depth
             ~nonincremental:(fun ~key:_ ~data ~children:_ -> data)
             ~incremental:(fun ~key:_ ~data ~children:_ -> data)
             ())
  in
  let out =
    Incr.Var.watch var
    |> Bonsai_web_ui_tree_table.map_to_tree
         ?instrumentation:map_to_tree_instrumentation
         (module String)
    |> instrumented_map
    |> Bonsai_web_ui_tree_table.tree_to_map
         ?instrumentation:tree_to_map_instrumentation
         ?max_incremental_recursion_depth
         ~how_to_deal_with_nones:Remove_and_also_remove_descendants
  in
  let obs = Incr.observe out in
  Incr.stabilize ();
  Incremental.Observer.value_exn obs
;;

let%expect_test "single stabilization" (* these were examples of inputs that found bugs *)
  =
  let%quick_test prop (features : t list) =
    let features = of_list features in
    let out_incr =
      features
      |> incrementally (module Util.Incr)
      |> Map.data
      |> List.map ~f:Bonsai_web_ui_tree_table.Row.data
    in
    let out_non_incr = nonincremental features in
    [%test_result: t list] out_incr ~expect:out_non_incr
      [@@remember_failures
        (* these were examples of inputs that found bugs *)
        {|(((path (a b)) (review 0)))|}
          {|(((path ("" "")) (review 0)))|}
          {|()|}
          {|(((path (a)) (review 0)) ((path (a b)) (review 0)))|}
          {|(((path (a)) (review 0)))|}
          {|(((path (b)) (review 0)) ((path (a b)) (review 0)))|}]
  in
  ()
;;
