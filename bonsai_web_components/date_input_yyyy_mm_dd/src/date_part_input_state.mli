type t =
  { state : [ `Nothing_typed | `Something_typed ]
  ; value : string option
  ; format : string
  ; max_value : int
  }
[@@deriving sexp_of, to_string]

module Action : sig
  type t =
    | Focus
    | Reset_value
    | Set_value of string option
    | Increase_by_one
    | Decrease_by_one
    | Append_value of string
end

val create
  :  format:string
  -> max_value:int
  -> local_ Bonsai.graph
  -> t Bonsai.t * (Action.t -> string option Bonsai.Effect.t) Bonsai.t

module For_testing : sig
  val initial_state : format:string -> max_value:int -> t
  val apply_action : t -> Action.t -> t
end
