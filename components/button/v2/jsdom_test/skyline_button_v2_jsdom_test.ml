open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
open! Jsdom
open Async_kernel
open Async_js_test
module Handle = Handle_experimental
module Button = Skyline_button_v2

let filter_printed_attributes ~key ~data:_ =
  not String.(key = "tabindex" || key = "style" || key = "class")
;;

let button_test_selector = Test_selector.make ()

module%test [@name "Loading_while_effect_in_progress"] _ = struct
  (** Helper to create an async effect that can be completed on demand *)
  let async_effect ~on_start ~on_complete =
    let ivar = Ivar.create () in
    let effect =
      let%bind.Effect () = Effect.print_s [%message on_start] in
      let%bind.Effect () = Effect.of_deferred_fun (fun () -> Ivar.read ivar) () in
      Effect.print_s [%message on_complete]
    in
    ivar, effect
  ;;

  (** Helper to create a test handle with a button *)
  let create_handle ?(disabled = false) ?(loading = Button.Loading.No) ~on_click =
    Handle.with_async
      ~get_vdom:Fn.id
      ~filter_printed_attributes
      (Button.component
         ~test_selector:(Bonsai.return button_test_selector)
         ~disabled:(Bonsai.return disabled)
         ~loading:(Bonsai.return loading)
         ~intent:(Bonsai.return `Primary)
         ~on_click:(Bonsai.return on_click)
         (Bonsai.return [ Vdom.Node.text "Click me" ]))
  ;;

  (** Helper to click the button *)
  let click_button handle =
    Handle.click_on
      handle
      ~selector:(Test_selector.For_bonsai_web.css_selector button_test_selector);
    Handle.one_frame handle
  ;;

  (** Helper to complete an async effect and wait for it to finish *)
  let complete_effect_and_wait ivar =
    Ivar.fill_exn ivar ();
    Async_kernel_scheduler.yield_until_no_jobs_remain ()
  ;;

  let%expect_test "Button transitions to loading state when clicked and returns to idle \
                   when effect completes"
    =
    let ivar, on_click =
      async_effect ~on_start:"Effect started" ~on_complete:"Effect completed"
    in
    let%with handle = create_handle ~loading:While_effect_in_progress ~on_click in
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <button data-skyline-component="button"> Click me </button>
        </body>
      </html>
      |}];
    click_button handle;
    Handle.print_dom handle;
    [%expect
      {|
      "Effect started"
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <button data-skyline-component="button" disabled="" aria-disabled="true"> Loading... </button>
        </body>
      </html>
      |}];
    let%bind () = complete_effect_and_wait ivar in
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      "Effect completed"
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <button data-skyline-component="button"> Click me </button>
        </body>
      </html>
      |}];
    Deferred.return ()
  ;;

  let%expect_test "Button stays in loading state during multiple sequential effects" =
    let ivar = Ivar.create () in
    let on_click =
      let%bind.Effect () = Effect.print_s [%message "Effect 1 started"] in
      let%bind.Effect () = Effect.of_deferred_fun (fun () -> Ivar.read ivar) () in
      let%bind.Effect () = Effect.print_s [%message "Effect 1 completed"] in
      let%bind.Effect () = Effect.print_s [%message "Effect 2 started"] in
      Effect.print_s [%message "Effect 2 completed"]
    in
    let%with handle = create_handle ~loading:While_effect_in_progress ~on_click in
    Handle.one_frame handle;
    click_button handle;
    Handle.print_dom handle;
    [%expect
      {|
      "Effect 1 started"
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <button data-skyline-component="button" disabled="" aria-disabled="true"> Loading... </button>
        </body>
      </html>
      |}];
    let%bind () = complete_effect_and_wait ivar in
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      "Effect 1 completed"
      "Effect 2 started"
      "Effect 2 completed"
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <button data-skyline-component="button"> Click me </button>
        </body>
      </html>
      |}];
    Deferred.return ()
  ;;

  let%expect_test "Button disabled while loading prevents additional clicks" =
    let ivar, on_click =
      async_effect ~on_start:"Effect started" ~on_complete:"Effect completed"
    in
    let%with handle = create_handle ~loading:While_effect_in_progress ~on_click in
    Handle.one_frame handle;
    click_button handle;
    Handle.print_dom handle;
    [%expect
      {|
      "Effect started"
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <button data-skyline-component="button" disabled="" aria-disabled="true"> Loading... </button>
        </body>
      </html>
      |}];
    (* Try to click again while loading *)
    click_button handle;
    Handle.print_dom handle;
    [%expect
      {|
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <button data-skyline-component="button" disabled="" aria-disabled="true"> Loading... </button>
        </body>
      </html>
      |}];
    let%bind () = complete_effect_and_wait ivar in
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      "Effect completed"
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <button data-skyline-component="button"> Click me </button>
        </body>
      </html>
      |}];
    Deferred.return ()
  ;;

  let%expect_test "Loading mode Yes always shows loading state" =
    let%with handle =
      create_handle ~loading:Yes ~on_click:(Effect.print_s [%message "Clicked"])
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
          <button disabled="" aria-disabled="true" data-skyline-component="button"> Loading... </button>
        </body>
      </html>
      |}];
    Deferred.return ()
  ;;

  let%expect_test "Loading mode No never shows loading state" =
    let ivar, on_click =
      async_effect ~on_start:"Effect started" ~on_complete:"Effect completed"
    in
    let%with handle = create_handle ~loading:No ~on_click in
    Handle.one_frame handle;
    click_button handle;
    Handle.print_dom handle;
    [%expect
      {|
      "Effect started"
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <button data-skyline-component="button"> Click me </button>
        </body>
      </html>
      |}];
    let%bind () = complete_effect_and_wait ivar in
    Handle.one_frame handle;
    Handle.print_dom handle;
    [%expect
      {|
      "Effect completed"
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <button data-skyline-component="button"> Click me </button>
        </body>
      </html>
      |}];
    Deferred.return ()
  ;;

  let%expect_test "Effect that completes synchronously doesn't show loading state" =
    let%with handle =
      create_handle
        ~loading:While_effect_in_progress
        ~on_click:(Effect.print_s [%message "Sync effect"])
    in
    Handle.one_frame handle;
    click_button handle;
    Handle.print_dom handle;
    [%expect
      {|
      "Sync effect"
      <html>
        <head>
          <meta charset="UTF-8"/>
        </head>
        <body>
          <button data-skyline-component="button"> Click me </button>
        </body>
      </html>
      |}];
    Deferred.return ()
  ;;
end
