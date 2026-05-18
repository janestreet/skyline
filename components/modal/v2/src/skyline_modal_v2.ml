open! Core
open! Private_skyline_prelude

let close_on_click_outside_toplayer close_on_click_outside =
  let%arr close_on_click_outside in
  if close_on_click_outside
  then
    (* Any popovers below the modal are inert and unclickable, so if a popover can be
       clicked, it is on top of the modal, and probably shouldn't cause the modal to
       close. *)
    Bonsai_web_toplayer.Close_on_click_outside.Yes_unless_target_is_popover
  else No
;;

let always_open
  ?(close_on_click_outside = return false)
  ?(close_on_esc = return true)
  ?(attrs = return [])
  content
  ~close
  (local_ graph)
  =
  let close_on_click_outside = close_on_click_outside_toplayer close_on_click_outside in
  let autoclose =
    Bonsai_web_toplayer.Autoclose.create
      ~close_on_click_outside
      ~close_on_esc
      ~close
      graph
  in
  let attrs =
    let%arr attrs in
    [%css
      {|
        margin: auto;
        border: none;
        max-width: 90%;
        max-height: 95%;
        background-color: transparent;
        &::backdrop {
          background-color: rgba(0, 0, 0, .4);
        }
        &:focus-visible, &.for-testing--force-focus-visible {
          outline: none;
          & > div > [role="dialog"], & > div > dialog {
            outline: auto;
          }
        }
      |}]
    :: Classes.data_skyline_component "modal"
    :: attrs
  in
  Bonsai_web_toplayer.Modal.always_open
    ~attrs
    ~autoclose
    ~overflow_auto_wrapper:(return false)
    ~content
    graph
;;

let component ?close_on_click_outside ?close_on_esc ?attrs ?state content (local_ graph) =
  let state = Option.value_or_thunk state ~default:(fun () -> Bonsai.state false graph) in
  let is_open, set_is_open = state in
  let%sub () =
    if%sub is_open
    then (
      let close =
        let%arr set_is_open in
        set_is_open false
      in
      always_open
        ?close_on_click_outside
        ?close_on_esc
        ?attrs
        (content ~close)
        ~close
        graph;
      Bonsai.return ())
    else Bonsai.return ()
  in
  let%arr set_is_open in
  set_is_open true
;;

let effect ?close_on_click_outside ?close_on_esc ?attrs content graph =
  let state, action =
    Bonsai.actor
      ~default_model:Fqueue.empty
      ~recv:(fun _ model action ->
        match action with
        | `Open input ->
          let ivar = Async_kernel.Ivar.create () in
          Fqueue.enqueue model (~input, ~ivar), Some ivar
        | `Resolve resolution ->
          (match Fqueue.dequeue model with
           | None -> Fqueue.empty, None
           | Some ((~input:_, ~ivar), tl) ->
             Async_kernel.Ivar.fill_exn ivar resolution;
             tl, None))
      graph
  in
  let input =
    let%arr state in
    let%map.Option ~input, ~ivar:_ = Fqueue.peek state in
    input
  in
  let resolve =
    let%arr action in
    fun a -> action (`Resolve (Some a)) |> Effect.ignore_m
  in
  let close =
    let%arr action in
    action (`Resolve None) |> Effect.ignore_m
  in
  let%sub () =
    match%sub input with
    | None -> Bonsai.return ()
    | Some input ->
      always_open
        ?close_on_click_outside
        ?close_on_esc
        ?attrs
        (content input ~close ~resolve)
        ~close
        graph;
      Bonsai.return ()
  in
  let%arr action in
  fun input ->
    match%bind.Effect action (`Open input) with
    | Some ivar -> Effect.of_deferred_fun Async_kernel.Ivar.read ivar
    | None -> Effect.return None
;;

module Deprecated = struct
  let always_open = always_open
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
