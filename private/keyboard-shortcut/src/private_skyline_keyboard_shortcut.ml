open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
include Bonsai_web_keyboard_shortcut

module Modifier_status = struct
  type t =
    | Idle
    | Show_indicator
  [@@deriving sexp_of]
end

module Modifier = struct
  type t =
    [ `Alt
    | `Ctrl
    | `Shift
    ]
  [@@deriving compare, equal, enumerate, sexp_of]

  let to_string : t -> string = function
    | `Alt -> "Alt"
    | `Ctrl -> "Ctrl"
    | `Shift -> "Shift"
  ;;

  include functor Comparable.Make_plain
end

module Key = struct
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

  let to_string = function
    | `A -> "A"
    | `B -> "B"
    | `C -> "C"
    | `D -> "D"
    | `E -> "E"
    | `F -> "F"
    | `G -> "G"
    | `H -> "H"
    | `I -> "I"
    | `J -> "J"
    | `K -> "K"
    | `L -> "L"
    | `M -> "M"
    | `N -> "N"
    | `O -> "O"
    | `P -> "P"
    | `Q -> "Q"
    | `R -> "R"
    | `S -> "S"
    | `T -> "T"
    | `U -> "U"
    | `V -> "V"
    | `W -> "W"
    | `X -> "X"
    | `Y -> "Y"
    | `Z -> "Z"
    | `Digit_1 -> "1"
    | `Digit_2 -> "2"
    | `Digit_3 -> "3"
    | `Digit_4 -> "4"
    | `Digit_5 -> "5"
    | `Digit_6 -> "6"
    | `Digit_7 -> "7"
    | `Digit_8 -> "8"
    | `Digit_9 -> "9"
    | `Digit_0 -> "0"
    | `Forward_slash -> "/"
    | `Period -> "."
    | `Arrow_up -> "\u{2191}"
    | `Arrow_down -> "\u{2193}"
    | `Arrow_left -> "\u{2190}"
    | `Arrow_right -> "\u{2192}"
    | `Backspace -> "Backspace"
    | `Enter -> "\u{21A9}"
    | `Esc -> "Esc"
    | `Space -> "Space"
  ;;

  let of_event_key = function
    | "A" -> `A
    | "B" -> `B
    | "C" -> `C
    | "D" -> `D
    | "E" -> `E
    | "F" -> `F
    | "G" -> `G
    | "H" -> `H
    | "I" -> `I
    | "J" -> `J
    | "K" -> `K
    | "L" -> `L
    | "M" -> `M
    | "N" -> `N
    | "O" -> `O
    | "P" -> `P
    | "Q" -> `Q
    | "R" -> `R
    | "S" -> `S
    | "T" -> `T
    | "U" -> `U
    | "V" -> `V
    | "W" -> `W
    | "X" -> `X
    | "Y" -> `Y
    | "Z" -> `Z
    | "1" -> `Digit_1
    | "2" -> `Digit_2
    | "3" -> `Digit_3
    | "4" -> `Digit_4
    | "5" -> `Digit_5
    | "6" -> `Digit_6
    | "7" -> `Digit_7
    | "8" -> `Digit_8
    | "9" -> `Digit_9
    | "0" -> `Digit_0
    | "/" -> `Forward_slash
    | "." -> `Period
    | "ARROWUP" -> `Arrow_up
    | "ARROWDOWN" -> `Arrow_down
    | "ARROWLEFT" -> `Arrow_left
    | "ARROWRIGHT" -> `Arrow_right
    | "BACKSPACE" -> `Backspace
    | "ENTER" -> `Enter
    | "ESCAPE" -> `Esc
    | " " -> `Space
    | _ -> `Unknown
  ;;

  let to_keystroke (t : t) ~(modifiers : Modifier.t list) =
    let alt = List.exists modifiers ~f:(Modifier.equal `Alt) in
    let ctrl = List.exists modifiers ~f:(Modifier.equal `Ctrl) in
    let shift = List.exists modifiers ~f:(Modifier.equal `Shift) in
    let meta = false in
    let key = Vdom_keyboard.Keystroke.create ~alt ~ctrl ~meta ~shift in
    match t with
    | `A -> key KeyA
    | `B -> key KeyB
    | `C -> key KeyC
    | `D -> key KeyD
    | `E -> key KeyE
    | `F -> key KeyF
    | `G -> key KeyG
    | `H -> key KeyH
    | `I -> key KeyI
    | `J -> key KeyJ
    | `K -> key KeyK
    | `L -> key KeyL
    | `M -> key KeyM
    | `N -> key KeyN
    | `O -> key KeyO
    | `P -> key KeyP
    | `Q -> key KeyQ
    | `R -> key KeyR
    | `S -> key KeyS
    | `T -> key KeyT
    | `U -> key KeyU
    | `V -> key KeyV
    | `W -> key KeyW
    | `X -> key KeyX
    | `Y -> key KeyY
    | `Z -> key KeyZ
    | `Digit_1 -> key Digit1
    | `Digit_2 -> key Digit2
    | `Digit_3 -> key Digit3
    | `Digit_4 -> key Digit4
    | `Digit_5 -> key Digit5
    | `Digit_6 -> key Digit6
    | `Digit_7 -> key Digit7
    | `Digit_8 -> key Digit8
    | `Digit_9 -> key Digit9
    | `Digit_0 -> key Digit0
    | `Forward_slash -> key Slash
    | `Period -> key Period
    | `Arrow_up -> key ArrowUp
    | `Arrow_down -> key ArrowDown
    | `Arrow_left -> key ArrowLeft
    | `Arrow_right -> key ArrowRight
    | `Backspace -> key Backspace
    | `Enter -> key Enter
    | `Esc -> key Escape
    | `Space -> key Space
  ;;

  include functor Comparable.Make_plain
end

let install_manual_listener component graph =
  let vdom, dispatch_byo = Expert.install_manual_listener component graph in
  let dispatch_keyboard_event =
    let%arr dispatch_byo in
    fun (modifiers, key) ->
      let keystroke = Key.to_keystroke key ~modifiers in
      dispatch_byo keystroke
  in
  dispatch_keyboard_event, vdom
;;

let install_listener ~mode inside (local_ graph) = install_listener ~mode inside graph

let register_shortcut ~effect ~modifier ~key (local_ graph) =
  let modifiers =
    let%arr modifier in
    match modifier with
    | `Any -> [ `Alt; `Ctrl; `Shift ]
    | `None -> []
    | #Modifier.t as modifier -> [ modifier ]
  in
  let keystroke =
    let%arr key and modifiers in
    Key.to_keystroke key ~modifiers
  in
  register keystroke ~effect graph;
  match%arr hint_status graph with
  | Hint_status.Hide -> Modifier_status.Idle
  | Show -> Show_indicator
;;
