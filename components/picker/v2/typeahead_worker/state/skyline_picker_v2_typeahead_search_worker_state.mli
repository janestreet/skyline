open! Core
open Skyline_picker_v2_typeahead_search_worker_protocol

type t

val create : post_message:(From_worker.t -> unit) -> unit -> t
val handle_message : t -> To_worker.message -> unit
