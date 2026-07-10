open! Core
open! Private_skyline_prelude
module Worker_protocol = Skyline_picker_v2_typeahead_search_worker_protocol
module Worker_state = Skyline_picker_v2_typeahead_search_worker_state

module Generation = struct
  type t = { generation : int } [@@unboxed] [@@deriving compare, sexp_of]

  include functor Comparator.Make
end

module Input_change_result = struct
  (** Response from [Model] on [Action.Input_changed] events. *)
  type 'a t =
    { items : 'a iarray or_null
    (** The ['a iarray] passed to [component], IFF it differs from the last state trackd
        by [Model]. If [This _], the web worker will be told to reset its input cache
        before continuing query processing. *)
    ; generation : int
    (** Generation to use when sending the fresh query to the worker. *)
    }
end

module Action = struct
  type ('a[@sexp.phantom], 'b[@sexp.phantom]) t =
    | Input_changed : ('b iarray[@sexp.opaque]) -> ('b Input_change_result.t, 'b) t
    | Search_complete :
        { generation : int
        ; indices : Worker_protocol.Indices.t
        }
        -> (unit, 'b) t
  [@@deriving sexp_of]

  let of_worker_message : Worker_protocol.From_worker.t -> (unit, 'b) t = function
    | Search_complete { generation; indices } -> Search_complete { generation; indices }
  ;;
end

module Model = struct
  type 'a[@sexp.phantom] t =
    { indices : Worker_protocol.Indices.t Map.M(Generation).t
    (** Indexes into [items], ordered by their fuzzy search store. One copy per query
        generation.

        Generally this map will be small. It only contains multiple entries when the query
        is being updated faster than the worker can return results, in which case we use
        the indices for the most recent query that refers to [items].

        Cleared whenever [items] changes. *)
    ; generation : int
    (** [generation] is incremented whenever [query] or [items] changes; we use this to
        track which worker responses correspond to which inputs. *)
    ; items : ('a iarray[@sexp.opaque])
    (** [items] is the raw input passed to [Worker_filter.component]. *)
    }
  [@@deriving sexp_of]

  (** Grab the most recent [indices] which refer to the current [items].

      This can refer to a stale query while we're waiting for an updated response from the
      worker. *)
  let latest_indices ({ indices; generation; _ } : _ t) =
    match Map.find_or_null indices { generation } with
    | This _ as indices -> indices
    | Null ->
      (* Fall back to the most recent indices; this keeps results stable while waiting for
         the worker to respond - see [Query_changed] handling in [recv]. *)
      (match Map.closest_key indices `Less_or_equal_to { generation } with
       | None -> Null
       | Some ({ generation = _ }, indices) -> This indices)
  ;;

  (** Convert the most recent valid [indices] for the current [items] to a ['a iarray]. *)
  let reify t =
    match latest_indices t with
    | Null -> t.items
    | This indices ->
      (* Indices cannot point out of bounds; every time [items] change we wipe out
         [indices]. *)
      Worker_protocol.Indices.to_iarray
        indices
        ~f:[%eta1 Iarray.unsafe_get t.items] [@nontail]
  ;;

  let recv (type a item) _ctx (t : item t) (action : (a, item) Action.t) : item t * a =
    match action with
    | Input_changed items ->
      let generation = t.generation + 1 in
      (* Here, either [items] or [query] has changed, or both.

         - When [items] are unchanged: Preserve the previous indices until we get a
           response - having the results be outdated for a few frames is better than
           having them flicker between filtered and unfiltered. We'll use the most recent
           one

         - When [items] have changed: Reset all indices, none of them are usable now.
      *)
      if phys_equal items t.items
      then { t with generation }, { items = Null; generation }
      else
        ( { generation; indices = Map.empty (module Generation); items }
        , { items = This items; generation } )
    | Search_complete { generation; indices } ->
      (* Old query result. We can't accept this because it might refer to an outdated
         [items]. *)
      if generation < t.generation
      then t, ()
      else (
        let indices = Map.add_exn t.indices ~key:{ generation } ~data:indices in
        let indices =
          (* Drop indices for old generations. *)
          let min_generation = Int.min generation t.generation in
          Map.filter_keys indices ~f:(fun { generation } -> generation >= min_generation)
        in
        { t with indices }, ())
  ;;
end

module Backend = struct
  type t = { post_message : Worker_protocol.To_worker.t -> unit Effect.t } [@@unboxed]

  let on_message ~inject =
    let%arr inject in
    fun message ->
      Effect.Expert.handle_non_dom_event_exn (inject (Action.of_worker_message message))
  ;;

  let blob_url =
    lazy
      (Web_worker.blob_url
         ~embedded_javascript_blob:Embedded_strings.For_worker_filter.worker_blob_js)
  ;;

  let create_web_worker ~inject (_ : Bonsai.graph @ local) : t Bonsai.t =
    let%arr on_message =
      (* [inject] doesn't ever actually change, so we're only creating a single worker,
         but using [let%arr inject] rather than an [on_change] hook means we don't
         initialize the worker until/unless this component is actually activated. *)
      on_message ~inject
    in
    let worker : Worker_protocol.Worker.t Js_of_ocaml.Js.t =
      match
        Or_error.try_with (fun () ->
          Worker_protocol.Worker.create ~script_url:(force blob_url) ~on_message)
      with
      | Ok w -> w
      | Error error -> raise_s [%message "Failed to create worker" (error : Error.t)]
    in
    { post_message =
        Effect.of_sync_fun [%eta1 Worker_protocol.To_worker.post_message ~worker]
    }
  ;;

  module For_jsdom_testing = struct
    let create ~inject (graph @ local) : t Bonsai.t =
      (* Web workers require browser APIs ([new Worker(url)]) that jsdom does not
         implement, so restrict the worker path to real browsers. Instead we simulate a
         web worker by running the same logic in the main context with an intentional
         delay before injecting the response. *)
      let%arr on_message = on_message ~inject
      and wait = Bonsai.Edge.wait_before_display graph in
      let state = Worker_state.create ~post_message:on_message () in
      { post_message =
          (fun message ->
            let (Packed { message; _ }) = Worker_protocol.To_worker.serialize message in
            let%bind.Effect () = wait in
            Effect.of_sync_fun (Worker_state.handle_message state) message)
      }
    ;;
  end

  let create ~inject (graph @ local) : t Bonsai.t =
    match Am_running_how_js.am_in_browser Am_running_how_js.am_running_how with
    | false -> For_jsdom_testing.create ~inject graph
    | true -> create_web_worker ~inject graph
  ;;
end

let trim_query query =
  Bonsai.cutoff
    ~equal:String.equal
    (let%arr query in
     String.strip query)
;;

module Phys_equal = struct
  type 'a t = 'a

  (* This is just here to make [%equal: _ Phys_equal.t * ...] work. *)
  let equal _ a b = phys_equal a b
end

let component
  (type item)
  ~items
  ~max_suggestions
  ~query_for_suggestions
  ~to_search_string
  (graph @ local)
  =
  let module Action = struct
    type 'a t = (('a[@sexp.phantom]), (item[@sexp.phantom])) Action.t [@@deriving sexp_of]
  end
  in
  let module Actor = Bonsai.Actor (Action) in
  let max_results = Or_null.of_option max_suggestions in
  let model, inject =
    Actor.create
      ~sexp_of_model:[%sexp_of: (_[@sexp.phantom]) Model.t]
      ~sexp_of_action:{ f = [%sexp_of: _ Action.t] }
      ~default_model:
        { generation = 0; indices = Map.empty (module Generation); items = Iarray.empty }
      ~recv:{ f = Model.recv }
      graph
  in
  let backend =
    Backend.create
      ~inject:
        (let%arr inject in
         inject.f)
      graph
  in
  Bonsai.Edge.on_change
    ~equal:[%equal: _ Phys_equal.t * string]
    (Bonsai.both items (trim_query query_for_suggestions))
    ~callback:
      (let%arr inject and backend in
       fun (items, query) ->
         let%bind.Effect { items; generation } = inject.f (Input_changed items) in
         let new_index =
           let%map.Or_null items in
           Iarray.map items ~f:to_search_string
         in
         backend.post_message { new_index; query; generation; max_results })
    graph;
  let%arr model in
  Model.reify model
;;
