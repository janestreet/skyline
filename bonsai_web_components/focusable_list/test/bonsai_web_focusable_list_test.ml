open! Core
open! Bonsai_web
open Bonsai.Let_syntax
open Jsdom
module Handle = Handle_experimental
module Node = Vdom.Node
module Focusable_list = Bonsai_web_focusable_list
open Focusable_list.Action

let render_ascii focusable =
  Focusable_list.For_testing.ascii_render focusable ~to_string:Fn.id
;;

let make_handle ?(wrap_around = false) () =
  let component graph =
    let ids = Bonsai.Expert.Var.create (Iarray.of_list [ "A"; "B"; "C"; "D" ]) in
    let ids_value = Bonsai.Expert.Var.value ids in
    let wrap_around = Bonsai.return wrap_around in
    let focusable, inject =
      Focusable_list.create (module String) ids_value graph ~wrap_around
    in
    let%arr focusable and inject in
    focusable, inject, ids
  in
  fun do_with_handle ->
    Handle.with_
      component
      ~get_vdom:(fun _ -> Node.none)
      (fun handle -> do_with_handle handle)
;;

let print_model handle =
  let model, _inject, ids_var = Handle.last_result handle in
  render_ascii ~ids:(Bonsai.Expert.Var.get ids_var) model |> print_endline
;;

let one_frame_and_print_model handle =
  Handle.one_frame handle;
  print_model handle
;;

let inject handle action =
  Handle.inject handle (fun (_model, inject, _ids_var) ->
    inject action |> Effect.ignore_m)
;;

let update_ids handle new_ids =
  let _model, _inject, ids_var = Handle.last_result handle in
  Bonsai.Expert.Var.set ids_var (Iarray.of_list new_ids)
;;

let%expect_test "initial state: first item is focusable" =
  let%with handle = make_handle () in
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}]
;;

let%expect_test "basic navigation: Next" =
  let%with handle = make_handle () in
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}];
  inject handle Next;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │ -> 1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}];
  inject handle Next;
  inject handle Next;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │    2. C │
    │ -> 3. D │
    └─────────┘
    |}];
  (* At end of list, Next should not move *)
  inject handle Next;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │    2. C │
    │ -> 3. D │
    └─────────┘
    |}]
;;

let%expect_test "basic navigation: Prev" =
  let%with handle = make_handle () in
  inject handle (Focus "D");
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │    2. C │
    │ -> 3. D │
    └─────────┘
    |}];
  inject handle Prev;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │ -> 2. C │
    │    3. D │
    └─────────┘
    |}];
  inject handle Prev;
  inject handle Prev;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}];
  (* At start of list, Prev should not move *)
  inject handle Prev;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}]
;;

let%expect_test "basic navigation, wraparound: Next at end wraps to first" =
  let%with handle = make_handle ~wrap_around:true () in
  inject handle Last;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │    2. C │
    │ -> 3. D │
    └─────────┘
    |}];
  inject handle Next;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}]
;;

let%expect_test "basic navigation, wraparound: Prev at start wraps to last" =
  let%with handle = make_handle ~wrap_around:true () in
  inject handle First;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}];
  inject handle Prev;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │    2. C │
    │ -> 3. D │
    └─────────┘
    |}]
;;

let%expect_test "basic navigation, no wraparound: Next at end is a no-op" =
  let%with handle = make_handle ~wrap_around:false () in
  inject handle Last;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │    2. C │
    │ -> 3. D │
    └─────────┘
    |}];
  inject handle Next;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │    2. C │
    │ -> 3. D │
    └─────────┘
    |}]
;;

let%expect_test "basic navigation, no wraparound: Prev at start is a no-op" =
  let%with handle = make_handle ~wrap_around:false () in
  inject handle First;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}];
  inject handle Prev;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}]
;;

let%expect_test "basic navigation: First and Last" =
  let%with handle = make_handle () in
  inject handle Last;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │    2. C │
    │ -> 3. D │
    └─────────┘
    |}];
  inject handle First;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}]
;;

