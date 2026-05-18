open! Core
open! Bonsai_web
open Bonsai.Let_syntax

module Date_part_input_state =
  Bonsai_web_contrib_date_input_yyyy_mm_dd.Date_part_input_state

module Date_input = Bonsai_web_contrib_date_input_yyyy_mm_dd

module%test [@name "date input"] _ = struct
  let print_state state = print_endline (Date_part_input_state.to_string state)

  let act state action =
    let new_state = Date_part_input_state.For_testing.apply_action state action in
    print_state new_state;
    new_state
  ;;

  let%expect_test "value type over after focus" =
    let state =
      Date_part_input_state.For_testing.initial_state ~format:"yyyy" ~max_value:9999
    in
    print_state state;
    [%expect {| yyyy |}];
    let state = act state (Date_part_input_state.Action.Append_value "1") in
    [%expect {| 0001 |}];
    let state = act state (Date_part_input_state.Action.Append_value "9") in
    [%expect {| 0019 |}];
    let state = act state (Date_part_input_state.Action.Append_value "4") in
    [%expect {| 0194 |}];
    let state = act state Date_part_input_state.Action.Focus in
    [%expect {| 0194 |}];
    let (_ : Date_part_input_state.t) =
      act state (Date_part_input_state.Action.Append_value "2")
    in
    [%expect {| 0002 |}]
  ;;

  let%expect_test "increment decrement" =
    let state =
      Date_part_input_state.For_testing.initial_state ~format:"x" ~max_value:3
    in
    print_state state;
    [%expect {| x |}];
    let state = act state Date_part_input_state.Action.Increase_by_one in
    [%expect {| 1 |}];
    let state = act state Date_part_input_state.Action.Increase_by_one in
    [%expect {| 2 |}];
    let state = act state Date_part_input_state.Action.Increase_by_one in
    [%expect {| 3 |}];
    (* Note that increasing above [max_value] resets to 1. *)
    let state = act state Date_part_input_state.Action.Increase_by_one in
    [%expect {| 1 |}];
    (* Decreasing below 1 changes back to [max_value]. *)
    let state = act state Date_part_input_state.Action.Decrease_by_one in
    [%expect {| 3 |}];
    let state = act state Date_part_input_state.Action.Decrease_by_one in
    [%expect {| 2 |}];
    let state = act state Date_part_input_state.Action.Decrease_by_one in
    [%expect {| 1 |}];
    let (_ : Date_part_input_state.t) =
      act state Date_part_input_state.Action.Decrease_by_one
    in
    [%expect {| 3 |}]
  ;;
end

module%test [@name "backspace on empty field moves to previous field"] _ = struct
  module Handle = Bonsai_web_test.Handle
  module Result_spec = Bonsai_web_test.Result_spec

  let dd_selector = Test_selector.make ~name:"dd" ()

  let date_input_component (local_ graph) =
    let state = Date_input.State.create graph in
    let%arr state in
    Date_input.view
      ~state
      [ Date_input.yyyy_part ()
      ; Date_input.delimiter ()
      ; Date_input.mm_part ()
      ; Date_input.delimiter ()
      ; Date_input.dd_part ~test_selector:dd_selector ()
      ]
  ;;

  let create_handle () =
    Handle.create
      (Result_spec.vdom Fn.id ~censor_paths:true ~censor_hash:true)
      date_input_component
  ;;

  let keydown handle ~selector ~key = Handle.keydown handle ~get_vdom:Fn.id ~selector ~key

  let%expect_test "first backspace clears a filled field, second fires focus_prev_part" =
    let handle = create_handle () in
    let dd_sel = Bonsai_web_test.test_selector dd_selector in
    (* Type "15" into DD *)
    keydown handle ~selector:dd_sel ~key:Digit1;
    keydown handle ~selector:dd_sel ~key:Digit5;
    Handle.show handle;
    [%expect
      {|
      <div tabindex="-1" @on_focus>
        <div tabindex="0" @on_click @on_focus @on_keydown> YYYY </div>
        <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
        <div tabindex="0" @on_click @on_focus @on_keydown> MM </div>
        <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
        <div tabindex="0" @on_click @on_focus @on_keydown> 15 </div>

        <input type="date"
               spellcheck="false"
               id="bonsai_path_replaced_in_test"
               tabindex="-1"
               class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"
               value:normalized=""
               @on_click
               @on_input/>
      </div>
      |}];
    (* First backspace: clears DD *)
    keydown handle ~selector:dd_sel ~key:Backspace;
    Handle.show_diff handle;
    [%expect
      {|
      ("default prevented" (key Backspace))

        <div tabindex="-1" @on_focus>
          <div tabindex="0" @on_click @on_focus @on_keydown> YYYY </div>
          <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
          <div tabindex="0" @on_click @on_focus @on_keydown> MM </div>
          <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
      -|  <div tabindex="0" @on_click @on_focus @on_keydown> 15 </div>
      +|  <div tabindex="0" @on_click @on_focus @on_keydown> DD </div>

          <input type="date"
                 spellcheck="false"
                 id="bonsai_path_replaced_in_test"
                 tabindex="-1"
                 class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"
                 value:normalized=""
                 @on_click
                 @on_input/>
        </div>
      |}];
    (* Second backspace on empty DD: fires focus_prev_part, focuses MM, no diff *)
    keydown handle ~selector:dd_sel ~key:Backspace;
    Handle.show_diff handle;
    [%expect
      {|
      ("default prevented" (key Backspace))
      ("focus effect for" mm)
      |}]
  ;;
