open! Core
open Bonsai_web

(** The [bonsai_web_browser_storage] provides APIs for backing up OCaml data into the
    browser's localStorage or sessionStorage

    https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage
    https://developer.mozilla.org/en-US/docs/Web/API/Window/sessionStorage

    Note that local storage only allots 5MB/domain, so you must be careful about how much
    data you store. *)

module Kind : sig
  type t =
    | Local_storage
    | Session_storage
end

module type S = sig
  type t [@@deriving sexp, equal]
end

(** A value from browser storage. Setting the value will also update it in storage, as
    well as in any other tabs with an [item] having the same unique_id.

    The returned ['m option Bonsai.t] will update with explicit writes and also via the
    browser "storage" event. Note that you can access the same data from multiple calls to
    [item]; just make sure you use the same [of_sexp]/[sexp_of] functions!

    State is not synced between local and session storage; you must choose which to use. *)
val item
  :  here:[%call_pos]
  -> (module S with type t = 'm)
  -> ?kind:Kind.t
  -> unique_id:string Bonsai.t
  -> local_ Bonsai.graph
  -> 'm option Bonsai.t * ('m -> unit Effect.t) Bonsai.t

(** You should wrap your top-level computation in [with_storage] so that multiple calls to
    [item] with the same [unique_id] and [kind] share state. *)
val with_storage
  :  f:(local_ Bonsai.graph -> 'a Bonsai.t)
  -> local_ Bonsai.graph
  -> 'a Bonsai.t

module Raw : sig
  (** Wrapper around [localStorage] and [sessionStorage] that allows imperative
      reading/writing. *)
  val handle
    :  here:[%call_pos]
    -> ?kind:Kind.t
    -> (module Sexpable with type t = 'm)
    -> read_from_storage:(string -> 'm option) * write_to_storage:(string -> 'm -> unit)
end
