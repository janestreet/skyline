open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
open! Jsdom
module Handle = Handle_experimental
module Options = Skyline_menu_v2.Options

let test_selector = Bonsai_web_test.test_selector

let filter_printed_attributes ~key ~data:_ =
  not String.(key = "style" || key = "class" || key = "id")
;;

(* Basic rendering test *)
let%expect_test "renders basic options" =
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.item ~key:%{"item-1"} ~on_click:%{Effect.Ignore}>
                First Item
              </>
              <Options.item ~key:%{"item-2"} ~on_click:%{Effect.Ignore}>
                Second Item
              </>
            </>
          |}
      in
      let component =
        Options.Expert.component ~close:(return Effect.Ignore) options graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
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
          <div tabindex="0">
            <button tabindex="-1" data-menu-item="item-1">
              <div>  First Item  </div>
            </button>
            <button tabindex="-1" data-menu-item="item-2">
              <div>  Second Item  </div>
            </button>
          </div>
        </div>
      </body>
    </html>
    |}];
  ()
;;

(* Test clicking items triggers their effects *)
let%expect_test "clicking item triggers on_click effect" =
  let module Key = struct
    type t = string Nonempty_list.t [@@deriving sexp_of]
  end
  in
  let items_test_selectors = Test_selector.Keyed.create (module Key) in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.item
                ~key:%{"clickable"}
                ~on_click:%{Effect.print_s [%message "Item clicked"]}
              >
                Click Me
              </>
            </>
          |}
      in
      let component =
        Options.Expert.component
          ~items_test_selectors:(return items_test_selectors)
          ~close:(return Effect.Ignore)
          options
          graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
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
          <div tabindex="0">
            <button tabindex="-1" data-menu-item="clickable">
              <div>  Click Me  </div>
            </button>
          </div>
        </div>
      </body>
    </html>
    |}];
  Handle.click_on
    handle
    ~selector:
      (test_selector
         (Test_selector.Keyed.get
            items_test_selectors
            (Nonempty_list.singleton "clickable")));
  Handle.one_frame handle;
  [%expect {| "Item clicked" |}];
  ()
;;

(* Test disabled items don't trigger effects *)
let%expect_test "disabled items don't trigger on_click" =
  let module Key = struct
    type t = string Nonempty_list.t [@@deriving sexp_of]
  end
  in
  let items_test_selectors = Test_selector.Keyed.create (module Key) in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.item
                ~key:%{"disabled"}
                ~disabled:%{true}
                ~on_click:%{Effect.print_s [%message "Disabled item clicked"]}
              >
                Disabled Item
              </>
            </>
          |}
      in
      let component =
        Options.Expert.component
          ~items_test_selectors:(return items_test_selectors)
          ~close:(return Effect.Ignore)
          options
          graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
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
          <div tabindex="0">
            <button tabindex="-1" data-menu-item="disabled" disabled="">
              <div>  Disabled Item  </div>
            </button>
          </div>
        </div>
      </body>
    </html>
    |}];
  (* Attempt to click - should not print anything because disabled items don't trigger *)
  Handle.click_on
    handle
    ~selector:
      (test_selector
         (Test_selector.Keyed.get
            items_test_selectors
            (Nonempty_list.singleton "disabled")));
  Handle.one_frame handle;
  [%expect {| |}];
  ()
;;

(* Test that clicking an item also triggers close effect *)
let%expect_test "clicking item triggers close effect" =
  let module Key = struct
    type t = string Nonempty_list.t [@@deriving sexp_of]
  end
  in
  let items_test_selectors = Test_selector.Keyed.create (module Key) in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.item
                ~key:%{"item"}
                ~on_click:%{Effect.print_s [%message "Item clicked"]}
              >
                Item
              </>
            </>
          |}
      in
      let component =
        Options.Expert.component
          ~items_test_selectors:(return items_test_selectors)
          ~close:(return (Effect.print_s [%message "Close triggered"]))
          options
          graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
  in
  Handle.click_on
    handle
    ~selector:
      (test_selector
         (Test_selector.Keyed.get items_test_selectors (Nonempty_list.singleton "item")));
  Handle.one_frame handle;
  [%expect
    {|
    "Close triggered"
    "Item clicked"
    |}];
  ()
;;

(* Test separators and titles render correctly *)
let%expect_test "separators and titles render" =
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.title>Section Title</>
              <Options.item ~key:%{"item"} ~on_click:%{Effect.Ignore}
                >Item</>
              <Options.separator />
            </>
          |}
      in
      let component =
        Options.Expert.component ~close:(return Effect.Ignore) options graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
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
          <div tabindex="0">
            <div>
              <div> Section Title </div>
            </div>
            <button tabindex="-1" data-menu-item="item">
              <div> Item </div>
            </button>
            <hr/>
          </div>
        </div>
      </body>
    </html>
    |}];
  ()
