open! Core
open Bonsai.Let_syntax
open Bonsai_web

module Kind = struct
  type t =
    | Local_storage
    | Session_storage
  [@@deriving compare, sexp_of]
end

let print_deserialization_error ~exn ~unique_id ~here =
  eprint_s
    [%message
      "WARNING: Could not deserialize value from storage"
        ~location:(here : Source_code_position.t)
        (unique_id : string)
        ~_:(exn : Exn.t)]
;;

let print_shared_item_error ~key ~here =
  eprint_s
    [%message
      "WARNING: It looks like you are using [Bonsai_web_browser_storage.item] multiple \
       times without setting up a shared Bonsai scope. Updates to your item will not be \
       correctly synced. Try wrapping your app with \
       [Bonsai_web_browser_storage.with_storage]."
        ~location:(here : Source_code_position.t)
        (key : Sexp.t)]
;;

let try_parse_sexp ~here ~unique_id sexp =
  try Some (Sexp.of_string sexp) with
  | exn ->
    print_deserialization_error ~exn ~unique_id ~here;
    None
;;

let try_parse_m (type a) ~here ~unique_id (module M : Sexpable with type t = a) sexp =
  try Some (M.t_of_sexp sexp) with
  | exn ->
    print_deserialization_error ~exn ~unique_id ~here;
    None
;;

module Storage = struct
  open Js_of_ocaml

  type t = Dom_html.storage Js.t option

  let of_kind : Kind.t -> t =
    let open Js_of_ocaml in
    function
    | Kind.Local_storage -> Dom_html.window##.localStorage |> Js.Optdef.to_option
    | Session_storage -> Dom_html.window##.sessionStorage |> Js.Optdef.to_option
  ;;

  let reader (type a) ~(here : [%call_pos]) (module M : Sexpable with type t = a)
    : t -> string -> a option
    =
    let open Js_of_ocaml in
    function
    | Some storage ->
      fun unique_id ->
        storage##getItem (Js.string unique_id)
        |> Js.Opt.to_option
        |> Option.map ~f:Js.to_string
        |> Option.bind ~f:(try_parse_sexp ~here ~unique_id)
        |> Option.bind ~f:(try_parse_m ~here ~unique_id (module M))
    | None -> fun _ -> None
  ;;

  let writer (type a) (module M : Sexpable with type t = a) =
    let open Js_of_ocaml in
    function
    | Some storage ->
      fun unique_id value ->
        let sexp = Sexp.to_string (M.sexp_of_t value) in
        storage##setItem (Js.string unique_id) (Js.string sexp)
    | None -> fun _ _ -> ()
  ;;
end

module type S = sig
  type t [@@deriving sexp, equal]
end

