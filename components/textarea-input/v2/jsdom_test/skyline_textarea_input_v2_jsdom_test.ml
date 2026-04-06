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

let%expect_test "Textarea updates value on input" =
  let textarea_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
      let value, set_value = Bonsai.state "" graph in
      let%arr value and set_value in
      let view =
        Skyline_field_v2.view
          ~test_selector:textarea_selector
          [ Skyline_textarea_input_v2.content ~state:(value, set_value) () ]
      in
      {%html|
        <div>
          %{view}
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
              <textarea rows="2"> </textarea>
            </div>
          </label>
          <div> Current value:  </div>
        </div>
      </body>
    </html>
    |}];
  (* Type into the textarea *)
  Handle.set_input_element_value
    handle
    ~selector:(test_selector textarea_selector)
    ~value:"Hello";
  Handle.one_frame handle;
  Handle.print_dom_diff handle;
  [%expect
    {|
    ("Not setting value, because node doesn't have a value prop" (value Hello)
     (here
      lib/skyline/components/textarea-input/v2/jsdom_test/skyline_textarea_input_v2_jsdom_test.ml:59:2))
    |}]
;;

let%expect_test "Textarea disabled state" =
  let textarea_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
      let value, set_value = Bonsai.state "" graph in
      let%arr value and set_value in
      Skyline_field_v2.view
        ~disabled:true
        [ Skyline_textarea_input_v2.content
            ~test_selector:textarea_selector
            ~state:(value, set_value)
            ()
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
        <label>
          <div>
            <textarea rows="2" disabled="" aria-disabled="true"> </textarea>
          </div>
        </label>
      </body>
    </html>
    |}];
  (* Try to type into the disabled textarea - it should not change *)
  Handle.set_input_element_value
    handle
    ~selector:(test_selector textarea_selector)
    ~value:"Hello";
  Handle.one_frame handle;
  Handle.print_dom_diff handle;
  [%expect {| |}]
;;
