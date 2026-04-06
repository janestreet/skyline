open! Core
open! Bonsai_web
open! Jsdom
module Handle = Handle_experimental

let test_selector = Bonsai_web_test.test_selector

module Popover = Skyline_popover_v2

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
  let%expect_test "Opens via the anchor button and closes via escape" =
    let open_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let popover =
          Popover.component
            (fun ~hide:_ (_graph @ local) -> Bonsai.return Vdom.Node.none)
            graph
        in
        let view =
          let open Bonsai.Let_syntax in
          let%arr popover in
          [%html
            {|
              <>
                <button
                  %{popover.Popover.anchor}
                  %{Test_selector.attr open_selector}
                  on_click=%{fun _ -> popover.Popover.set_is_open true}
                >
                  Open
                </button>
              </>
            |}]
        in
        view)
    in
    Handle.one_frame handle;
    Handle.click_on handle ~selector:(test_selector open_selector);
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {| <div popover="manual" data-skyline-component="popover" mock-popover-state="open"> ... </div> |}];
    (* We can dismiss the popover with escape, returning focus to the anchor button. *)
    Handle.press_key handle ~selector:"*:focus" ~code:Escape;
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect
      {|
      <body>
        <div> ... </div>
      </body>
      |}]
  ;;

  let%expect_test "Opens and closes using the hide effect" =
    let open_selector = Test_selector.make () in
    let close_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let popover =
          Popover.component
            (fun ~hide (_graph @ local) ->
              let%arr hide in
              [%html
                {|
                  <button %{Test_selector.attr close_selector} on_click=%{fun _ -> hide}>
                    Close
                  </button>
                |}])
            graph
        in
        let view =
          let%arr popover in
          [%html
            {|
              <>
                <button
                  %{popover.Popover.anchor}
                  %{Test_selector.attr open_selector}
                  on_click=%{fun _ -> popover.Popover.set_is_open true}
                >
                  Open
                </button>
              </>
            |}]
        in
        view)
    in
    Handle.one_frame handle;
    Handle.click_on handle ~selector:(test_selector open_selector);
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {| <div popover="manual" data-skyline-component="popover" mock-popover-state="open"> ... </div> |}];
    (* We can dismiss the popover with the button, returning focus to the anchor. *)
    Handle.click_on handle ~selector:(test_selector close_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect
      {|
      <body>
        <div> ... </div>
      </body>
      |}]
  ;;

  let%expect_test "Does not close on outside click when disabled" =
    let open_selector = Test_selector.make () in
    let outside_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let popover =
          Popover.component
            ~close_on_click_outside:(Bonsai.return false)
            (fun ~hide:_ (_graph @ local) -> Bonsai.return Vdom.Node.none)
            graph
        in
        let view =
          let%arr popover in
          [%html
            {|
              <>
                <div %{popover.Popover.anchor}>
                  <button
                    %{Test_selector.attr open_selector}
                    on_click=%{fun _ -> popover.Popover.set_is_open true}
                  >
                    Open
                  </button>
                </div>
                <div %{Test_selector.attr outside_selector}>Outside</div>
              </>
            |}]
        in
        view)
    in
    Handle.one_frame handle;
    Handle.click_on handle ~selector:(test_selector open_selector);
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {| <div popover="manual" data-skyline-component="popover" mock-popover-state="open"> ... </div> |}];
    (* Clicking outside should not close the popover when disabled. *)
    Handle.click_on handle ~selector:(test_selector outside_selector);
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {| <div popover="manual" data-skyline-component="popover" mock-popover-state="open"> ... </div> |}]
  ;;

  let%expect_test "focus_on_show:false keeps focus on the anchor when opening" =
    let open_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let popover =
          Popover.component
            ~focus_on_show:(Bonsai.return false)
            (fun ~hide:_ (_graph @ local) -> Bonsai.return Vdom.Node.none)
            graph
        in
        let view =
          let open Bonsai.Let_syntax in
          let%arr popover in
          [%html
            {|
              <>
                <button
                  %{popover.Popover.anchor}
                  %{Test_selector.attr open_selector}
                  on_click=%{fun _ -> popover.Popover.set_is_open true}
                >
                  Open
                </button>
              </>
            |}]
        in
        view)
    in
    Handle.one_frame handle;
    Handle.focus handle ~selector:(test_selector open_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect {| <button>  Open  </button> |}];
    Handle.click_on handle ~selector:(test_selector open_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect {| <button>  Open  </button> |}]
  ;;

  let%expect_test "focus_on_show:true closes on outside click and updates external state" =
    let open_selector = Test_selector.make () in
    let outside_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let is_open, set_is_open = Bonsai.state false graph in
        let popover =
          Popover.component
            ~state:
              ( is_open
              , let%arr set_is_open in
                fun is_open ->
                  let%bind.Effect () =
                    Effect.print_s [%message "set_is_open" (is_open : bool)]
                  in
                  set_is_open is_open )
            ~focus_on_show:(Bonsai.return true)
            (fun ~hide:_ (_graph @ local) -> Bonsai.return Vdom.Node.none)
            graph
        in
        let%arr is_open and popover in
        Vdom.Node.fragment
          [ Vdom.Node.sexp_for_debugging [%message (is_open : bool)]
          ; [%html
              {|
                <>
                  <div %{popover.Popover.anchor}>
                    <button
                      %{Test_selector.attr open_selector}
                      on_click=%{fun _ -> (popover.Popover.set_is_open true)}
                    >
                      Open
                    </button>
                  </div>
                  <div %{Test_selector.attr outside_selector}>Outside</div>
                </>
              |}]
          ])
    in
    Handle.one_frame handle;
    (* Open the popover, which should move focus into it due to focus_on_show:true. *)
    Handle.click_on handle ~selector:(test_selector open_selector);
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {|
      (set_is_open (is_open true))
      <div popover="manual" data-skyline-component="popover" mock-popover-state="open"> ... </div>
      |}];
    (* Clicking outside should close the popover and set external state to false. *)
    Handle.click_on handle ~selector:(test_selector outside_selector);
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      (set_is_open (is_open false))
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <div>
            <pre> (is_open false) </pre>
            <div>
              <button>  Open  </button>
            </div>
            <div> Outside </div>
          </div>
        </body>
        <div> </div>
      </html>
      |}]
  ;;
