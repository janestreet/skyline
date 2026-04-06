open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
open! Jsdom
module Handle = Handle_experimental
module Options = Skyline_menu_v2.Options
module Menu = Skyline_menu_v2

let test_selector = Bonsai_web_test.test_selector

let filter_printed_attributes ~key ~data:_ =
  not
    String.(
      key = "style"
      || key = "class"
      || key = "id"
      || String.is_prefix key ~prefix:"data-bonsai-popover")
;;

let sample_options ~on_item_click =
  {%html|
    <Options.create>
      <Options.item ~key:%{"item-1"} ~on_click:%{on_item_click "item-1"}>
        Item 1
      </>
      <Options.item ~key:%{"item-2"} ~on_click:%{on_item_click "item-2"}>
        Item 2
      </>
    </>
  |}
;;

(* Basic rendering test - menu starts closed *)
let%expect_test "menu starts in closed state" =
  let button_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let menu = Menu.component graph in
      let options = return (sample_options ~on_item_click:(fun _ -> Effect.Ignore)) in
      let%arr menu and options in
      {%html|
        <div>
          <button
            %{Test_selector.attr button_selector}
            %{Menu.on_click menu ~options:(Effect.return options)}
          >
            Open Menu
          </button>
        </div>
      |})
  in
  Handle.print_dom handle;
  [%expect
    {|
    <html>
      <head>
        <meta charset="UTF-8"/>
      </head>
      <body>
        <div tabindex="0">
          <button>  Open Menu  </button>
        </div>
      </body>
      <div> </div>
    </html>
    |}];
  ()
;;

(* Test clicking opens menu *)
let%expect_test "clicking button opens menu" =
  let button_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let menu = Menu.component graph in
      let options = return (sample_options ~on_item_click:(fun _ -> Effect.Ignore)) in
      let%arr menu and options in
      {%html|
        <div>
          <button
            %{Test_selector.attr button_selector}
            %{Menu.on_click menu ~options:(Effect.return options)}
          >
            Open Menu
          </button>
        </div>
      |})
  in
  Handle.click_on handle ~selector:(test_selector button_selector);
  Handle.one_frame handle;
  Handle.print_dom handle;
  [%expect
    {|
    <html>
      <head>
        <meta charset="UTF-8"/>
      </head>
      <body>
        <div tabindex="0">
          <button>  Open Menu  </button>
        </div>
      </body>
      <div>
        <div popover="manual" tabindex="-1" mock-popover-state="open">
          <div>
            <div data-focus-handle="bonsai_path_replaced_in_test" tabindex="0">
              <button tabindex="-1" data-menu-item="item-1">
                <div>  Item 1  </div>
              </button>
              <button tabindex="-1" data-menu-item="item-2">
                <div>  Item 2  </div>
              </button>
            </div>
          </div>
          <div> </div>
        </div>
      </div>
    </html>
    |}];
  ()
;;

(* Test that listbox receives focus when menu opens *)
let%expect_test "listbox receives focus when menu opens" =
  let button_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let menu = Menu.component graph in
      let options = return (sample_options ~on_item_click:(fun _ -> Effect.Ignore)) in
      let%arr menu and options in
      {%html|
        <div>
          <button
            %{Test_selector.attr button_selector}
            %{Menu.on_click menu ~options:(Effect.return options)}
          >
            Open Menu
          </button>
        </div>
      |})
  in
  (* Before opening, print active element *)
  Handle.print_active_element handle;
  [%expect {| <div tabindex="0"> ... </div> |}];
  (* Open the menu *)
  Handle.click_on handle ~selector:(test_selector button_selector);
  Handle.one_frame handle;
  (* After opening, the listbox container should have focus *)
  Handle.print_active_element ~depth:1 handle;
  [%expect
    {|
    <div data-focus-handle="bonsai_path_replaced_in_test" tabindex="0">
      <button tabindex="-1" data-menu-item="item-1"> ... </button>
      <button tabindex="-1" data-menu-item="item-2"> ... </button>
    </div>
    |}];
  ()
;;

(* Test clicking menu item triggers on_click effect *)
let%expect_test "clicking menu item triggers on_click" =
  let button_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let menu = Menu.component graph in
      let options =
        return
          (sample_options ~on_item_click:(fun key ->
             Effect.print_s [%message "Clicked" (key : string)]))
      in
      let%arr menu and options in
      {%html|
        <div>
          <button
            %{Test_selector.attr button_selector}
            %{Menu.on_click menu ~options:(Effect.return options)}
          >
            Open Menu
          </button>
        </div>
      |})
  in
  (* Open the menu *)
  Handle.click_on handle ~selector:(test_selector button_selector);
  Handle.one_frame handle;
  (* Click on item-1 *)
  Handle.click_on handle ~selector:{|[data-menu-item="item-1"]|};
  Handle.one_frame handle;
  [%expect {| (Clicked (key item-1)) |}];
  ()
