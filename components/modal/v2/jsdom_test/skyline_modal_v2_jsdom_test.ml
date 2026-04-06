open! Core
open! Bonsai_web
open! Jsdom
open! Private_skyline_prelude
module Handle = Handle_experimental

let test_selector = Bonsai_web_test.test_selector

let filter_printed_attributes ~key ~data:_ =
  not
    String.(
      key = "tabindex"
      || key = "style"
      || key = "class"
      || key = "id"
      || key = "data-bonsai-popover-356c4f74-f7b7-11ee-8823-aa63f6b8d3b4")
;;

module%test Uncontrolled = struct
  let%expect_test "Opens via the provided effect and closes via escape" =
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open_ =
          Skyline_modal_v2.component
            (fun ~close:_ (_graph @ local) -> Bonsai.return Node.none)
            graph
        in
        Bonsai.Edge.lifecycle ~on_activate:open_ graph;
        Bonsai.return Node.none)
    in
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {|
      <div popover="manual"
           data-testing-modal=""
           data-skyline-component="modal"
           mock-popover-state="open"> ... </div>
      |}];
    (* We can dismiss the dialog with escape, returning focus to the body. *)
    Handle.press_key handle ~selector:"*:focus" ~code:Escape;
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect {| <body> ... </body> |}]
  ;;

  let%expect_test "Opens via the provided effect and closes using the close effect" =
    let close_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let open_ =
          Skyline_modal_v2.component
            (fun ~close (_graph @ local) ->
              let%arr close in
              {%html|
                <button %{Test_selector.attr close_selector} on_click=%{fun _ -> close}>
                  Close
                </button>
              |})
            graph
        in
        Bonsai.Edge.lifecycle ~on_activate:open_ graph;
        Bonsai.return Node.none)
    in
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {|
      <div popover="manual"
           data-testing-modal=""
           data-skyline-component="modal"
           mock-popover-state="open"> ... </div>
      |}];
    (* We can dismiss the dialog with the button, returning focus to the body. *)
    Handle.click_on handle ~selector:(test_selector close_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect {| <body> </body> |}]
  ;;
end

module%test Controlled = struct
  let%expect_test "Constant open controller: the modal shows and isn't closable" =
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let state = Bonsai.return true, Bonsai.return (fun _ -> Effect.Ignore) in
        let (_ : unit Effect.t Bonsai.t) =
          Skyline_modal_v2.component
            ~close_on_esc:(Bonsai.return true)
            ~state
            (fun ~close:_ (_graph @ local) -> Bonsai.return Node.none)
            graph
        in
        Bonsai.return Node.none)
    in
    (* Our state tells us that the modal is opened. *)
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {|
      <div popover="manual"
           data-testing-modal=""
           data-skyline-component="modal"
           mock-popover-state="open"> ... </div>
      |}];
    (* We can't dismiss the dialog with escape even if it should be possible, our state
       prevents it. *)
    Handle.press_key handle ~selector:"*:focus" ~code:Escape;
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {|
      <div popover="manual"
           data-testing-modal=""
           data-skyline-component="modal"
           mock-popover-state="open"> ... </div>
      |}]
  ;;

  let%expect_test "Internal close actions sync with the state" =
    let close_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let is_open, set_is_open = Bonsai.state true graph in
        let (_ : unit Effect.t Bonsai.t) =
          Skyline_modal_v2.component
            ~state:(is_open, set_is_open)
            (fun ~close (_graph @ local) ->
              let%arr close in
              {%html|
                <button %{Test_selector.attr close_selector} on_click=%{fun _ -> close}>
                  Close
                </button>
              |})
            graph
        in
        let%arr is_open in
        Node.sexp_for_debugging [%message (is_open : bool)])
    in
    (* Our state initially tells us that the modal is opened. *)
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {|
      <div popover="manual"
           data-testing-modal=""
           data-skyline-component="modal"
           mock-popover-state="open"> ... </div>
      |}];
    (* We can dismiss the modal with the button, returning focus to the body showing the
       state synced to is_open being false *)
    Handle.click_on handle ~selector:(test_selector close_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect {| <pre> (is_open false) </pre> |}]
  ;;
end