let listen_for_events ~storage ~unique_id ~on_event ~here (local_ graph) =
  let open Js_of_ocaml in
  let matches_storage =
    let%arr storage in
    fun other_storage ->
      Option.map storage ~f:(Js.equals other_storage) |> Option.value ~default:false
  in
  let handler =
    let%arr unique_id and matches_storage and on_event in
    let matches_key other_key = Js.to_string other_key |> String.equal unique_id in
    let f evt =
      (match matches_storage evt##.storageArea, matches_key evt##.key with
       | true, true ->
         (match try_parse_sexp ~here ~unique_id (Js.to_string evt##.newValue) with
          | Some parsed_m ->
            Effect.Expert.handle evt (on_event parsed_m) ~on_exn:(fun exn ->
              Exn.reraise exn "Unhandled exception raised in effect")
          | None -> ())
       | _ -> ());
      Js.bool true
    in
    Dom.handler f
  in
  let event_listener_id, set_event_listener_id = Bonsai.state_opt graph in
  let add_event_listener =
    let%arr handler and set_event_listener_id in
    let%bind.Effect event_listener_id =
      Effect.of_thunk (fun () ->
        (* NB: this is only triggered by writes from _other_ tabs:
           https://developer.mozilla.org/en-US/docs/Web/API/Window/storage_event *)
        Dom_html.addEventListener
          Dom_html.window
          (Dom_html.Event.make "storage")
          handler
          Js._true)
    in
    set_event_listener_id (Some event_listener_id)
  in
  let remove_event_listener =
    let%arr event_listener_id and set_event_listener_id in
    match event_listener_id with
    | None -> Effect.Ignore
    | Some id ->
      Effect.Many
        [ set_event_listener_id None
        ; Effect.of_thunk (fun () -> Dom_html.removeEventListener id)
        ]
  in
  Bonsai.Edge.lifecycle
    ~here
    ~on_activate:add_event_listener
    ~on_deactivate:remove_event_listener
    graph
;;

let updated_value ~(here : [%call_pos]) input (local_ graph)
  : (Sexp.t option * (Sexp.t -> unit Effect.t)) Bonsai.t
  =
  let%sub ~unique_id, ~kind = input in
  let write_to_storage =
    let%arr kind in
    Storage.of_kind kind |> Storage.writer (module Sexp)
  in
  let value, set_value = Bonsai.state_opt graph in
  let ( (* Set up "storage" event listeners *) ) =
    let storage =
      let%arr kind in
      Storage.of_kind kind
    in
    let on_event =
      let%arr set_value in
      fun m -> set_value (Some m)
    in
    listen_for_events ~here ~storage ~unique_id ~on_event graph
  in
  let set_value =
    let write_to_storage =
      let%arr unique_id and write_to_storage in
      Effect.of_sync_fun (fun value -> write_to_storage unique_id value)
    in
    let%arr write_to_storage and set_value in
    fun value -> Effect.Many [ write_to_storage value; set_value (Some value) ]
  in
  Bonsai.both value set_value
;;

module Memo = struct
  module Input = struct
    type t = unique_id:string * kind:Kind.t [@@deriving compare, sexp_of]

    include functor Comparable.Make_plain
  end

  type result = Sexp.t option * (Sexp.t -> unit Effect.t)

  type t =
    | Present of (Input.t, result) Bonsai.Memo.t
    | Missing

  let shared_storage_dyn_scope =
    Bonsai.Dynamic_scope.create ~name:"shared_storage" ~fallback:Missing ()
  ;;

  let create (local_ graph) = Bonsai.Memo.create (module Input) ~f:updated_value graph

  (** Util that keeps a frequency map and warns when any key has a frequency >1. *)
  module Missing_warning = struct
    let state = ref Sexp.Map.empty
    let lookup key = Map.find !state key |> Option.value ~default:0

    let increment_and_warn ~here key =
      state
      := match lookup key with
         | 0 -> Map.set !state ~key ~data:1
         | n ->
           print_shared_item_error ~key ~here;
           Map.set !state ~key ~data:(n + 1)
    ;;

    let decrement key =
      state
      := match lookup key with
         | 1 -> Map.remove !state key
         | n -> Map.set !state ~key ~data:(n - 1)
    ;;

    let track_usages_and_warn ~here key graph =
      let on_activate =
        let%arr key in
        Effect.of_thunk (fun () -> increment_and_warn ~here key)
      in
      let on_deactivate =
        let%arr key in
        Effect.of_thunk (fun () -> decrement key)
      in
      Bonsai.Edge.lifecycle ~here ~on_activate ~on_deactivate graph
    ;;
  end
end

let with_storage ~f:inside (local_ graph) =
  let memo = Memo.create graph in
  Bonsai.Dynamic_scope.set
    Memo.shared_storage_dyn_scope
    (let%arr memo in
     Memo.Present memo)
    ~inside
    graph
;;

let item
  (type a)
  ~(here : [%call_pos])
  (module M : S with type t = a)
  ?(kind = Kind.Local_storage)
  ~unique_id
  (local_ graph)
  =
  let%sub updated_value, set_updated_value =
    let input =
      let%arr unique_id in
      ~unique_id, ~kind
    in
    match%sub Bonsai.Dynamic_scope.lookup Memo.shared_storage_dyn_scope graph with
    | Missing ->
      (* If the caller didn't use [with_storage], fall back to [Bonsai.scope_model] to get
         the same per-input lifecycle behavior *)
      let for_each_input (local_ graph) =
        (* Warn the user if they've got multiple [item] attempting to read the same key.
           If they are, writes will be unsynchronized. [with_storage] fixes that. *)
        Memo.Missing_warning.track_usages_and_warn
          ~here
          (Bonsai.map input ~f:Memo.Input.sexp_of_t)
          graph;
        updated_value ~here input graph
      in
      Bonsai.scope_model (module Memo.Input) ~on:input ~for_:for_each_input graph
    | Present memo ->
      (match%sub Bonsai.Memo.lookup memo input graph with
       | None ->
         (* NB: in practice the user won't see a brief flash of None here, because this
            value is only useful after the first write has happened. Before the first
            write, we just return [initial_value_from_storage]. *)
         Bonsai.return (None, fun _ -> Effect.Ignore)
       | Some result -> result)
  in
  let initial_value_from_storage : Sexp.t option Bonsai.t =
    let read_from_storage = Storage.of_kind kind |> Storage.reader ~here (module Sexp) in
    let%arr unique_id in
    read_from_storage unique_id
  in
  let value =
    let sexp =
      match%sub updated_value with
      | None -> initial_value_from_storage
      | Some _ as v -> v
    in
    let%arr sexp and unique_id in
    Option.bind sexp ~f:(fun sexp ->
      try Some (M.t_of_sexp sexp) with
      | exn ->
        print_deserialization_error ~exn ~unique_id ~here;
        None)
  in
  let set_updated_value =
    let%arr set_updated_value in
    fun value -> set_updated_value (M.sexp_of_t value)
  in
  value, set_updated_value
;;

module Raw = struct
  let handle
    (type a)
    ~(here : [%call_pos])
    ?(kind = Kind.Local_storage)
    (module M : Sexpable with type t = a)
    =
    let storage = Storage.of_kind kind in
    let read_from_storage = Storage.reader ~here (module M) storage in
    let write_to_storage = Storage.writer (module M) storage in
    ~read_from_storage, ~write_to_storage
  ;;
end
