open! Core
module Incr : Incremental.S

module Nonempty_string_list : sig
  type t = string Nonempty_list.t [@@deriving quickcheck, sexp, compare, hash]

  include Comparable.S with type t := t
end

type t =
  { path : Nonempty_string_list.t
  ; review : int
  }
[@@deriving quickcheck, sexp, compare]

val nonincremental : t Core.Map.M(Nonempty_string_list).t -> t list
val of_list : t list -> t Map.M(Nonempty_string_list).t
