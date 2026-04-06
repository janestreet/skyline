open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
open! Jsdom
open! Private_skyline_prelude
module Handle = Handle_experimental

let test_selector = Bonsai_web_test.test_selector

module Accordion = Skyline_accordion_v2

let filter_printed_attributes ~key ~data:_ =
  not
    String.(
      key = "tabindex"
      || key = "style"
      || key = "class"
      || key = "id"
      || String.is_prefix key ~prefix:"name")
;;

module%test Uncontrolled = struct
  let%expect_test "Accordion opens and closes via clicking the header" =
    let header_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun _graph ->
        Bonsai.return
          {%html|
            <Accordion.view
              ~header:(<Accordion.Header.content ~test_selector:%{header_selector}>Header</>)
            >
              <Accordion.Section.content> Section content </>
            </>
          |})
    in
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <div>
            <details>
              <summary>
                <icon-chevron_right size="16px"
                                    color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                Header
              </summary>
              <div>  Section content  </div>
            </details>
          </div>
        </body>
      </html>
      |}];
    (* Click to open the accordion *)
    Handle.click_on handle ~selector:(test_selector header_selector);
    Handle.one_frame handle;
    Handle.print_dom_diff handle;
    [%expect
      {|
      === DIFF HUNK ===
        <html>
          <head>
            <meta charset="UTF-8"/>
          </head>
          <body>
            <div>
      -|      <details>
      +|      <details open="">
                <summary>
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Header
                </summary>
                <div>  Section content  </div>
              </details>
            </div>
          </body>
        </html>
      |}];
    (* Click to close the accordion *)
    Handle.click_on handle ~selector:(test_selector header_selector);
    Handle.one_frame handle;
    Handle.print_dom_diff handle;
    [%expect
      {|
      === DIFF HUNK ===
        <html>
          <head>
            <meta charset="UTF-8"/>
          </head>
          <body>
            <div>
      -|      <details open="">
      +|      <details>
                <summary>
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Header
                </summary>
                <div>  Section content  </div>
              </details>
            </div>
          </body>
        </html>
      |}]
  ;;

  let%expect_test "Accordion respects default_open parameter" =
    let header_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun _graph ->
        Bonsai.return
          {%html|
            <Accordion.view
              ~default_open:%{true}
              ~header:(<Accordion.Header.content ~test_selector:%{header_selector}>
                Header
              </>)
            >
              <Accordion.Section.content>Section content</>
            </>
          |})
    in
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <div>
            <details open="">
              <summary>
                <icon-chevron_right size="16px"
                                    color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                 Header
              </summary>
              <div> Section content </div>
            </details>
          </div>
        </body>
      </html>
      |}];
    (* Click to close the accordion *)
    Handle.click_on handle ~selector:(test_selector header_selector);
    Handle.one_frame handle;
    Handle.print_dom_diff handle;
    [%expect
      {|
      === DIFF HUNK ===
        <html>
          <head>
            <meta charset="UTF-8"/>
          </head>
          <body>
            <div>
      -|      <details open="">
      +|      <details>
                <summary>
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                   Header
                </summary>
                <div> Section content </div>
              </details>
            </div>
          </body>
        </html>
      |}]
  ;;
end