module%test Effect = struct
  open Async_kernel
  open Async_js_test

  let resolve_selector = Test_selector.make ()

  let%expect_test "Effect resolves None on dismiss" =
    let%with handle =
      Handle.with_async ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let effect =
          Skyline_modal_v2.effect
            (fun _in ~close:_ ~resolve:_ (_graph @ local) -> Bonsai.return Node.none)
            graph
        in
        let effect_chain =
          let%arr effect in
          let input = () in
          let%bind.Effect () = Effect.print_s [%message "start chain" (input : unit)] in
          let%bind.Effect result = effect input in
          Effect.print_s [%message "end chain" (result : unit option)]
        in
        Bonsai.Edge.lifecycle ~on_activate:effect_chain graph;
        Bonsai.return Node.none)
    in
    (* The effect chain starts and the modal is focused *)
    Handle.one_frame handle;
    [%expect {| ("start chain" (input ())) |}];
    Handle.print_active_element handle;
    [%expect
      {|
      <div popover="manual"
           data-testing-modal=""
           data-skyline-component="modal"
           mock-popover-state="open"> ... </div>
      |}];
    (* We escape to close the modal going back to the body *)
    Handle.press_key handle ~selector:"*:focus" ~code:Escape;
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect {| <body> ... </body> |}];
    (* We need to unroll the async queue to be able to continue the effect chain to its
       None resolution. *)
    let%bind.Deferred () = Async_kernel_scheduler.yield_until_no_jobs_remain () in
    [%expect {| ("end chain" (result ())) |}];
    Deferred.return ()
  ;;

  let%expect_test "Effect resolves Some on resolve" =
    let%with handle =
      Handle.with_async ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let effect =
          Skyline_modal_v2.effect
            (fun in_value ~close:_ ~resolve (_graph @ local) ->
              let%arr in_value and resolve in
              {%html|
                <button
                  %{Test_selector.attr resolve_selector}
                  on_click=%{fun _ -> resolve ((-1) * in_value)}
                >
                  Resolve negative input
                </button>
              |})
            graph
        in
        let effect_chain =
          let%arr effect in
          let input = 123 in
          let%bind.Effect () = Effect.print_s [%message "start chain" (input : int)] in
          let%bind.Effect result = effect input in
          Effect.print_s [%message "end chain" (result : int option)]
        in
        Bonsai.Edge.lifecycle ~on_activate:effect_chain graph;
        Bonsai.return Node.none)
    in
    (* The effect chain starts and the modal is focused *)
    Handle.one_frame handle;
    [%expect {| ("start chain" (input 123)) |}];
    Handle.print_active_element handle;
    [%expect
      {|
      <div popover="manual"
           data-testing-modal=""
           data-skyline-component="modal"
           mock-popover-state="open"> ... </div>
      |}];
    (* We resolve by clicking on the button *)
    Handle.click_on handle ~selector:(test_selector resolve_selector);
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect {| <body> ... </body> |}];
    (* We need to unroll the async queue to be able to continue the effect chain to its
       Some resolution. *)
    let%bind.Deferred () = Async_kernel_scheduler.yield_until_no_jobs_remain () in
    [%expect {| ("end chain" (result (-123))) |}];
    Deferred.return ()
  ;;

  let%expect_test "Effect chains with multiple calls will go one by one" =
    let%with handle =
      Handle.with_async ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let effect =
          Skyline_modal_v2.effect
            (fun in_value ~close:_ ~resolve (_graph @ local) ->
              let%arr in_value and resolve in
              {%html|
                <>
                  In value: #{Int.to_string in_value}
                  <button
                    %{Test_selector.attr resolve_selector}
                    on_click=%{fun _ -> resolve ((-1) * in_value)}
                  >
                    Resolve negative input
                  </button>
                </>
              |})
            graph
        in
        let effect_chains =
          let%arr effect in
          let one_chain input =
            let%bind.Effect () = Effect.print_s [%message "start chain" (input : int)] in
            let%bind.Effect result = effect input in
            Effect.print_s [%message "end chain" (result : int option)]
          in
          Effect.all_parallel_unit [ one_chain 123; one_chain 456 ]
        in
        Bonsai.Edge.lifecycle ~on_activate:effect_chains graph;
        Bonsai.return Node.none)
    in
    (* The effect chains both start and the modal is focused on only one of 2 of the
       effect chains *)
    Handle.one_frame handle;
    [%expect
      {|
      ("start chain" (input 123))
      ("start chain" (input 456))
      |}];
    Handle.print_active_element ~depth:2 handle;
    [%expect
      {|
      <div popover="manual"
           data-testing-modal=""
           data-skyline-component="modal"
           mock-popover-state="open">
        <div>
           In value: 123
          <button> ... </button>
        </div>
        <div> </div>
      </div>
      |}];
    (* We escape to close the modal going back to the body *)
    Handle.click_on handle ~selector:(test_selector resolve_selector);
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {|
      <div popover="manual"
           data-testing-modal=""
           data-skyline-component="modal"
           mock-popover-state="open"> ... </div>
      |}];
    (* We need to unroll the async queue to be able to continue the effect chain to its
       Some resolution that corresponds. *)
    let%bind.Deferred () = Async_kernel_scheduler.yield_until_no_jobs_remain () in
    [%expect {| ("end chain" (result (-123))) |}];
    (* The second effect chain modal shows up *)
    Handle.one_frame handle;
    Handle.print_active_element ~depth:2 handle;
    [%expect
      {|
      <div popover="manual"
           data-testing-modal=""
           data-skyline-component="modal"
           mock-popover-state="open">
        <div>
           In value: 456
          <button> ... </button>
        </div>
        <div> </div>
      </div>
      |}];
    (* We escape to close the modal going back to the body *)
    Handle.click_on handle ~selector:(test_selector resolve_selector);
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect {| <body> ... </body> |}];
    (* We need to unroll the async queue to be able to continue the effect chain to its
       corresponding Some resolution. *)
    let%bind.Deferred () = Async_kernel_scheduler.yield_until_no_jobs_remain () in
    [%expect {| ("end chain" (result (-456))) |}];
    Deferred.return ()
  ;;
