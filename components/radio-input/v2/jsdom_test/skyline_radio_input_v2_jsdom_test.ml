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

let%expect_test "Radio is selected on click" =
  let radio_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
      let value, set_value = Bonsai.state "" graph in
      let%arr value and set_value in
      let radio_view =
        Skyline_field_v2.view
          [ Skyline_radio_input_v2.content
              ~test_selector:radio_selector
              ~group:"test-group"
              ~state:(String.equal value "test", set_value "test")
              ()
          ]
      in
      {%html|
        <div>
          %{radio_view}
          <div>Current value: #{value}</div>
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
                  <input type="radio" name="test-group"/>
                </div>
              </span>
            </div>
          </label>
          <div> Current value:  </div>
        </div>
      </body>
    </html>
    |}];
  Handle.click_on handle ~selector:(test_selector radio_selector);
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
                    <input type="radio" name="test-group"/>
                  </div>
                </span>
              </div>
            </label>
    -|      <div> Current value:  </div>
    +|      <div> Current value: test </div>
          </div>
        </body>
      </html>
    |}]
;;

let%expect_test "Disabled radio cannot be clicked" =
  let radio_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
      let value, set_value = Bonsai.state "" graph in
      let%arr value and set_value in
      let radio_view =
        Skyline_field_v2.view
          ~disabled:true
          [ Skyline_radio_input_v2.content
              ~test_selector:radio_selector
              ~group:"test-group"
              ~state:(String.equal value "disabled-test", set_value "disabled-test")
              ()
          ]
      in
      {%html|
        <div>
          %{radio_view}
          <div>Current value: #{value}</div>
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
                  <input type="radio" name="test-group" disabled=""/>
                </div>
              </span>
            </div>
          </label>
          <div> Current value:  </div>
        </div>
      </body>
    </html>
    |}];
  Handle.click_on handle ~selector:(test_selector radio_selector);
  Handle.one_frame handle;
  Handle.print_dom_diff handle;
  (* No diff expected since disabled radio shouldn't respond to clicks *)
  [%expect {| |}]
;;
