open! Core

module type Worker_state = sig
  type t
  type to_worker

  val create : unit -> t
  val handle_message : t -> to_worker -> unit
end

module type S = sig
  type to_worker_t
  type to_worker_message
  type from_worker_t
  type from_worker_message

  module Worker : sig
    type t = (to_worker_message, from_worker_message) Js_of_ocaml.Worker.worker

    val create_from_blob
      :  embedded_javascript_blob:string
      -> on_message:(from_worker_t -> unit)
      -> t Js_of_ocaml.Js.t

    val create
      :  script_url:Js_of_ocaml.Js.js_string Js_of_ocaml.Js.t
      -> on_message:(from_worker_t -> unit)
      -> t Js_of_ocaml.Js.t

    (** Convenience helper to create client-side handlers for [worker##.onerror] and
        [worker##.onmessage]. *)
    val create_event_handler
      :  prevent_default:bool
      -> ((#Js_of_ocaml.Dom_html.event as 'a) Js_of_ocaml.Js.t -> unit)
      -> (t Js_of_ocaml.Js.t, 'a Js_of_ocaml.Js.t) Js_of_ocaml.Dom.event_listener

    (** Convenience helper to create client-side handlers for [worker##.onmessage]. *)
    val create_message_event_handler
      :  (from_worker_t -> unit)
      -> ( t Js_of_ocaml.Js.t
           , from_worker_message #Js_of_ocaml.Worker.messageEvent Js_of_ocaml.Js.t )
           Js_of_ocaml.Dom.event_listener
  end
end

module type Web_worker0 = sig
  module type S = S
  module type Worker_state = Worker_state

  val blob_url
    :  embedded_javascript_blob:string
    -> Js_of_ocaml.Js.js_string Js_of_ocaml.Js.t

  module Make
      (From_worker : Transferrable.From_worker)
      (To_worker : Transferrable.To_worker with type 'a response := From_worker.message) :
    S
    with type to_worker_t := To_worker.t
     and type to_worker_message := To_worker.message
     and type from_worker_t := From_worker.t
     and type from_worker_message := From_worker.message
end
