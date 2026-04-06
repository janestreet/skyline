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

let%expect_test "Text input updates value on input" =
  let input_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
      let value, set_value = Bonsai.state "" graph in
      let%arr value and set_value in
      {%html|
        <div>
          <Skyline_field_v2.view ~test_selector:%{input_selector}>
            <Skyline_text_input_v2.content ~state:%{(value, set_value)} />
          </>
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
              <input type="text"/>
            </div>
          </label>
          <div> Current value:  </div>
        </div>
      </body>
    </html>
    |}];
  (* Type into the input *)
  Handle.set_input_element_value
    handle
    ~selector:(test_selector input_selector)
    ~value:"Hello";
  Handle.one_frame handle;
  Handle.print_dom_diff handle;
  [%expect
    {|
    ("Not setting value, because node doesn't have a value prop" (value Hello)
     (here
      lib/skyline/components/text-input/v2/jsdom_test/skyline_text_input_v2_jsdom_test.ml:56:2))
    |}]
;;

let%expect_test "Input_value_hook" =
  let input_selector = Test_selector.make () in
  let module Input_value_hook = Skyline_text_input_v2.For_testing.Input_value_hook in
  let filter_input s = String.for_all s ~f:Char.is_alpha in
  let parse s = if String.is_empty s || String.length s % 2 <> 0 then None else Some s in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
      let value, set_value = Bonsai.state "" graph in
      let%arr value and set_value in
      let hook_attr =
        Input_value_hook.create ~filter_input ~parse ~state:(value, set_value) ()
      in
      {%html|
        <div>
          <input %{Test_selector.attr input_selector} %{hook_attr} type="text" />
          <span>Value: #{value}</span>
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
          <input type="text"/>
          <span> Value:  </span>
        </div>
      </body>
    </html>
    |}];
  let test_input value =
    Handle.set_input_element_value handle ~selector:(test_selector input_selector) ~value;
    Handle.one_frame handle;
    Handle.print_dom_diff ~context:0 handle
  in
  test_input "a";
  [%expect {| |}];
  test_input "ab";
  [%expect
    {|
    === DIFF HUNK ===
    -|      <span> Value:  </span>
    +|      <span> Value: ab </span>
    |}];
  test_input "abcd";
  [%expect
    {|
    === DIFF HUNK ===
    -|      <span> Value: ab </span>
    +|      <span> Value: abcd </span>
    |}]
;;

let%expect_test "Numeric with Int63" =
  let input_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
      let value, set_value = Bonsai.state None graph in
      let%arr value and set_value in
      let parsed_value =
        match value with
        | None -> "None"
        | Some n -> "(Some " ^ Int63.to_string n ^ ")"
      in
      {%html|
        <div>
          <Skyline_field_v2.view>
            <Skyline_text_input_v2.Numeric.content
              ~stringable:%{(module Int63)}
              ~test_selector:%{input_selector}
              ~state:%{(value, set_value)}
            />
          </>
          <span>Parsed: #{parsed_value}</span>
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
              <input inputmode="decimal" type="text"/>
            </div>
          </label>
          <span> Parsed: None </span>
        </div>
      </body>
    </html>
    |}];
  let test_input value =
    Handle.set_input_element_value handle ~selector:(test_selector input_selector) ~value;
    Handle.one_frame handle;
    Handle.print_dom_diff ~context:0 handle
  in
  (* Input should show "-" but not parse as an Int. *)
  test_input "-";
  [%expect {| |}];
  (* Invalid input. *)
  test_input "--";
  [%expect {| |}];
  test_input "-1";
  [%expect
    {|
    === DIFF HUNK ===
    -|      <span> Parsed: None </span>
    +|      <span> Parsed: (Some -1) </span>
    |}]
;;

let%expect_test "Numeric with Float" =
  let input_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
      let value, set_value = Bonsai.state None graph in
      let%arr value and set_value in
      let parsed_value =
        match value with
        | None -> "None"
        | Some n -> "(Some " ^ Float.to_string n ^ ")"
      in
      {%html|
        <div>
          <Skyline_field_v2.view>
            <Skyline_text_input_v2.Numeric.content
              ~stringable:%{(module Float)}
              ~test_selector:%{input_selector}
              ~state:%{(value, set_value)}
            />
          </>
          <span>Parsed: #{parsed_value}</span>
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
              <input inputmode="decimal" type="text"/>
            </div>
          </label>
          <span> Parsed: None </span>
        </div>
      </body>
    </html>
    |}];
  let test_input value =
    Handle.set_input_element_value handle ~selector:(test_selector input_selector) ~value;
    Handle.one_frame handle;
    Handle.print_dom_diff ~context:0 handle
  in
  test_input "1e";
  [%expect {| |}];
  test_input "1e2";
  [%expect
    {|
    === DIFF HUNK ===
    -|      <span> Parsed: None </span>
    +|      <span> Parsed: (Some 100.) </span>
    |}];
  test_input "-.";
  [%expect
    {|
    === DIFF HUNK ===
    -|      <span> Parsed: (Some 100.) </span>
    +|      <span> Parsed: None </span>
    |}];
  test_input "-.1";
  [%expect
    {|
    === DIFF HUNK ===
    -|      <span> Parsed: None </span>
    +|      <span> Parsed: (Some -0.1) </span>
    |}]
