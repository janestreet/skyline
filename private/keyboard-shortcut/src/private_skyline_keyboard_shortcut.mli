open! Core
open! Bonsai_web

module Modifier_status : sig
  type t =
    | Idle
    | Show_indicator
  [@@deriving sexp_of]
end

module Modifier : sig
  type t =
    [ `Alt
    | `Ctrl
    | `Shift
    ]
  [@@deriving compare, equal, sexp_of]

  val to_string : t -> string
end

module Key : sig
  type t =
    [ `A
    | `B
    | `C
    | `D
    | `E
    | `F
    | `G
    | `H
    | `I
    | `J
    | `K
    | `L
    | `M
    | `N
    | `O
    | `P
    | `Q
    | `R
    | `S
    | `T
    | `U
    | `V
    | `W
    | `X
    | `Y
    | `Z
    | `Digit_1
    | `Digit_2
    | `Digit_3
    | `Digit_4
    | `Digit_5
    | `Digit_6
    | `Digit_7
    | `Digit_8
    | `Digit_9
    | `Digit_0
    | `Forward_slash
    | `Period
    | `Arrow_up
    | `Arrow_down
    | `Arrow_left
    | `Arrow_right
    | `Backspace
    | `Enter
    | `Esc
    | `Space
    ]
  [@@deriving compare, equal, sexp_of]

  val to_string : t -> string
  val of_event_key : string -> [ `Unknown | t ]
end

val install_listener
  :  mode:[ `Local | `Global ]
  -> (Bonsai.graph @ local -> Vdom.Node.t Bonsai.t)
  -> Bonsai.graph @ local
  -> Vdom.Node.t Bonsai.t

val install_manual_listener
  :  (Bonsai.graph @ local -> 'a Bonsai.t)
  -> Bonsai.graph @ local
  -> (Modifier.t list * Key.t -> unit Effect.t) Bonsai.t * 'a Bonsai.t

val register_shortcut
  :  effect:unit Effect.t Bonsai.t
  -> modifier:[ `Any | `None | Modifier.t ] Bonsai.t
  -> key:Key.t Bonsai.t
  -> local_ Bonsai.graph
  -> Modifier_status.t Bonsai.t