end

module%test Controlled = struct
  let%expect_test "Constant open controller: the popover shows and isn't closable" =
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let state = Bonsai.return true, Bonsai.return (fun _ -> Effect.Ignore) in
        let popover =
          Popover.component
            ~state
            (fun ~hide:_ (_graph @ local) -> Bonsai.return Vdom.Node.none)
            graph
        in
        let view =
          let open Bonsai.Let_syntax in
          let%arr popover in
          [%html {|<div %{popover.Popover.anchor}>Anchor</div>|}]
        in
        view)
    in
    (* Our state tells us that the popover is opened. *)
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {| <div popover="manual" data-skyline-component="popover" mock-popover-state="open"> ... </div> |}];
    (* We can't dismiss the popover with escape even if it should be possible, our state
       prevents it. *)
    Handle.press_key handle ~selector:"*:focus" ~code:Escape;
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {| <div popover="manual" data-skyline-component="popover" mock-popover-state="open"> ... </div> |}]
  ;;

  let%expect_test "Internal hide actions sync with controlled state" =
    let close_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let is_open, set_is_open = Bonsai.state true graph in
        let popover =
          Popover.component
            ~state:(is_open, set_is_open)
            (fun ~hide (_graph @ local) ->
              let%arr hide in
              [%html
                {|
                  <button %{Test_selector.attr close_selector} on_click=%{fun _ -> hide}>
                    Close
                  </button>
                |}])
            graph
        in
        let%arr is_open and popover in
        Vdom.Node.fragment
          [ Vdom.Node.sexp_for_debugging [%message (is_open : bool)]
          ; [%html {|<div %{popover.Popover.anchor}></div>|}]
          ])
    in
    (* Our state initially tells us that the popover is opened. *)
    Handle.one_frame handle;
    Handle.print_active_element handle;
    [%expect
      {| <div popover="manual" data-skyline-component="popover" mock-popover-state="open"> ... </div> |}];
    (* We can dismiss the popover with the button, returning focus to the body showing the
       state synced to is_open being false *)
    Handle.click_on handle ~selector:(test_selector close_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect
      {|
      <body>
        <div> ... </div>
      </body>
      |}]
  ;;

  let%expect_test "focus_on_show:false keeps focus on the anchor when opening" =
    let open_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let is_open, set_is_open = Bonsai.state false graph in
        let popover =
          Popover.component
            ~state:(is_open, set_is_open)
            ~focus_on_show:(Bonsai.return false)
            (fun ~hide:_ (_graph @ local) -> Bonsai.return Vdom.Node.none)
            graph
        in
        let%arr popover in
        [%html
          {|
            <button
              %{popover.Popover.anchor}
              %{Test_selector.attr open_selector}
              on_click=%{fun _ -> (popover.Popover.set_is_open true)}
            >
              Open
            </button>
          |}])
    in
    Handle.one_frame handle;
    Handle.focus handle ~selector:(test_selector open_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect {| <button>  Open  </button> |}];
    Handle.click_on handle ~selector:(test_selector open_selector);
    Handle.one_frame handle;
    Handle.print_active_element ~depth:1 handle;
    [%expect {| <button>  Open  </button> |}]
  ;;
end
