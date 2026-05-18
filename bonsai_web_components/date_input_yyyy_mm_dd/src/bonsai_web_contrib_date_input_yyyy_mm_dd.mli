open! Core
open! Bonsai_web

module State : sig
  type t = private
    { value : Date.t option
    ; yyyy_part : Date_part_input_state.t
    ; yyyy_apply_action : Date_part_input_state.Action.t -> string option Effect.t
    ; yyyy_part_valid : bool
    ; mm_part : Date_part_input_state.t
    ; mm_apply_action : Date_part_input_state.Action.t -> string option Effect.t
    ; mm_part_valid : bool
    ; dd_part : Date_part_input_state.t
    ; dd_apply_action : Date_part_input_state.Action.t -> string option Effect.t
    ; dd_part_valid : bool
    ; focus_yyyy : unit Effect.t
    ; focus_mm : unit Effect.t
    ; focus_dd : unit Effect.t
    ; focus_attr_yyyy : Vdom.Attr.t
    ; focus_attr_mm : Vdom.Attr.t
    ; focus_attr_dd : Vdom.Attr.t
    ; set_value : Date.t option -> unit Effect.t
    ; hidden_date_input_id : string
    }

  val create
    :  ?state:Date.t option Bonsai.t * (Date.t option -> unit Effect.t) Bonsai.t
    -> local_ Bonsai.graph
    -> t Bonsai.t
end

module Content : sig
  type t
end

val view
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?disabled:bool
  -> state:State.t
  -> Content.t list
  -> Vdom.Node.t

val yyyy_part
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> unit
  -> Content.t

val mm_part
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> unit
  -> Content.t

val dd_part
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> unit
  -> Content.t

val delimiter
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?char:char
  -> unit
  -> Content.t

val calendar_icon
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> Vdom.Node.t list
  -> Content.t

module Date_part_input_state : sig
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

  module For_testing : sig
    val initial_state : format:string -> max_value:int -> t
    val apply_action : t -> Action.t -> t
  end
end
