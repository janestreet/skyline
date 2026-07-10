open! Core
open! Js_of_ocaml
include Transferrable_intf

let to_arraybuf m x = Binable.to_bigstring m x |> Typed_array.Bigstring.to_arrayBuffer
let of_arraybuf m x = x |> Typed_array.Bigstring.of_arrayBuffer |> Binable.of_bigstring m

module Of_binable (T : sig
    type t [@@deriving bin_io]
  end) : S with type t := T.t and type message = Typed_array.arrayBuffer Js.t = struct
  type message = Typed_array.arrayBuffer Js.t

  let parse = of_arraybuf (module T)

  let serialize t : message With_transfer.Packed.t =
    Packed (With_transfer.singleton (to_arraybuf (module T) t))
  ;;
end
