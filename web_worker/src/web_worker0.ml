open! Core
include Web_worker0_intf

let blob_url ~embedded_javascript_blob : Js_of_ocaml.Js.js_string Js_of_ocaml.Js.t =
  Js_of_ocaml.Dom_html.window##._URL##createObjectURL
    (Js_of_ocaml.File.blob_from_string
       ~contentType:"application/javascript"
       embedded_javascript_blob)
;;

let create_event_handler ~prevent_default f =
  Js_of_ocaml.Dom_html.handler (fun event ->
    f event;
    (* Returning [_true] here means the default handler for this message still fires;
       [_false] prevents it. I suppose the intended interpretation is "Did this handler
       handle the event?" *)
    match prevent_default with
    | true -> Js_of_ocaml.Js._false
    | false -> Js_of_ocaml.Js._true)
;;

module Make (From_worker : Transferrable.S) (To_worker : Transferrable.S) = struct
  module Worker = struct
    type t = (To_worker.message, From_worker.message) Js_of_ocaml.Worker.worker

    let create_event_handler = create_event_handler

    let create_message_event_handler f =
      (* There's no meaningful default handler; these events are otherwise ignored. *)
      create_event_handler ~prevent_default:false (fun event ->
        f (From_worker.parse event##.data))
    ;;

    let create ~script_url ~on_message : t Js_of_ocaml.Js.t =
      let worker = script_url |> Js_of_ocaml.Js.to_string |> Js_of_ocaml.Worker.create in
      worker##.onmessage := create_message_event_handler on_message;
      worker
    ;;

    let create_from_blob ~embedded_javascript_blob ~on_message : t Js_of_ocaml.Js.t =
      create ~script_url:(blob_url ~embedded_javascript_blob) ~on_message
    ;;
  end
end