module%test Controlled = struct
  let%expect_test "Controlled accordion syncs with external state" =
    let header_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let is_open, set_is_open = Bonsai.state false graph in
        let%arr is_open and set_is_open in
        Node.fragment
          [ Node.sexp_for_debugging [%message (is_open : bool)]
          ; {%html|
              <Accordion.Controlled.view
                ~state:%{is_open, set_is_open}
                ~header:(<Accordion.Header.content ~test_selector:%{header_selector}>Header</>)
              >
                <Accordion.Section.content>Section content</>
              </>
            |}
          ])
    in
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <div>
            <pre> (is_open false) </pre>
            <div>
              <details>
                <summary role="button" aria-expanded="false">
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Header
                </summary>
                <div> Section content </div>
              </details>
            </div>
          </div>
        </body>
      </html>
      |}];
    (* Click to open the accordion *)
    Handle.click_on handle ~selector:(test_selector header_selector);
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <div>
            <pre> (is_open true) </pre>
            <div>
              <details open="">
                <summary role="button" aria-expanded="true">
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Header
                </summary>
                <div> Section content </div>
              </details>
            </div>
          </div>
        </body>
      </html>
      |}];
    (* Click to close the accordion *)
    Handle.click_on handle ~selector:(test_selector header_selector);
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <div>
            <pre> (is_open false) </pre>
            <div>
              <details>
                <summary role="button" aria-expanded="false">
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Header
                </summary>
                <div> Section content </div>
              </details>
            </div>
          </div>
        </body>
      </html>
      |}]
  ;;

  let%expect_test "Controlled accordion can be opened programmatically" =
    let open_button_selector = Test_selector.make () in
    let%with handle =
      Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
        let open Bonsai.Let_syntax in
        let is_open, set_is_open = Bonsai.state false graph in
        let%arr is_open and set_is_open in
        {%html|
          <>
            <button
              %{Test_selector.attr open_button_selector}
              on_click=%{fun _ -> set_is_open true}
            >
              Open programmatically
            </button>
            <Accordion.Controlled.view
              ~state:%{is_open, set_is_open}
              ~header:(<Accordion.Header.content>Header</>)
            >
              <Accordion.Section.content>Section content</>
            </>
          </>
        |})
    in
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <div>
            <button>  Open programmatically  </button>
            <div>
              <details>
                <summary role="button" aria-expanded="false">
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Header
                </summary>
                <div> Section content </div>
              </details>
            </div>
          </div>
        </body>
      </html>
      |}];
    (* Click the button to open programmatically *)
    Handle.click_on handle ~selector:(test_selector open_button_selector);
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <div>
            <button>  Open programmatically  </button>
            <div>
              <details open="">
                <summary role="button" aria-expanded="true">
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Header
                </summary>
                <div> Section content </div>
              </details>
            </div>
          </div>
        </body>
      </html>
      |}]
  ;;
end