let%expect_test "reorder: focusable item moves, Next still works" =
  let%with handle = make_handle () in
  inject handle (Focus "B");
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │ -> 1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}];
  (* Reorder: move B to the end *)
  update_ids handle [ "A"; "C"; "D"; "B" ];
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. C │
    │    2. D │
    │ -> 3. B │
    └─────────┘
    |}];
  (* Next should stay at B (end of list) *)
  inject handle Next;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. C │
    │    2. D │
    │ -> 3. B │
    └─────────┘
    |}];
  (* Prev should go to D *)
  inject handle Prev;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. C │
    │ -> 2. D │
    │    3. B │
    └─────────┘
    |}]
;;

let%expect_test "reorder: focusable item moves to start, Prev noops" =
  let%with handle = make_handle () in
  inject handle (Focus "C");
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │ -> 2. C │
    │    3. D │
    └─────────┘
    |}];
  (* Reorder: move C to the start *)
  update_ids handle [ "C"; "A"; "B"; "D" ];
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. C │
    │    1. A │
    │    2. B │
    │    3. D │
    └─────────┘
    |}];
  (* Prev should stay at C (start of list) *)
  inject handle Prev;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. C │
    │    1. A │
    │    2. B │
    │    3. D │
    └─────────┘
    |}]
;;

let%expect_test "removal: focusable item is removed, index is preserved" =
  let%with handle = make_handle () in
  inject handle (Focus "B");
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │ -> 1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}];
  (* Remove B, even though item is gone, index is preserved. *)
  update_ids handle [ "A"; "C"; "D" ];
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │ -> 1. C │
    │    2. D │
    └─────────┘
    |}];
  (* Next should focus next item *)
  inject handle Next;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. C │
    │ -> 2. D │
    └─────────┘
    |}]
;;

let%expect_test "removal: non-focused item is removed, focus preserved" =
  let%with handle = make_handle () in
  inject handle (Focus "C");
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │ -> 2. C │
    │    3. D │
    └─────────┘
    |}];
  (* Remove B (before focused item) *)
  update_ids handle [ "A"; "C"; "D" ];
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │ -> 1. C │
    │    2. D │
    └─────────┘
    |}];
  (* Next should go to D *)
  inject handle Next;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. C │
    │ -> 2. D │
    └─────────┘
    |}]
;;

let%expect_test "insertion: new item added, focus preserved" =
  let%with handle = make_handle () in
  (* Focus on B *)
  inject handle (Focus "B");
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │ -> 1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}];
  (* Insert X before B *)
  update_ids handle [ "A"; "X"; "B"; "C"; "D" ];
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. X │
    │ -> 2. B │
    │    3. C │
    │    4. D │
    └─────────┘
    |}];
  (* Next should go to C *)
  inject handle Next;
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. X │
    │    2. B │
    │ -> 3. C │
    │    4. D │
    └─────────┘
    |}]
;;

let%expect_test "removal: last item removed clamps to new last" =
  let%with handle = make_handle () in
  (* Focus on D (last item) *)
  inject handle (Focus "D");
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │    2. C │
    │ -> 3. D │
    └─────────┘
    |}];
  (* Remove D - should clamp to C (new last) *)
  update_ids handle [ "A"; "B"; "C" ];
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │    0. A │
    │    1. B │
    │ -> 2. C │
    └─────────┘
    |}]
;;

let%expect_test "removal: all items removed, then re-added" =
  let%with handle = make_handle () in
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}];
  (* Remove all items *)
  update_ids handle [];
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌───────┐
    │ Items │
    ├┬┬┬┬┬┬┬┤
    └┴┴┴┴┴┴┴┘
    |}];
  (* Add items back - first item should be focusable *)
  update_ids handle [ "X"; "Y"; "Z" ];
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. X │
    │    1. Y │
    │    2. Z │
    └─────────┘
    |}]
;;

let%expect_test "duplicate ids considers everything focused" =
  let%with handle = make_handle () in
  update_ids handle [ "A"; "A"; "A"; "A" ];
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │ -> 1. A │
    │ -> 2. A │
    │ -> 3. A │
    └─────────┘
    |}]
;;

let%expect_test "focusing a nonexistent item is a no-op" =
  let%with handle = make_handle () in
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}];
  inject handle (Focus "E");
  one_frame_and_print_model handle;
  [%expect
    {|
    ┌─────────┐
    │ Items   │
    ├─────────┤
    │ -> 0. A │
    │    1. B │
    │    2. C │
    │    3. D │
    └─────────┘
    |}]
;;