end

module%test [@name "disabled"] _ = struct
  module Handle = Bonsai_web_test.Handle
  module Result_spec = Bonsai_web_test.Result_spec

  let date_input_component ~disabled (local_ graph) =
    let state = Date_input.State.create graph in
    let%arr state and disabled in
    Date_input.view
      ~disabled
      ~state
      [ Date_input.yyyy_part ()
      ; Date_input.delimiter ()
      ; Date_input.mm_part ()
      ; Date_input.delimiter ()
      ; Date_input.dd_part ()
      ]
  ;;

  let create_handle ~disabled =
    let disabled_var = Bonsai.Expert.Var.create disabled in
    let disabled = Bonsai.Expert.Var.value disabled_var in
    let handle =
      Handle.create
        (Result_spec.vdom Fn.id ~censor_paths:true ~censor_hash:true)
        (date_input_component ~disabled)
    in
    handle, disabled_var
  ;;

  let%expect_test "enabled view has interactive attrs" =
    let handle, _ = create_handle ~disabled:false in
    Handle.show handle;
    [%expect
      {|
      <div tabindex="-1" @on_focus>
        <div tabindex="0" @on_click @on_focus @on_keydown> YYYY </div>
        <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
        <div tabindex="0" @on_click @on_focus @on_keydown> MM </div>
        <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
        <div tabindex="0" @on_click @on_focus @on_keydown> DD </div>

        <input type="date"
               spellcheck="false"
               id="bonsai_path_replaced_in_test"
               tabindex="-1"
               class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"
               value:normalized=""
               @on_click
               @on_input/>
      </div>
      |}]
  ;;

  let%expect_test "disabled view omits interactive attrs" =
    let handle, _ = create_handle ~disabled:true in
    Handle.show handle;
    [%expect
      {|
      <div tabindex="-1">
        <div> YYYY </div>
        <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
        <div> MM </div>
        <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
        <div> DD </div>

        <input disabled=""
               type="date"
               spellcheck="false"
               id="bonsai_path_replaced_in_test"
               tabindex="-1"
               class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"
               value:normalized=""
               @on_click
               @on_input/>
      </div>
      |}]
  ;;

  let%expect_test "switching from enabled to disabled removes interactive attrs" =
    let handle, disabled_var = create_handle ~disabled:false in
    Handle.show handle;
    [%expect
      {|
      <div tabindex="-1" @on_focus>
        <div tabindex="0" @on_click @on_focus @on_keydown> YYYY </div>
        <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
        <div tabindex="0" @on_click @on_focus @on_keydown> MM </div>
        <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
        <div tabindex="0" @on_click @on_focus @on_keydown> DD </div>

        <input type="date"
               spellcheck="false"
               id="bonsai_path_replaced_in_test"
               tabindex="-1"
               class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"
               value:normalized=""
               @on_click
               @on_input/>
      </div>
      |}];
    Bonsai.Expert.Var.set disabled_var true;
    Handle.show_diff handle;
    [%expect
      {|
      -|<div tabindex="-1" @on_focus>
      +|<div tabindex="-1">
      -|  <div tabindex="0" @on_click @on_focus @on_keydown> YYYY </div>
      +|  <div> YYYY </div>
          <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
      -|  <div tabindex="0" @on_click @on_focus @on_keydown> MM </div>
      +|  <div> MM </div>
          <div class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"> - </div>
      -|  <div tabindex="0" @on_click @on_focus @on_keydown> DD </div>
      +|  <div> DD </div>

      -|  <input type="date"
      +|  <input disabled=""
      +|         type="date"
                 spellcheck="false"
                 id="bonsai_path_replaced_in_test"
                 tabindex="-1"
                 class="bonsai_web_contrib_date_input_yyyy_mm_dd__inline_class_hash_replaced_in_test"
                 value:normalized=""
                 @on_click
                 @on_input/>
        </div>
      |}]
  ;;
end
