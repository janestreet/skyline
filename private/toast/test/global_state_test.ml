open! Core
open! Bonsai.Let_syntax

module Result_spec = struct
  type incoming =
    [ `First of string option Private_skyline_toast.action
    | `Second of int option Private_skyline_toast.action
    ]

  type t =
    { state : string
    ; set_first : string option Private_skyline_toast.action -> unit Bonsai.Effect.t
    ; set_second : int option Private_skyline_toast.action -> unit Bonsai.Effect.t
    }

  let view { state; _ } = state

  let incoming { set_first; set_second; _ } = function
    | `First action -> set_first action
    | `Second action -> set_second action
  ;;
end

let create () =
  let component graph =
    let first, set_first = Private_skyline_toast.component (return None) graph in
    let second, set_second = Private_skyline_toast.component (return None) graph in
    let state =
      let%arr first and second in
      match first, second with
      | None, None -> "<empty>"
      | Some first, None -> [%string "first: %{first}"]
      | None, Some second -> [%string "second: %{second#Int}"]
      | Some first, Some second ->
        (* This state should be impossible! *)
        failwith
          [%string "Error: Both values set: first: %{first}; second: %{second#Int}"]
    in
    let%arr state and set_first and set_second in
    { Result_spec.state; set_first; set_second }
  in
  let handle = Bonsai_test.Handle.create (module Result_spec) component in
  handle
;;

let%expect_test "Can set states and replace the current state" =
  let handle = create () in
  Bonsai_test.Handle.show handle;
  [%expect {| <empty> |}];
  Bonsai_test.Handle.do_actions handle [ `First (Replace (Some "Hello Skyline!")) ];
  Bonsai_test.Handle.show handle;
  [%expect {| first: Hello Skyline! |}];
  Bonsai_test.Handle.do_actions handle [ `Second (Replace (Some 9911)) ];
  Bonsai_test.Handle.show handle;
  [%expect {| second: 9911 |}];
  Bonsai_test.Handle.do_actions handle [ `First (Replace (Some "Back to strings ...")) ];
  Bonsai_test.Handle.show handle;
  [%expect {| first: Back to strings ... |}]
;;

let%expect_test "Can dismiss the current value (but only if it's my value)" =
  let handle = create () in
  Bonsai_test.Handle.show handle;
  [%expect {| <empty> |}];
  (* Set the first value. *)
  Bonsai_test.Handle.do_actions handle [ `First (Replace (Some "Hello Skyline!")) ];
  Bonsai_test.Handle.show handle;
  [%expect {| first: Hello Skyline! |}];
  (* Now dismiss the first value, which removes it! *)
  Bonsai_test.Handle.do_actions handle [ `First Dismiss ];
  Bonsai_test.Handle.show handle;
  [%expect {| <empty> |}];
  (* Set the second value *)
  Bonsai_test.Handle.do_actions handle [ `Second (Replace (Some 20)) ];
  Bonsai_test.Handle.show handle;
  [%expect {| second: 20 |}];
  (* Dismissing the first value now does nothing. *)
  Bonsai_test.Handle.do_actions handle [ `First Dismiss ];
  Bonsai_test.Handle.show handle;
  [%expect {| second: 20 |}]
;;
