# Web_worker

`Web_worker` is a helper library for defining `js_of_ocaml` dedicated web workers
communicating using transferrable JavaScript objects (i.e. with minimal use of
structured cloning).

Briefly, it lets you define protocol libraries like

```
module Protocol : sig
  module From_worker = From_worker
  module Indices = Indices
  module Search_query = Search_query
  module To_worker = To_worker

  include
    Web_worker.S
    with type to_worker_message := To_worker.message
     and type to_worker_t := To_worker.t
     and type from_worker_t := From_worker.t
     and type from_worker_message := From_worker.message
end = struct
  module From_worker = From_worker
  module Indices = Indices
  module Search_query = Search_query
  module To_worker = To_worker
  include Web_worker.Make (From_worker) (To_worker)
end
```

where the `To_worker` or `From_worker` module might look something like
```
module Indices = struct
  type t = int Web_worker.Immediate_iarray.t [@@deriving sexp_of]

  let length : t -> _ = Web_worker.Immediate_iarray.length
  let unsafe_get : t -> _ = Web_worker.Immediate_iarray.unsafe_get
  let to_iarray : t -> _ = Web_worker.Immediate_iarray.to_iarray

  let of_iarray : int iarray @ local -> t =
    Web_worker.Transferrable.of_iarray
  ;;

  let transferrable_buffer : t -> _ =
    Web_worker.Transferrable.transferrable_buffer
  ;;
end

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
```

## Starting a worker from the client

Create a worker from either a script URL or an embedded JavaScript blob, then use
`To_worker.post_message` to send messages. The `on_message` callback receives
parsed `From_worker.t` values. For example, if `To_worker.t` has a `Search`
constructor:

```
let worker =
  Protocol.Worker.create
    ~script_url:(Js.string "/static/worker.js")
    ~on_message:(fun from_worker ->
      match from_worker with
      | Search_complete { generation; indices } ->
        printf
          "generation %d returned %d indices\n"
          generation
          (Protocol.Indices.length indices))
;;

let () =
  Protocol.To_worker.post_message (Search { generation = 1; query }) ~worker
;;
```

## Responding from the worker

Inside the dedicated worker implementation, parse incoming messages with the
protocol module and respond with `From_worker.post_message`.

```
let handle_raw_message message =
  match Protocol.To_worker.parse message with
  | Search { generation; query } ->
    let indices = search query |> Protocol.Indices.of_iarray in
    Protocol.From_worker.post_message (Search_complete { generation; indices })
;;
```

## Transferring ownership

Transferable objects must be included both in the posted message and in the
`transfer` array. Once the message is posted, the sending context no longer owns
those backing buffers, so treat transferred values as consumed.

```
let serialize_indices indices =
  let message = indices in
  let transfer = [| Protocol.Indices.transferrable_buffer indices |] in
  Web_worker.With_transfer.Packed (Web_worker.With_transfer.{ message; transfer })
;;
```
