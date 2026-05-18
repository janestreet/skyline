open! Core
open Util

(* These tests allocate a single global incremental value that is used for every iteration
   of the quickcheck test. In contrast with the "quickcheck_isolated" tests, these should
   show that there isn't any behavioral concequences from the incrementality *)

let var = Incr.Var.create (Map.empty (module Nonempty_string_list))

let out =
  Incr.Var.watch var
  |> Bonsai_web_contrib_tree_table.map_to_tree (module String)
  |> Bonsai_web_contrib_tree_table.tree_to_map
       ~how_to_deal_with_nones:Remove_and_also_remove_descendants
;;

let obs = Incr.observe out

let%expect_test "re-using the same incremental var"
  (* these were examples of inputs that found bugs *)
  =
  let%quick_test prop (features : t list) =
    let features = of_list features in
    Incr.Var.set var features;
    let out_incr =
      (* incrementally features *)
      Incr.stabilize ();
      Incr.Observer.value_exn obs
      |> Map.data
      |> List.map ~f:Bonsai_web_contrib_tree_table.Row.data
    in
    let out_non_incr = nonincremental features in
    [%test_result: t list] out_incr ~expect:out_non_incr
      [@@remember_failures
        (* these were examples of inputs that found bugs *)
        {|(((path (a b)) (review 0)))|}
          {|(((path (a b)) (review 0)))|}
          {|()|}
          {|(((path (a)) (review 0)) ((path (a b)) (review 0)))|}
          {|(((path (a)) (review 0)))|}]
  in
  ()
;;