;;

(* Test submenu structure *)
let%expect_test "submenu renders with trigger" =
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.Sub_menu.create
                ~key:%{"submenu"}
                ~trigger:(<Options.Sub_menu.Trigger.create
                  >Open Submenu</>)
              >
                <Options.item ~key:%{"sub-item"} ~on_click:%{Effect.Ignore}>
                  Sub Item
                </>
              </>
            </>
          |}
      in
      let component =
        Options.Expert.component ~close:(return Effect.Ignore) options graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
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
          <div tabindex="0">
            <button tabindex="-1" data-menu-item="submenu">
              <div>
                <div> Open Submenu </div>
                <icon-chevron_right size="16px"> </icon-chevron_right>
              </div>
            </button>
          </div>
        </div>
      </body>
    </html>
    |}];
  ()
;;

(* Test icons render correctly *)
let%expect_test "items with icons render correctly" =
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.item
                ~key:%{"with-icon"}
                ~icon:%{Lucide.star}
                ~on_click:%{Effect.Ignore}
              >
                With Icon
              </>
              <Options.item ~key:%{"no-icon"} ~on_click:%{Effect.Ignore}>
                No Icon
              </>
            </>
          |}
      in
      let component =
        Options.Expert.component ~close:(return Effect.Ignore) options graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
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
          <div tabindex="0">
            <button tabindex="-1" data-menu-item="with-icon">
              <icon-star size="16px"> </icon-star>
              <div>  With Icon  </div>
            </button>
            <button tabindex="-1" data-menu-item="no-icon">
              <div>  No Icon  </div>
            </button>
          </div>
        </div>
      </body>
    </html>
    |}];
  ()
;;

(* Test test_selector on items *)
let%expect_test "test selectors work on items" =
  let item_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.item
                ~test_selector:%{item_selector}
                ~key:%{"item"}
                ~on_click:%{Effect.print_s [%message "Item clicked"]}
              >
                Item
              </>
            </>
          |}
      in
      let component =
        Options.Expert.component ~close:(return Effect.Ignore) options graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
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
          <div tabindex="0">
            <button tabindex="-1" data-menu-item="item">
              <div>  Item  </div>
            </button>
          </div>
        </div>
      </body>
    </html>
    |}];
  (* Click using the individual test selector *)
  Handle.click_on handle ~selector:(test_selector item_selector);
  Handle.one_frame handle;
  [%expect {| "Item clicked" |}];
  ()
;;

(* Test keyed test selectors *)
let%expect_test "keyed test selectors work" =
  let module Key = struct
    type t = string Nonempty_list.t [@@deriving sexp_of]
  end
  in
  let items_test_selectors = Test_selector.Keyed.create (module Key) in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.item
                ~key:%{"first"}
                ~on_click:%{Effect.print_s [%message "First item clicked"]}
              >
                First
              </>
              <Options.Sub_menu.create
                ~key:%{"submenu"}
                ~trigger:(<Options.Sub_menu.Trigger.create>Submenu</>)
              >
                <Options.item ~key:%{"nested"} ~on_click:%{Effect.Ignore}>
                  Nested
                </>
              </>
            </>
          |}
      in
      let component =
        Options.Expert.component
          ~items_test_selectors:(return items_test_selectors)
          ~close:(return Effect.Ignore)
          options
          graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
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
          <div tabindex="0">
            <button tabindex="-1" data-menu-item="first">
              <div>  First  </div>
            </button>
            <button tabindex="-1" data-menu-item="submenu">
              <div>
                <div> Submenu </div>
                <icon-chevron_right size="16px"> </icon-chevron_right>
              </div>
            </button>
          </div>
        </div>
      </body>
    </html>
    |}];
  (* Click using keyed test selector *)
  Handle.click_on
    handle
    ~selector:
      (test_selector
         (Test_selector.Keyed.get items_test_selectors (Nonempty_list.singleton "first")));
  Handle.one_frame handle;
  [%expect {| "First item clicked" |}];
  ()
;;