;;

(* Test context menu opens on right-click *)
let%expect_test "context menu opens on right-click" =
  let area_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let menu = Menu.component graph in
      let options = return (sample_options ~on_item_click:(fun _ -> Effect.Ignore)) in
      let%arr menu and options in
      {%html|
        <div
          %{Test_selector.attr area_selector}
          %{Menu.on_contextmenu menu ~options:(Effect.return options)}
        >
          Right-click area
        </div>
      |})
  in
  Handle.print_dom handle;
  [%expect
    {|
    <html>
      <head>
        <meta charset="UTF-8"/>
      </head>
      <body>
        <div tabindex="0">  Right-click area  </div>
      </body>
      <div> </div>
    </html>
    |}];
  Handle.right_click_on handle ~selector:(test_selector area_selector);
  Handle.one_frame handle;
  Handle.print_dom handle;
  [%expect
    {|
    <html>
      <head>
        <meta charset="UTF-8"/>
      </head>
      <body>
        <div tabindex="0">  Right-click area  </div>
      </body>
      <div>
        <div popover="manual" tabindex="-1" mock-popover-state="open">
          <div>
            <div data-focus-handle="bonsai_path_replaced_in_test" tabindex="0">
              <button tabindex="-1" data-menu-item="item-1">
                <div>  Item 1  </div>
              </button>
              <button tabindex="-1" data-menu-item="item-2">
                <div>  Item 2  </div>
              </button>
            </div>
          </div>
          <div> </div>
        </div>
      </div>
    </html>
    |}];
  ()
;;

(* Test controlled state *)
let%expect_test "controlled state works" =
  let button_selector = Test_selector.make () in
  let close_button_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let state, set_state = Bonsai.state Menu.State.Closed graph in
      let menu = Menu.component ~state:(state, set_state) graph in
      let options = return (sample_options ~on_item_click:(fun _ -> Effect.Ignore)) in
      let%arr menu and set_state and options in
      {%html|
        <div>
          <button
            %{Test_selector.attr button_selector}
            %{Menu.on_click menu ~options:(Effect.return options)}
          >
            Open
          </button>
          <button
            %{Test_selector.attr close_button_selector}
            on_click=%{fun _ -> set_state Menu.State.Closed}
          >
            Close
          </button>
        </div>
      |})
  in
  (* Menu starts closed *)
  Handle.print_dom handle;
  [%expect
    {|
    <html>
      <head>
        <meta charset="UTF-8"/>
      </head>
      <body>
        <div tabindex="0">
          <button>  Open  </button>
          <button>  Close  </button>
        </div>
      </body>
      <div> </div>
    </html>
    |}];
  (* Open menu *)
  Handle.click_on handle ~selector:(test_selector button_selector);
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
          <div tabindex="0">
            <button>  Open  </button>
            <button>  Close  </button>
          </div>
        </body>
    -|  <div> </div>
    +|  <div>
    +|    <div popover="manual" tabindex="-1" mock-popover-state="open">
    +|      <div>
    +|        <div data-focus-handle="bonsai_path_replaced_in_test" tabindex="0">
    +|          <button tabindex="-1" data-menu-item="item-1">
    +|            <div>  Item 1  </div>
    +|          </button>
    +|          <button tabindex="-1" data-menu-item="item-2">
    +|            <div>  Item 2  </div>
    +|          </button>
    +|        </div>
    +|      </div>
    +|      <div> </div>
    +|    </div>
    +|  </div>
      </html>
    |}];
  (* Close menu using controlled state *)
  Handle.click_on handle ~selector:(test_selector close_button_selector);
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
          <div tabindex="0">
            <button>  Open  </button>
            <button>  Close  </button>
          </div>
        </body>
    -|  <div>
    -|    <div popover="manual" tabindex="-1" mock-popover-state="open">
    -|      <div>
    -|        <div data-focus-handle="bonsai_path_replaced_in_test" tabindex="0">
    -|          <button tabindex="-1" data-menu-item="item-1">
    -|            <div>  Item 1  </div>
    -|          </button>
    -|          <button tabindex="-1" data-menu-item="item-2">
    -|            <div>  Item 2  </div>
    -|          </button>
    -|        </div>
    -|      </div>
    -|      <div> </div>
    -|    </div>
    -|  </div>
    +|  <div> </div>
      </html>
    |}];
  ()
;;
