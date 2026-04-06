open! Core
open! Bonsai_web
open Jsdom
module Handle = Handle_experimental

let filter_printed_attributes ~key ~data:_ =
  not String.(key = "tabindex" || key = "style")
;;

let%expect_test "Can manually focus / blur an element in the DOM" =
  let%with handle =
    Handle.with_ ~get_vdom:snd ~filter_printed_attributes (fun graph ->
      let open Bonsai.Let_syntax in
      let attr, actions = Private_skyline_manual_focus.component graph in
      let view =
        let%arr attr in
        {%html|<div><button %{attr}>I can be focused!</button></div>|}
      in
      Bonsai.both actions view)
  in
  Handle.one_frame handle;
  Handle.print_active_element handle;
  [%expect {| <div> ... </div> |}];
  Handle.inject handle (fun ((~focus, ..), _) -> focus);
  Handle.one_frame handle;
  Handle.print_active_element handle;
  [%expect {| <button> ... </button> |}];
  Handle.inject handle (fun ((~blur, ..), _) -> blur);
  Handle.one_frame handle;
  Handle.print_active_element handle;
  [%expect {| <div> ... </div> |}]
;;

let%expect_test "Can blur any element if attached to multiple nodes" =
  let%with handle =
    Handle.with_ ~get_vdom:snd ~filter_printed_attributes (fun graph ->
      let open Bonsai.Let_syntax in
      let attr, actions = Private_skyline_manual_focus.component graph in
      let view =
        let%arr attr in
        Vdom.Node.div
          [ Vdom.Node.button
              ~attrs:[ Vdom.Attr.id "first"; attr ]
              [ Vdom.Node.text "First element" ]
          ; Vdom.Node.button
              ~attrs:[ Vdom.Attr.id "second"; attr ]
              [ Vdom.Node.text "Second element" ]
          ]
      in
      Bonsai.both actions view)
  in
  Handle.one_frame handle;
  Handle.print_active_element handle;
  [%expect {| <div> ... </div> |}];
  (* Focus and blur the first element. *)
  Handle.focus handle ~selector:"#first";
  Handle.print_active_element handle;
  [%expect {| <button id="first"> ... </button> |}];
  Handle.inject handle (fun ((~blur, ..), _) -> blur);
  (* State resets to idle after each frame via an onchange, so we need 2 frames. *)
  Handle.one_frame handle;
  Handle.one_frame handle;
  Handle.print_active_element handle;
  [%expect {| <div> ... </div> |}];
  (* Focus and blur the second element. *)
  Handle.focus handle ~selector:"#second";
  Handle.print_active_element handle;
  [%expect {| <button id="second"> ... </button> |}];
  Handle.inject handle (fun ((~blur, ..), _) -> blur);
  Handle.one_frame handle;
  Handle.print_active_element handle;
  [%expect {| <div> ... </div> |}]
;;

let%expect_test "Test race coditions: Focus followed by immediate blur" =
  let%with handle =
    Handle.with_ ~get_vdom:snd ~filter_printed_attributes (fun graph ->
      let open Bonsai.Let_syntax in
      let attr, actions = Private_skyline_manual_focus.component graph in
      let view =
        let%arr attr in
        {%html|<div><button %{attr}>I can be focused!</button></div>|}
      in
      Bonsai.both actions view)
  in
  Handle.one_frame handle;
  Handle.print_active_element handle;
  [%expect {| <div> ... </div> |}];
  Handle.inject handle (fun ((~focus, ~blur), _) ->
    let%bind.Effect () = focus in
    blur);
  Handle.one_frame handle;
  Handle.print_active_element handle;
  [%expect {| <div> ... </div> |}]
;;

let%expect_test "Test race coditions: Blur followed by immediate focus" =
  let%with handle =
    Handle.with_ ~get_vdom:snd ~filter_printed_attributes (fun graph ->
      let open Bonsai.Let_syntax in
      let attr, actions = Private_skyline_manual_focus.component graph in
      let view =
        let%arr attr in
        {%html|<div><button %{attr}>I can be focused!</button></div>|}
      in
      Bonsai.both actions view)
  in
  Handle.one_frame handle;
  Handle.print_active_element handle;
  [%expect {| <div> ... </div> |}];
  Handle.inject handle (fun ((~focus, ~blur), _) ->
    let%bind.Effect () = blur in
    focus);
  Handle.one_frame handle;
  Handle.print_active_element handle;
  [%expect {| <button> ... </button> |}]
;;
