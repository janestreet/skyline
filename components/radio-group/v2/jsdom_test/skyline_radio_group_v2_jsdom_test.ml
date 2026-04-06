open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
open! Jsdom
module Handle = Handle_experimental
module Radio_group = Skyline_radio_group_v2

let filter_printed_attributes ~key ~data:_ =
  not String.(key = "style" || key = "class" || key = "id")
;;

let test_selectors = Test_selector.Keyed.create (module String)

let make_handle ?(initial_value = "test1") () =
  let component graph =
    let values_var = Bonsai.Expert.Var.create [ "test1"; "test2"; "test3" ] in
    let values = Bonsai.Expert.Var.value values_var in
    let current_value, set_value = Bonsai.state initial_value graph in
    let%arr current_value and set_value and values in
    let vdom =
      Radio_group.view
        ~name:"test-radio-group"
        ~test_selectors
        ~state:(current_value, set_value)
        ~equal:String.equal
        ~to_string:Fn.id
        ~values
        ()
    in
    vdom, current_value, values
  in
  fun do_with_handle ->
    Handle.with_
      component
      ~get_vdom:(fun (vdom, _, _) -> vdom)
      (fun handle -> do_with_handle handle)
;;

let print_state handle =
  let _vdom, selected, values = Handle.last_result handle in
  Radio_group.For_testing.ascii_render
    ~selected
    ~values
    ~to_string:Fn.id
    ~equal:String.equal
  |> print_endline
;;

let one_frame_and_print handle =
  Handle.one_frame handle;
  print_state handle
;;

let%expect_test "initial state: first item is selected" =
  let%with handle = make_handle () in
  one_frame_and_print handle;
  [%expect
    {|
    ┌───────────┐
    │ Value     │
    ├───────────┤
    │ [x] test1 │
    │ [ ] test2 │
    │ [ ] test3 │
    └───────────┘
    |}]
;;

let%expect_test "click on radio input updates selection" =
  let%with handle = make_handle () in
  one_frame_and_print handle;
  [%expect
    {|
    ┌───────────┐
    │ Value     │
    ├───────────┤
    │ [x] test1 │
    │ [ ] test2 │
    │ [ ] test3 │
    └───────────┘
    |}];
  (* Click on the second radio input *)
  Handle.click_on
    handle
    ~selector:
      (Bonsai_web_test.test_selector (Test_selector.Keyed.get test_selectors "test2"));
  one_frame_and_print handle;
  [%expect
    {|
    ┌───────────┐
    │ Value     │
    ├───────────┤
    │ [ ] test1 │
    │ [x] test2 │
    │ [ ] test3 │
    └───────────┘
    |}];
  (* Click on the third radio input *)
  Handle.click_on
    handle
    ~selector:
      (Bonsai_web_test.test_selector (Test_selector.Keyed.get test_selectors "test3"));
  one_frame_and_print handle;
  [%expect
    {|
    ┌───────────┐
    │ Value     │
    ├───────────┤
    │ [ ] test1 │
    │ [ ] test2 │
    │ [x] test3 │
    └───────────┘
    |}]
;;

let%expect_test "vdom sanity check" =
  let%with handle =
    Handle.with_
      (fun graph ->
        let current_value, set_value = Bonsai.state "test2" graph in
        let%arr current_value and set_value in
        Radio_group.view
          ~name:"test-radio-group"
          ~state:(current_value, set_value)
          ~equal:String.equal
          ~to_string:Fn.id
          ~values:[ "test1"; "test2"; "test3" ]
          ())
      ~filter_printed_attributes
      ~get_vdom:Fn.id
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
        <fieldset tabindex="0">
          <label>
            <div>
              <span data-skyline-component="text">
                <div>
                  <input type="radio" name="test-radio-group"/>
                </div>
              </span>
            </div>
            <div>
              <div> test1 </div>
            </div>
          </label>
          <label>
            <div>
              <span data-skyline-component="text">
                <div>
                  <input type="radio" name="test-radio-group"/>
                </div>
              </span>
            </div>
            <div>
              <div> test2 </div>
            </div>
          </label>
          <label>
            <div>
              <span data-skyline-component="text">
                <div>
                  <input type="radio" name="test-radio-group"/>
                </div>
              </span>
            </div>
            <div>
              <div> test3 </div>
            </div>
          </label>
        </fieldset>
      </body>
    </html>
    |}]
;;
