open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
open Jsdom
module Handle = Handle_experimental

let%expect_test "Can update the text contents and have that reflected in the document" =
  let%with handle =
    Handle.with_ ~get_vdom:snd (fun graph ->
      let doc, set_doc = Bonsai.state "" graph in
      let%arr set_doc
      and vdom = Skyline_text_document_v1.component doc graph in
      set_doc, vdom)
  in
  let show ?new_text () =
    Option.iter new_text ~f:(fun new_text ->
      Handle.inject handle (fun (set_doc, _) -> set_doc new_text));
    Handle.one_frame handle;
    let editor = Handle.query_selector_exn handle ~selector:".cm-content" in
    editor##.outerHTML
    |> Js_of_ocaml.Js.to_string
    |> String.substr_replace_all ~pattern:"><" ~with_:">\n<"
    |> print_endline
  in
  (* Initially the editor is empty. *)
  show ();
  [%expect
    {|
    <div style="tab-size: 4;" spellcheck="false" autocorrect="off" autocapitalize="off" translate="no" contenteditable="false" class="cm-content" role="textbox" aria-multiline="true" aria-readonly="true">
    <div class="cm-line">
    <br>
    </div>
    </div>
    |}];
  (* We can update the contents from empty. *)
  show ~new_text:"Hello World!" ();
  [%expect
    {|
    <div style="tab-size: 4;" spellcheck="false" autocorrect="off" autocapitalize="off" translate="no" contenteditable="false" class="cm-content" role="textbox" aria-multiline="true" aria-readonly="true">
    <div class="cm-line">Hello World!</div>
    </div>
    |}];
  (* We can update the contents a second time as well. *)
  show ~new_text:"Hello Skyline?" ();
  [%expect
    {|
    <div style="tab-size: 4;" spellcheck="false" autocorrect="off" autocapitalize="off" translate="no" contenteditable="false" class="cm-content" role="textbox" aria-multiline="true" aria-readonly="true">
    <div class="cm-line">Hello Skyline?</div>
    </div>
    |}]
;;