(* Test arrow key navigation including submenus *)
let%expect_test "arrow keys navigate through items and submenus" =
  let options_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.item ~key:%{"first"} ~on_click:%{Effect.Ignore}>
                First Item
              </>
              <Options.item
                ~key:%{"second"}
                ~disabled:%{true}
                ~on_click:%{Effect.Ignore}
              >
                Disabled Item
              </>
              <Options.Sub_menu.create
                ~key:%{"submenu"}
                ~trigger:(<Options.Sub_menu.Trigger.create>Submenu</>)
              >
                <Options.item ~key:%{"sub-1"} ~on_click:%{Effect.Ignore}>
                  Sub Item 1
                </>
                <Options.item ~key:%{"sub-2"} ~on_click:%{Effect.Ignore}>
                  Sub Item 2
                </>
              </>
              <Options.item ~key:%{"third"} ~on_click:%{Effect.Ignore}>
                Third Item
              </>
            </>
          |}
      in
      let component =
        Options.Expert.component
          ~test_selector:(return options_selector)
          ~close:(return Effect.Ignore)
          options
          graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
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
          <div tabindex="0">
            <button tabindex="-1" data-menu-item="first">
              <div>  First Item  </div>
            </button>
            <button tabindex="-1" data-menu-item="second" disabled="">
              <div>  Disabled Item  </div>
            </button>
            <button tabindex="-1" data-menu-item="submenu">
              <div>
                <div> Submenu </div>
                <icon-chevron_right size="16px"> </icon-chevron_right>
              </div>
            </button>
            <button tabindex="-1" data-menu-item="third">
              <div>  Third Item  </div>
            </button>
          </div>
        </div>
      </body>
    </html>
    |}];
  (* Press ArrowDown to activate first item *)
  Handle.press_key handle ~selector:(test_selector options_selector) ~code:ArrowDown;
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
            <div tabindex="0">
    -|        <button tabindex="-1" data-menu-item="first">
    +|        <button tabindex="-1" data-menu-item="first" data-test-is-active="true">
                <div>  First Item  </div>
              </button>
              <button tabindex="-1" data-menu-item="second" disabled="">
                <div>  Disabled Item  </div>
              </button>
              <button tabindex="-1" data-menu-item="submenu">
                <div>
                  <div> Submenu </div>
                  <icon-chevron_right size="16px"> </icon-chevron_right>
                </div>
              </button>
              <button tabindex="-1" data-menu-item="third">
                <div>  Third Item  </div>
              </button>
            </div>
          </div>
    |}];
  (* Press ArrowDown - should skip disabled item and go to submenu *)
  Handle.press_key handle ~selector:(test_selector options_selector) ~code:ArrowDown;
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
            <div tabindex="0">
    -|        <button tabindex="-1" data-menu-item="first" data-test-is-active="true">
    +|        <button tabindex="-1" data-menu-item="first">
                <div>  First Item  </div>
              </button>
              <button tabindex="-1" data-menu-item="second" disabled="">
                <div>  Disabled Item  </div>
              </button>
    -|        <button tabindex="-1" data-menu-item="submenu">
    +|        <button tabindex="-1" data-menu-item="submenu" data-test-is-active="true">
                <div>
                  <div> Submenu </div>
                  <icon-chevron_right size="16px"> </icon-chevron_right>
                </div>
              </button>
              <button tabindex="-1" data-menu-item="third">
                <div>  Third Item  </div>
              </button>
            </div>
          </div>
        </body>
    +|  <div>
    +|    <div popover="manual"
    +|         tabindex="-1"
    +|         data-bonsai-popover-356c4f74-f7b7-11ee-8823-aa63f6b8d3b4=""
    +|         mock-popover-state="open">
    +|      <div>
    +|        <div>
    +|          <button tabindex="-1" data-menu-item="sub-1">
    +|            <div>  Sub Item 1  </div>
    +|          </button>
    +|          <button tabindex="-1" data-menu-item="sub-2">
    +|            <div>  Sub Item 2  </div>
    +|          </button>
    +|        </div>
    +|      </div>
    +|      <div> </div>
    +|    </div>
    +|  </div>
      </html>
    |}];
  (* Press ArrowRight to open submenu *)
  Handle.press_key handle ~selector:(test_selector options_selector) ~code:ArrowRight;
  Handle.one_frame handle;
  Handle.print_dom_diff handle;
  [%expect
    {|
    === DIFF HUNK ===
                  <icon-chevron_right size="16px"> </icon-chevron_right>
                </div>
              </button>
              <button tabindex="-1" data-menu-item="third">
                <div>  Third Item  </div>
              </button>
            </div>
          </div>
        </body>
        <div>
          <div popover="manual"
               tabindex="-1"
               data-bonsai-popover-356c4f74-f7b7-11ee-8823-aa63f6b8d3b4=""
               mock-popover-state="open">
            <div>
              <div>
    -|          <button tabindex="-1" data-menu-item="sub-1">
    +|          <button tabindex="-1" data-menu-item="sub-1" data-test-is-active="true">
                  <div>  Sub Item 1  </div>
                </button>
                <button tabindex="-1" data-menu-item="sub-2">
                  <div>  Sub Item 2  </div>
                </button>
              </div>
            </div>
            <div> </div>
          </div>
        </div>
      </html>
    |}];
  (* Press ArrowDown to navigate to first sub-item *)
  Handle.press_key handle ~selector:(test_selector options_selector) ~code:ArrowDown;
  Handle.one_frame handle;
  Handle.print_dom_diff handle;
  [%expect
    {|
    === DIFF HUNK ===
                  <icon-chevron_right size="16px"> </icon-chevron_right>
                </div>
              </button>
              <button tabindex="-1" data-menu-item="third">
                <div>  Third Item  </div>
              </button>
            </div>
          </div>
        </body>
        <div>
          <div popover="manual"
               tabindex="-1"
               data-bonsai-popover-356c4f74-f7b7-11ee-8823-aa63f6b8d3b4=""
               mock-popover-state="open">
            <div>
              <div>
    -|          <button tabindex="-1" data-menu-item="sub-1" data-test-is-active="true">
    +|          <button tabindex="-1" data-menu-item="sub-1">
                  <div>  Sub Item 1  </div>
                </button>
    -|          <button tabindex="-1" data-menu-item="sub-2">
    +|          <button tabindex="-1" data-menu-item="sub-2" data-test-is-active="true">
                  <div>  Sub Item 2  </div>
                </button>
              </div>
            </div>
            <div> </div>
          </div>
        </div>
      </html>
    |}];
  (* Press ArrowDown to navigate to second sub-item *)
  Handle.press_key handle ~selector:(test_selector options_selector) ~code:ArrowDown;
  Handle.one_frame handle;
  Handle.print_dom_diff handle;
  [%expect
    {|
    === DIFF HUNK ===
                  <icon-chevron_right size="16px"> </icon-chevron_right>
                </div>
              </button>
              <button tabindex="-1" data-menu-item="third">
                <div>  Third Item  </div>
              </button>
            </div>
          </div>
        </body>
        <div>
          <div popover="manual"
               tabindex="-1"
               data-bonsai-popover-356c4f74-f7b7-11ee-8823-aa63f6b8d3b4=""
               mock-popover-state="open">
            <div>
              <div>
    -|          <button tabindex="-1" data-menu-item="sub-1">
    +|          <button tabindex="-1" data-menu-item="sub-1" data-test-is-active="true">
                  <div>  Sub Item 1  </div>
                </button>
    -|          <button tabindex="-1" data-menu-item="sub-2" data-test-is-active="true">
    +|          <button tabindex="-1" data-menu-item="sub-2">
                  <div>  Sub Item 2  </div>
                </button>
              </div>
            </div>
            <div> </div>
          </div>
        </div>
      </html>
    |}];
  (* Press ArrowLeft to go back to parent *)
  Handle.press_key handle ~selector:(test_selector options_selector) ~code:ArrowLeft;
  Handle.one_frame handle;
  Handle.print_dom_diff handle;
  [%expect
    {|
    === DIFF HUNK ===
                  <icon-chevron_right size="16px"> </icon-chevron_right>
                </div>
              </button>
              <button tabindex="-1" data-menu-item="third">
                <div>  Third Item  </div>
              </button>
            </div>
          </div>
        </body>
        <div>
          <div popover="manual"
               tabindex="-1"
               data-bonsai-popover-356c4f74-f7b7-11ee-8823-aa63f6b8d3b4=""
               mock-popover-state="open">
            <div>
              <div>
    -|          <button tabindex="-1" data-menu-item="sub-1" data-test-is-active="true">
    +|          <button tabindex="-1" data-menu-item="sub-1">
                  <div>  Sub Item 1  </div>
                </button>
                <button tabindex="-1" data-menu-item="sub-2">
                  <div>  Sub Item 2  </div>
                </button>
              </div>
            </div>
            <div> </div>
          </div>
        </div>
      </html>
    |}];
  (* Press ArrowDown to navigate to third item and close menu. *)
  Handle.press_key handle ~selector:(test_selector options_selector) ~code:ArrowDown;
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
            <div tabindex="0">
              <button tabindex="-1" data-menu-item="first">
                <div>  First Item  </div>
              </button>
              <button tabindex="-1" data-menu-item="second" disabled="">
                <div>  Disabled Item  </div>
              </button>
    -|        <button tabindex="-1" data-menu-item="submenu" data-test-is-active="true">
    +|        <button tabindex="-1" data-menu-item="submenu">
                <div>
                  <div> Submenu </div>
                  <icon-chevron_right size="16px"> </icon-chevron_right>
                </div>
              </button>
    -|        <button tabindex="-1" data-menu-item="third">
    +|        <button tabindex="-1" data-menu-item="third" data-test-is-active="true">
                <div>  Third Item  </div>
              </button>
            </div>
          </div>
        </body>
    -|  <div>
    -|    <div popover="manual"
    -|         tabindex="-1"
    -|         data-bonsai-popover-356c4f74-f7b7-11ee-8823-aa63f6b8d3b4=""
    -|         mock-popover-state="open">
    -|      <div>
    -|        <div>
    -|          <button tabindex="-1" data-menu-item="sub-1">
    -|            <div>  Sub Item 1  </div>
    -|          </button>
    -|          <button tabindex="-1" data-menu-item="sub-2">
    -|            <div>  Sub Item 2  </div>
    -|          </button>
    -|        </div>
    -|      </div>
    -|      <div> </div>
    -|    </div>
    -|  </div>
    +|  <div> </div>
      </html>
    |}];
  (* Press ArrowUp to go back to submenu *)
  Handle.press_key handle ~selector:(test_selector options_selector) ~code:ArrowUp;
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
            <div tabindex="0">
              <button tabindex="-1" data-menu-item="first">
                <div>  First Item  </div>
              </button>
              <button tabindex="-1" data-menu-item="second" disabled="">
                <div>  Disabled Item  </div>
              </button>
    -|        <button tabindex="-1" data-menu-item="submenu">
    +|        <button tabindex="-1" data-menu-item="submenu" data-test-is-active="true">
                <div>
                  <div> Submenu </div>
                  <icon-chevron_right size="16px"> </icon-chevron_right>
                </div>
              </button>
    -|        <button tabindex="-1" data-menu-item="third" data-test-is-active="true">
    +|        <button tabindex="-1" data-menu-item="third">
                <div>  Third Item  </div>
              </button>
            </div>
          </div>
        </body>
    -|  <div> </div>
    +|  <div>
    +|    <div popover="manual"
    +|         tabindex="-1"
    +|         data-bonsai-popover-356c4f74-f7b7-11ee-8823-aa63f6b8d3b4=""
    +|         mock-popover-state="open">
    +|      <div>
    +|        <div>
    +|          <button tabindex="-1" data-menu-item="sub-1">
    +|            <div>  Sub Item 1  </div>
    +|          </button>
    +|          <button tabindex="-1" data-menu-item="sub-2">
    +|            <div>  Sub Item 2  </div>
    +|          </button>
    +|        </div>
    +|      </div>
    +|      <div> </div>
    +|    </div>
    +|  </div>
      </html>
    |}];
  ()
