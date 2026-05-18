open! Core
open! Bonsai_web

type t = ([ `Matching | `Not_matching ] * string) list

(** Splits [item] into matching and non-matching segments given a fuzzy [~needle]. *)
val of_string : needle:string -> string -> t

(** Converts a splits list into vdom, wrapping the [`Matching] strings in [<strong>]. *)
val view : ?attrs:Vdom.Attr.t list -> t -> Vdom.Node.t