module%test Controlled_group = struct
  let make_accordion_group ?initial_open ~header_selectors graph =
    let state =
      Accordion.Controlled.make_grouped_state ?initial_open ~equal:Int.equal graph
    in
    let accordions =
      List.map (List.range 0 3) ~f:(fun accordion_id ->
        let is_open, set_is_open = state (Bonsai.return accordion_id) in
        let%arr is_open and set_is_open in
        {%html|
          <Accordion.Controlled.view
            ~state:%{is_open, set_is_open}
            ~header:(<Accordion.Header.content ~test_selector:%{Test_selector.Keyed.get header_selectors accordion_id}>
              #{sprintf "Accordion %d" accordion_id}
            </>)
          >
            <Accordion.Section.content></>
          </>
        |})
    in
    Bonsai.all accordions >>| Node.fragment
  ;;

  let%expect_test "Controlled_group ensures only one accordion is open at a time" =
    let header_selectors = Test_selector.Keyed.create (module Int) in
    let%with handle =
      Handle.with_
        ~get_vdom:Fn.id
        ~filter_printed_attributes
        (make_accordion_group ~header_selectors)
    in
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <div>
            <div>
              <details>
                <summary role="button" aria-expanded="false">
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Accordion 0
                </summary>
                <div> </div>
              </details>
            </div>
            <div>
              <details>
                <summary role="button" aria-expanded="false">
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Accordion 1
                </summary>
                <div> </div>
              </details>
            </div>
            <div>
              <details>
                <summary role="button" aria-expanded="false">
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Accordion 2
                </summary>
                <div> </div>
              </details>
            </div>
          </div>
        </body>
      </html>
      |}];
    (* Open first accordion *)
    Handle.click_on
      handle
      ~selector:(test_selector (Test_selector.Keyed.get header_selectors 0));
    Handle.one_frame handle;
    Handle.print_dom_diff handle;
    [%expect
      {|
      === DIFF HUNK ===
        <html>
          <head>
            <meta charset="UTF-8"/>
          </head>
          <body>
            <div>
              <div>
      -|        <details>
      +|        <details open="">
      -|          <summary role="button" aria-expanded="false">
      +|          <summary role="button" aria-expanded="true">
                    <icon-chevron_right size="16px"
                                        color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                    Accordion 0
                  </summary>
                  <div> </div>
                </details>
              </div>
              <div>
                <details>
                  <summary role="button" aria-expanded="false">
                    <icon-chevron_right size="16px"
                                        color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                    Accordion 1
                  </summary>
                  <div> </div>
                </details>
      |}];
    (* Open second accordion - first should close *)
    Handle.click_on
      handle
      ~selector:(test_selector (Test_selector.Keyed.get header_selectors 1));
    Handle.one_frame handle;
    Handle.print_dom_diff handle;
    [%expect
      {|
      === DIFF HUNK ===
        <html>
          <head>
            <meta charset="UTF-8"/>
          </head>
          <body>
            <div>
              <div>
      -|        <details open="">
      +|        <details>
      -|          <summary role="button" aria-expanded="true">
      +|          <summary role="button" aria-expanded="false">
                    <icon-chevron_right size="16px"
                                        color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                    Accordion 0
                  </summary>
                  <div> </div>
                </details>
              </div>
              <div>
      -|        <details>
      +|        <details open="">
      -|          <summary role="button" aria-expanded="false">
      +|          <summary role="button" aria-expanded="true">
                    <icon-chevron_right size="16px"
                                        color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                    Accordion 1
                  </summary>
                  <div> </div>
                </details>
              </div>
              <div>
                <details>
                  <summary role="button" aria-expanded="false">
                    <icon-chevron_right size="16px"
                                        color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                    Accordion 2
                  </summary>
                  <div> </div>
                </details>
      |}];
    (* Open third accordion - second should close *)
    Handle.click_on
      handle
      ~selector:(test_selector (Test_selector.Keyed.get header_selectors 2));
    Handle.one_frame handle;
    Handle.print_dom_diff handle;
    [%expect
      {|
      === DIFF HUNK ===
          <head>
            <meta charset="UTF-8"/>
          </head>
          <body>
            <div>
              <div>
                <details>
                  <summary role="button" aria-expanded="false">
                    <icon-chevron_right size="16px"
                                        color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                    Accordion 0
                  </summary>
                  <div> </div>
                </details>
              </div>
              <div>
      -|        <details open="">
      +|        <details>
      -|          <summary role="button" aria-expanded="true">
      +|          <summary role="button" aria-expanded="false">
                    <icon-chevron_right size="16px"
                                        color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                    Accordion 1
                  </summary>
                  <div> </div>
                </details>
              </div>
              <div>
      -|        <details>
      +|        <details open="">
      -|          <summary role="button" aria-expanded="false">
      +|          <summary role="button" aria-expanded="true">
                    <icon-chevron_right size="16px"
                                        color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                    Accordion 2
                  </summary>
                  <div> </div>
                </details>
              </div>
            </div>
          </body>
        </html>
      |}];
    (* Close the third accordion *)
    Handle.click_on
      handle
      ~selector:(test_selector (Test_selector.Keyed.get header_selectors 2));
    Handle.one_frame handle;
    Handle.print_dom_diff handle;
    [%expect
      {|
      === DIFF HUNK ===
                    Accordion 0
                  </summary>
                  <div> </div>
                </details>
              </div>
              <div>
                <details>
                  <summary role="button" aria-expanded="false">
                    <icon-chevron_right size="16px"
                                        color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                    Accordion 1
                  </summary>
                  <div> </div>
                </details>
              </div>
              <div>
      -|        <details open="">
      +|        <details>
      -|          <summary role="button" aria-expanded="true">
      +|          <summary role="button" aria-expanded="false">
                    <icon-chevron_right size="16px"
                                        color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                    Accordion 2
                  </summary>
                  <div> </div>
                </details>
              </div>
            </div>
          </body>
        </html>
      |}]
  ;;

  let%expect_test "Controlled_group with initial_open parameter" =
    let header_selectors = Test_selector.Keyed.create (module Int) in
    let%with handle =
      Handle.with_
        ~get_vdom:Fn.id
        ~filter_printed_attributes
        (make_accordion_group ~initial_open:2 ~header_selectors)
    in
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <div>
            <div>
              <details>
                <summary role="button" aria-expanded="false">
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Accordion 0
                </summary>
                <div> </div>
              </details>
            </div>
            <div>
              <details>
                <summary role="button" aria-expanded="false">
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Accordion 1
                </summary>
                <div> </div>
              </details>
            </div>
            <div>
              <details open="">
                <summary role="button" aria-expanded="true">
                  <icon-chevron_right size="16px"
                                      color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-chevron_right>
                  Accordion 2
                </summary>
                <div> </div>
              </details>
            </div>
          </div>
        </body>
      </html>
      |}]
  ;;
end