;;

module Decimal = Skyline_text_input_v2.Numeric.Decimal
module Price = Skyline_text_input_v2.Numeric.Price

let%expect_test "Decimal.of_string" =
  List.iter
    [ "1"; "1.5"; ".5"; "-1.5"; "0.0"; "0.123456789012"; "nan"; "inf" ]
    ~f:(fun s ->
      let result = Or_error.try_with (fun () -> Decimal.of_string s) in
      print_s [%message (s : string) (result : float Or_error.t)]);
  [%expect
    {|
    ((s 1) (result (Ok 1)))
    ((s 1.5) (result (Ok 1.5)))
    ((s .5) (result (Ok 0.5)))
    ((s -1.5) (result (Ok -1.5)))
    ((s 0.0) (result (Ok 0)))
    ((s 0.123456789012) (result (Ok 0.123456789012)))
    ((s nan)
     (result (Error ("Cannot represent non-finite float as decimal" (s nan)))))
    ((s inf)
     (result (Error ("Cannot represent non-finite float as decimal" (s inf)))))
    |}]
;;

let%expect_test "Decimal.to_string" =
  List.iter [ 1.; 1.5; 0.; -0.123; 100. ] ~f:(fun float ->
    let to_string = Decimal.to_string float in
    let round_tripped = Decimal.to_string (Decimal.of_string to_string) in
    print_s [%message (float : float) (to_string : string) (round_tripped : string)]);
  [%expect
    {|
    ((float 1) (to_string 1) (round_tripped 1))
    ((float 1.5) (to_string 1.5) (round_tripped 1.5))
    ((float 0) (to_string 0) (round_tripped 0))
    ((float -0.123) (to_string -0.123) (round_tripped -0.123))
    ((float 100) (to_string 100) (round_tripped 100))
    |}]
;;

let%expect_test "Price.of_string" =
  List.iter
    [ "1"; "1.5"; "1.50"; "100.00"; "-3.25"; "0.01"; ".99"; "1.500"; "1.123"; "1.13000" ]
    ~f:(fun s ->
      let result =
        Or_error.try_with (fun () ->
          let t = Price.of_string s in
          Price.to_float t)
      in
      print_s [%message (s : string) (result : float Or_error.t)]);
  [%expect
    {|
    ((s 1) (result (Ok 1)))
    ((s 1.5) (result (Ok 1.5)))
    ((s 1.50) (result (Ok 1.5)))
    ((s 100.00) (result (Ok 100)))
    ((s -3.25) (result (Ok -3.25)))
    ((s 0.01) (result (Ok 0.01)))
    ((s .99) (result (Ok 0.99)))
    ((s 1.500)
     (result (Error ("Price cannot have more than 2 decimal places" (s 1.500)))))
    ((s 1.123)
     (result (Error ("Price cannot have more than 2 decimal places" (s 1.123)))))
    ((s 1.13000)
     (result
      (Error ("Price cannot have more than 2 decimal places" (s 1.13000)))))
    |}]
;;

let%expect_test "Price.to_string" =
  List.iter [ 1.5; 1.; 100.; 0.01; -3.25 ] ~f:(fun float ->
    let t = Price.of_float_rounded float |> Option.value_exn in
    let to_string = Price.to_string t in
    let round_tripped = Price.to_string (Price.of_string to_string) in
    print_s [%message (float : float) (to_string : string) (round_tripped : string)]);
  [%expect
    {|
    ((float 1.5) (to_string 1.50) (round_tripped 1.50))
    ((float 1) (to_string 1.00) (round_tripped 1.00))
    ((float 100) (to_string 100.00) (round_tripped 100.00))
    ((float 0.01) (to_string 0.01) (round_tripped 0.01))
    ((float -3.25) (to_string -3.25) (round_tripped -3.25))
    |}]
;;

let%expect_test "Text input disabled state" =
  let input_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun graph ->
      let value, set_value = Bonsai.state "" graph in
      let%arr value and set_value in
      Skyline_field_v2.view
        ~disabled:true
        [ Skyline_text_input_v2.content
            ~test_selector:input_selector
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
            <input disabled="" aria-disabled="true" type="text"/>
          </div>
        </label>
      </body>
    </html>
    |}];
  (* Try to type into the disabled input - it should not change *)
  Handle.set_input_element_value
    handle
    ~selector:(test_selector input_selector)
    ~value:"Hello";
  Handle.one_frame handle;
  Handle.print_dom_diff handle;
  [%expect {| |}]
;;
