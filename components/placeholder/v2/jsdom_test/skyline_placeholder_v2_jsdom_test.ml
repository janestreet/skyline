open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
open! Jsdom
module Handle = Handle_experimental

let filter_printed_attributes ~key ~data:_ =
  not String.(key = "tabindex" || key = "style" || key = "class")
;;

let%expect_test "renders with required title and message" =
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun _graph ->
      Bonsai.return
        {%html|
          <Skyline_placeholder_v2.view
            ~title:%{"No results"}
            ~message:(<>Try again later</>)
          >
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
        <div data-skyline-component="placeholder">
          <div>
            <span> No results </span>
            <span data-skyline-component="text"> Try again later </span>
          </div>
        </div>
      </body>
    </html>
    |}]
;;

let%expect_test "renders with icon and actions" =
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun _graph ->
      Bonsai.return
        {%html|
          <Skyline_placeholder_v2.view
            ~icon:%{Lucide.triangle_alert}
            ~title:%{"Error"}
            ~message:(<>Could not load data</>)
          >
            <button on_click=%{fun _ -> Effect.Ignore}>Retry</button>
            <button on_click=%{fun _ -> Effect.Ignore}>Go back</button>
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
        <div data-skyline-component="placeholder">
          <icon-triangle_alert size="56px" stroke-width="1px"> </icon-triangle_alert>
          <div>
            <span> Error </span>
            <span data-skyline-component="text"> Could not load data </span>
          </div>
          <div>
            <button> Retry </button>
            <button> Go back </button>
          </div>
        </div>
      </body>
    </html>
    |}]
;;
