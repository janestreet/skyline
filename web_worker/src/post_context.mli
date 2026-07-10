open! Core

(** Describes a context in which a [postMessage] javascript method is available. *)

type -'message t =
  | From_worker
  (** [From_worker]: Equivalent of [Js_of_ocaml.Worker.post_message]

      @see < https://developer.mozilla.org/en-US/docs/Web/API/DedicatedWorkerGlobalScope/postMessage >
        the underlying Javascript method

        Using this context in any context other than a dedicated worker will raise a
        runtime exception.

      @see <
        https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API#worker_contexts >
        regarding types of web worker *)
  | To_worker : ('message, _) Js_of_ocaml.Worker.worker Js_of_ocaml.Js.t -> 'message t
  (** [To_worker worker]: Equivalent of [worker##postMessage]

      @see < https://developer.mozilla.org/en-US/docs/Web/API/Worker/postMessage > *)