;;

(* Test Enter key triggers on_click *)
let%expect_test "Enter key triggers active item's on_click" =
  let options_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.item
                ~key:%{"first"}
                ~on_click:%{Effect.print_s [%message "First item clicked"]}
              >
                First Item
              </>
              <Options.item
                ~key:%{"second"}
                ~on_click:%{Effect.print_s [%message "Second item clicked"]}
              >
                Second Item
              </>
            </>
          |}
      in
      let component =
        Options.Expert.component
          ~test_selector:(return options_selector)
          ~close:(return Effect.Ignore)
          options
          graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
  in
  (* Press ArrowDown to activate first item *)
  Handle.press_key handle ~selector:(test_selector options_selector) ~code:ArrowDown;
  Handle.one_frame handle;
  (* Press Enter to trigger on_click *)
  Handle.press_key handle ~selector:(test_selector options_selector) ~code:Enter;
  Handle.one_frame handle;
  [%expect {| "First item clicked" |}];
  ()
;;

(* Test Escape key triggers close effect *)
let%expect_test "Escape key triggers close effect" =
  let options_selector = Test_selector.make () in
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (graph @ local) ->
      let options =
        return
          {%html|
            <Options.create>
              <Options.item
                ~key:%{"item"}
                ~on_click:%{Effect.print_s [%message "Item clicked"]}
              >
                Item
              </>
            </>
          |}
      in
      let component =
        Options.Expert.component
          ~test_selector:(return options_selector)
          ~close:(return (Effect.print_s [%message "Close triggered"]))
          options
          graph
      in
      let%arr component in
      {%html|<div>%{component}</div>|})
  in
  (* Press Escape to trigger close *)
  Handle.press_key handle ~selector:(test_selector options_selector) ~code:Escape;
  Handle.one_frame handle;
  [%expect {| "Close triggered" |}];
  ()
;;
