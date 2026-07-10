open! Core
open! Js_of_ocaml

(** For this message type we can just treat the entire thing as binable, since the only
    large part of the message (the string array) has to be copied to the heap for use in
    [Worker_state.search_strings] anyway.

    To expand: Technically only the strings themselves need to be copied for individual
    scoring, but we also need random access to them. We could build a random access
    arraylike data structure that keeps the string bytes in a Typed_array.arraybuffer and
    the index-> offset mapping in a separate mapping like [Indices], but it would be
    unergonomic to use, and then every access into the structure would allocate a new copy
    of the string, and fixing that would require very intrusive changes to
    lib/fuzzy_search or forking the implementation. *)

module T = struct
  type t =
    { new_index : string iarray or_null
    ; query : string
    ; generation : int
    ; max_results : int or_null
    }
  [@@deriving bin_io, compare, equal, quickcheck, sexp_of]
end

include T
include Web_worker.Transferrable.Of_binable (T)

let%expect_test "serialization roundtrip" =
  Quickcheck.test quickcheck_generator ~f:(fun t ->
    match serialize t with
    | Packed { message; transfer = _ } -> [%test_result: t] ~expect:t (parse message))
;;

let post_message t ~worker =
  t |> serialize |> Web_worker.With_transfer.Packed.post_message (To_worker worker)
;;
