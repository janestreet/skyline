open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
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
      || String.is_prefix key ~prefix:"data-")
;;

let%expect_test "Switch toggles on click" =
  let checkbox_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
      let value, set_value = Bonsai.state false graph in
      let%arr value and set_value in
      let checkbox_view =
        Skyline_field_v2.view
          [ Skyline_switch_v2.content
              ~test_selector:checkbox_selector
              ~state:(value, set_value)
              ()
          ]
      in
      {%html|
        <div>
          %{checkbox_view}
          <div>Current value: #{Bool.to_string value}</div>
        </div>
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
          <label>
            <div>
              <span>
                <div>
                  <div>
                    <input type="checkbox"/>
                    <div>
                      <div> </div>
                    </div>
                  </div>
                </div>
              </span>
            </div>
          </label>
          <div> Current value: false </div>
        </div>
      </body>
    </html>
    |}];
  Handle.click_on handle ~selector:(test_selector checkbox_selector);
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
            <label>
              <div>
                <span>
                  <div>
                    <div>
    -|                <input type="checkbox"/>
    +|                <input type="checkbox" checked=""/>
                      <div>
                        <div> </div>
                      </div>
                    </div>
                  </div>
                </span>
              </div>
            </label>
    -|      <div> Current value: false </div>
    +|      <div> Current value: true </div>
          </div>
        </body>
      </html>
    |}]
;;
