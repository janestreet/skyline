open! Core
open! Bonsai_web
open Jsdom
module Handle = Handle_experimental

let filter_printed_attributes ~key ~data:_ =
  not String.(key = "tabindex" || key = "style")
;;

let%expect_test "Can focus on mount on some element" =
  let%with handle =
    Handle.with_ ~get_vdom:fst ~filter_printed_attributes (fun graph ->
      let dom, set_dom = Bonsai.state Vdom.Node.none graph in
      Bonsai.both dom set_dom)
  in
  Handle.one_frame handle;
  Handle.print_dom handle;
  [%expect
    {|
    <html>
      <head>
        <meta charset="UTF-8"/>
      </head>
      <body> </body>
    </html>
    |}];
  Handle.print_active_element handle;
  [%expect {| <body> ... </body> |}];
  Handle.inject handle (fun (_, set_dom) ->
    set_dom
      (Vdom.Node.input
         ~attrs:[ Private_skyline_autofocus.focus_on_mount; Vdom.Attr.value "focus me!" ]
         ()));
  Handle.one_frame handle;
  Handle.print_dom handle;
  [%expect
    {|
    <html>
      <head>
        <meta charset="UTF-8"/>
      </head>
      <body>
        <input value="focus me!"/>
      </body>
    </html>
    |}];
  Handle.print_active_element handle;
  [%expect {| <input value="focus me!"/> |}]
;;
