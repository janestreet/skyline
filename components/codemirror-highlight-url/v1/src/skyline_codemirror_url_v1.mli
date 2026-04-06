open! Gen_js_api

(** [highlight ~regexp href_of_match] creates a Codemirror extension which turns regexp
    matches into URLs. *)
val highlight' : regexp:string -> (string -> string) -> Codemirror.State.Extension.t

val highlight : Codemirror.State.Extension.t Lazy.t

module For_testing : sig
  val regexp : string
  val href_of_match : string -> string
end
