open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Hook = struct
  module Input = struct
    type t =
      [ `Idle
      | `Focus
      | `Blur
      ]
    [@@deriving equal, sexp_of]

    let combine first second =
      match first, second with
      | `Idle, other | other, `Idle -> other
      | _ -> first
    ;;
  end

  module State = Unit

  let init (_ : Input.t) _ = ()
  let on_mount = `Do_nothing

  let update ~old_input ~new_input () elem =
    match old_input, new_input with
    | _, `Idle | `Focus, `Focus | `Blur, `Blur -> ()
    | `Idle, `Focus | `Blur, `Focus -> elem##focus
    | `Idle, `Blur | `Focus, `Blur -> elem##blur
  ;;

  let destroy (_ : Input.t) () _ = ()

  include functor Vdom.Attr.Hooks.Make

  let create input = Vdom.Attr.create_hook "skyline-manual-focus" (create input)
end

let component graph =
  let state, set_state = Bonsai.state `Idle graph in
  Bonsai.Edge.on_change
    ~trigger:`After_display
    state
    ~equal:Hook.Input.equal
    ~callback:
      (let%arr set_state in
       function
       | `Idle -> Effect.Ignore
       | `Focus | `Blur -> set_state `Idle)
    graph;
  let attr =
    let%arr state in
    Hook.create state
  in
  let actions =
    let%arr set_state in
    let focus = set_state `Focus in
    let blur = set_state `Blur in
    ~focus, ~blur
  in
  attr, actions
;;
