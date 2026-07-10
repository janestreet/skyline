open! Core
open! Js_of_ocaml

type t =
  | Search_complete of
      { generation : int
      ; indices : Indices.t
      }
[@@deriving sexp_of]

module Protocol = struct
  class type t = object
    method generation : int Js.readonly_prop
    method indices : Indices.t Js.readonly_prop
  end
end

type message = Protocol.t Js.t

let parse (data : message) =
  Search_complete { generation = data##.generation; indices = data##.indices }
;;

(* This is more efficient than just directly writing the entire message with bin_prot to a
   transferrable array buffer because it avoids copying the indices back to the ocaml heap *)
let serialize : t -> message Web_worker.With_transfer.Packed.t = function
  | Search_complete { generation; indices } ->
    let message : message =
      object%js (self)
        val generation = generation
        val indices = indices
      end
    in
    Packed { message; transfer = [| Indices.transferrable_buffer indices |] }
;;

let%expect_test "serialization roundtrip" =
  let module Q = struct
    type t =
      | Search_complete of
          { generation : int
          ; indices : int iarray
          }
    [@@deriving compare, equal, quickcheck, sexp_of]
  end
  in
  let to_transferrable : Q.t -> t = function
    | Search_complete { generation; indices } ->
      Search_complete { generation; indices = Indices.of_iarray indices }
  and of_transferrable : t -> Q.t = function
    | Search_complete { generation; indices } ->
      Search_complete { generation; indices = Indices.to_iarray indices ~f:Fn.id }
  in
  Quickcheck.test Q.quickcheck_generator ~f:(fun t ->
    let%tydi (Packed { message; _ }) = to_transferrable t |> serialize in
    [%test_result: Q.t] ~expect:t (message |> parse |> of_transferrable))
;;

let post_message t =
  t |> serialize |> Web_worker.With_transfer.Packed.post_message From_worker
;;
