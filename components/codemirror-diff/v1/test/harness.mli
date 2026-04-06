open! Core

val changes : ?context:int -> original:string -> string -> unit
val side_by_side : context:int option -> lhs:string -> rhs:string -> unit
