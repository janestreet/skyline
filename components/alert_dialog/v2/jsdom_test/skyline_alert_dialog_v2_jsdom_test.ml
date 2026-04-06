open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
open! Jsdom
open! Private_skyline_prelude
module Handle = Handle_experimental

let test_selector = Bonsai_web_test.test_selector

let filter_printed_attributes ~key ~data:_ =
  not String.(key = "tabindex" || key = "style" || key = "class")
;;

module%test Effect = struct
  open Async_kernel
  open Async_js_test

  let%expect_test "Alert waits for dismissal to resolve" =
    let%with handle =
      Handle.with_async ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let alert = Skyline_alert_dialog_v2.effect graph in
        let effect_chain =
          let%arr alert in
          let%bind.Effect () = Effect.print_s [%message "start chain"] in
          let%bind.Effect () = alert ~title:"Alert" {%html|This is an alert|} in
          Effect.print_s [%message "end chain"]
        in
        Bonsai.Edge.lifecycle ~on_activate:effect_chain graph;
        Bonsai.return Node.none)
    in
    (* The effect chain starts *)
    Handle.one_frame handle;
    [%expect {| "start chain" |}];
    (* We escape to close the modal going back to the body *)
    Handle.press_key handle ~selector:"*:focus" ~code:Escape;
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect {| <body> ... </body> |}];
    (* We need to unroll the async queue to be able to continue the effect chain to its
       resolution. *)
    let%bind.Deferred () = Async_kernel_scheduler.yield_until_no_jobs_remain () in
    [%expect {| "end chain" |}];
    Deferred.return ()
  ;;

  let%expect_test "Alert waits for resolution to resolve" =
    let resolve_selector = Test_selector.make () in
    let%with handle =
      Handle.with_async ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let alert = Skyline_alert_dialog_v2.effect graph in
        let effect_chain =
          let%arr alert in
          let%bind.Effect () = Effect.print_s [%message "start chain"] in
          let%bind.Effect () =
            alert
              ~button_test_selector:resolve_selector
              ~title:"Alert"
              {%html|This is an alert|}
          in
          Effect.print_s [%message "end chain"]
        in
        Bonsai.Edge.lifecycle ~on_activate:effect_chain graph;
        Bonsai.return Node.none)
    in
    (* The effect chain starts *)
    Handle.one_frame handle;
    [%expect {| "start chain" |}];
    (* We click on the button to resolve and go back to the body. *)
    Handle.click_on handle ~selector:(test_selector resolve_selector);
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect {| <body> ... </body> |}];
    (* We need to unroll the async queue to be able to continue the effect chain to its
       resolution. *)
    let%bind.Deferred () = Async_kernel_scheduler.yield_until_no_jobs_remain () in
    [%expect {| "end chain" |}];
    Deferred.return ()
  ;;
end

module%test Focus = struct
  let%expect_test "The confirm button gets focused at modal opening" =
    let open_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let%arr alert = Skyline_alert_dialog_v2.effect graph in
        let on_click _ =
          alert
            ~button_label:"Confirm button within the dialog"
            ~title:"Alert"
            {%html|Example alert!|}
        in
        [%html
          {|
            <>
              <button %{Test_selector.attr open_selector} on_click=%{on_click}>
                Open
              </button>
            </>
          |}])
    in
    Handle.one_frame handle;
    (* We open the alert, the confirm button should get focused. *)
    Handle.click_on handle ~selector:(test_selector open_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:2 handle;
    [%expect
      {| <button data-skyline-component="button" autofocus=""> Confirm button within the dialog </button> |}]
  ;;
end