end

module%test Focus = struct
  let other_button_selector = Test_selector.make ()

  let%expect_test "Any previous focus prior to the opening the modal should be restored \
                   after close."
    =
    let open_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let%arr open_ =
          Skyline_modal_v2.component
            (fun ~close:_ (_graph @ local) -> Bonsai.return {%html|<>Modal contents</>|})
            graph
        in
        let on_click _ = open_ in
        [%html
          {|
            <>
              <button %{Test_selector.attr open_selector} on_click=%{on_click}>
                Open
              </button>
              <button %{Test_selector.attr other_button_selector}>
                I get focused first and focus should return to me later.
              </button>
            </>
          |}])
    in
    Handle.one_frame handle;
    (* We focus a random button in the UI. *)
    Handle.focus handle ~selector:(test_selector other_button_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect
      {| <button>  I get focused first and focus should return to me later.  </button> |}];
    (* We now open the alert, the modal should get focused. *)
    Handle.click_on handle ~selector:(test_selector open_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect
      {|
      <div popover="manual"
           data-testing-modal=""
           data-skyline-component="modal"
           mock-popover-state="open">
        <div> ... </div>
        <div> </div>
      </div>
      |}];
    (* We can dismiss the dialog, returning focus to the "Other" button. *)
    Handle.press_key handle ~selector:"*:focus" ~code:Escape;
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect
      {| <button>  I get focused first and focus should return to me later.  </button> |}]
  ;;

  let%expect_test "Any previous focus prior to the opening of the modal should be \
                   restored after close even if an element was focused within the \
                   dialog."
    =
    let open_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let%arr open_ =
          Skyline_modal_v2.component
            (fun ~close:_ (_graph @ local) ->
              Bonsai.return
                {%html|
                  <button autofocus=%{true}>
                    I am getting focused when the modal opens.
                  </button>
                |})
            graph
        in
        let on_click _ = open_ in
        [%html
          {|
            <>
              <button %{Test_selector.attr open_selector} on_click=%{on_click}>
                Open
              </button>
              <button %{Test_selector.attr other_button_selector}>
                I get focused first and focus should return to me later.
              </button>
            </>
          |}])
    in
    Handle.one_frame handle;
    (* We focus a random button in the UI. *)
    Handle.focus handle ~selector:(test_selector other_button_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect
      {| <button>  I get focused first and focus should return to me later.  </button> |}];
    (* We now open the alert, the autofocus button in the modal should get focused. *)
    Handle.click_on handle ~selector:(test_selector open_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect
      {| <button autofocus="">  I am getting focused when the modal opens.  </button> |}];
    (* We can dismiss the dialog, returning focus to the "Other" button. *)
    Handle.press_key handle ~selector:"*:focus" ~code:Escape;
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect
      {| <button>  I get focused first and focus should return to me later.  </button> |}]
  ;;
end
