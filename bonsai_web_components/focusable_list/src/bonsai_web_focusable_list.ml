open! Core
open! Bonsai_web
open Bonsai.Let_syntax

module Action = struct
  type 'id t =
    | Focus of 'id
    | Next
    | Prev
    | First
    | Last
  [@@deriving sexp_of, equal]
end

module Model = struct
  type 'id t =
    { focusable : 'id option
    ; index_hint : int option
    }
  [@@deriving sexp_of, equal]

  let empty = { focusable = None; index_hint = None }
end

let find_index ~ids ~equal id =
  Iarray.findi ids ~f:(fun _ candidate -> equal candidate id)
  |> Option.map ~f:(fun (i, _) -> i)
;;

(** Returns the index of the focusable element, using the hint if valid. *)
let resolve_index ~ids ~equal ~focusable ~index_hint =
  match focusable, index_hint with
  | None, _ -> None
  | Some id, Some hint ->
    (match Iarray.get_opt ids hint with
     | Some hinted_id when equal hinted_id id -> Some hint (* hint valid *)
     | _ -> find_index ~ids ~equal id (* hint stale *))
  | Some id, None -> find_index ~ids ~equal id
;;

(** [revalidate] ensures [model.focusable] is a valid item in [ids]. It is a pure function
    that takes model and list of ids and returns a new model.

    - If focusable is [None], returns the first item (if any).
    - If focusable still exists in [ids], returns it unchanged.
    - If focusable was removed, returns the closest item by [index_hint].

    It is reasonable to think that we should call [Focus] instead, as the element may have
    changed its index in the list.

    We instead rely on two properties:
    1. The [index_hint] is just a hint. Within [resolve_index] we always verify it hasn't
       gone stale, that way we only pay the cost for the O(n) scan to find the index when
       we need it instead of eagerly where it might be wasted work.

    2. The consumer of this API should apply vdom keys to the list children. That way DOM
       focus is preserved. *)
let revalidate ~ids ~equal (model : 'a Model.t) : 'a Model.t =
  let len = Iarray.length ids in
  let focus_index i =
    match Iarray.get_opt ids i with
    | None -> model
    | Some id -> { Model.focusable = Some id; index_hint = Some i }
  in
  match model.focusable with
  | None -> focus_index 0
  | Some focusable_item ->
    let still_in_list =
      let slow_path () = Iarray.mem ids ~equal focusable_item in
      match model.index_hint with
      | Some hint ->
        (match Iarray.get_opt ids hint with
         | Some item when equal item focusable_item -> true
         | _ -> slow_path ())
      | None -> slow_path ()
    in
    if still_in_list
    then model
    else (
      match model.index_hint with
      | None -> focus_index 0
      | Some index_hint ->
        if len = 0
        then { model with focusable = None }
        else (
          let closest_valid_index = Int.clamp_exn ~min:0 ~max:(len - 1) index_hint in
          focus_index closest_valid_index))
;;

let apply_action ~ids ~wrap_around ~equal model (action : _ Action.t) =
  let len = Iarray.length ids in
  let focus_index i =
    match Iarray.get_opt ids i with
    | None -> model, model.Model.focusable
    | Some id -> { Model.focusable = Some id; index_hint = Some i }, Some id
  in
  match action with
  | Focus id ->
    (match find_index ~ids ~equal id with
     | None -> model, model.focusable
     | Some i -> { focusable = Some id; index_hint = Some i }, Some id)
  | First -> focus_index 0
  | Last -> focus_index (len - 1)
  | Next ->
    (match
       resolve_index ~ids ~equal ~focusable:model.focusable ~index_hint:model.index_hint
     with
     | None -> focus_index 0
     | Some i ->
       if i + 1 >= len
       then if wrap_around then focus_index 0 else model, model.focusable
       else focus_index (i + 1))
  | Prev ->
    (match
       resolve_index ~ids ~equal ~focusable:model.focusable ~index_hint:model.index_hint
     with
     | None -> focus_index (len - 1)
     | Some i ->
       if i - 1 < 0
       then if wrap_around then focus_index (len - 1) else model, model.focusable
       else focus_index (i - 1))
;;

type 'id t =
  { focusable : 'id option
  ; has_focus : bool
  ; inject : 'id Action.t -> 'id option Effect.t
  ; dom_refs : 'id Keyed_dom_ref.t
  ; set_has_focus : bool -> unit Effect.t
  ; equal : 'id -> 'id -> bool
  }

let focusable t = t.focusable
let has_focus t = t.has_focus

let create
  (type id)
  ?(wrap_around = Bonsai.return false)
  (module Id : Comparable.S_plain with type t = id)
  (ids : id Iarray.t Bonsai.t)
  (local_ graph)
  =
  let dom_refs = Keyed_dom_ref.create (module Id) graph in
  let has_focus, set_has_focus = Bonsai.state false graph in
  let model, inject =
    Bonsai.actor_with_input
      ~default_model:Model.empty
      ~recv:(fun _ctx input model action ->
        match input with
        | Bonsai.Computation_status.Inactive -> model, model.focusable
        | Active (wrap_around, ids) ->
          apply_action ~ids ~wrap_around ~equal:Id.equal model action)
      ~equal:[%equal: Id.t Model.t]
      (Bonsai.both wrap_around ids)
      graph
  in
  (* Focus DOM element when focusable id changes, but only if we have focus *)
  let () =
    let focusable = Bonsai.map model ~f:(fun m -> m.focusable) in
    Bonsai.Edge.on_change
      focusable
      ~trigger:`After_display
      ~equal:[%equal: Id.t option]
      ~callback:
        (let%arr dom_refs and has_focus in
         function
         | None -> Effect.Ignore
         | Some id ->
           if has_focus then Keyed_dom_ref.focus dom_refs ~key:id else Effect.Ignore)
      graph
  in
  (* Re-focus after ids change (VDOM reconciliation can drop browser focus), but only if
     we have focus *)
  let () =
    Bonsai.Edge.on_change
      ~trigger:`After_display
      ids
      ~equal:[%equal: Id.t iarray]
      ~callback:
        (let%arr dom_refs and model and has_focus in
         fun _ids ->
           match model.focusable with
           | None -> Effect.Ignore
           | Some id ->
             if has_focus then Keyed_dom_ref.focus dom_refs ~key:id else Effect.Ignore)
      graph
  in
  (* When ids change: ensure focusable is always set to a valid item.
     - If focusable item was removed, pick closest by index
     - If focusable is None and items exist, pick first item *)
  let () =
    let callback =
      let%arr model and inject in
      fun items ->
        let revalidated_model : Id.t Model.t =
          revalidate model ~ids:items ~equal:Id.equal
        in
        match revalidated_model.focusable, model.Model.focusable with
        | Some revalidated_id, Some current_id
          when not (Id.equal revalidated_id current_id) ->
          inject (Focus revalidated_id) |> Effect.ignore_m
        | Some revalidated, None -> inject (Focus revalidated) |> Effect.ignore_m
        | _ -> Effect.Ignore
    in
    (* NOTE: We intentionally use [phys_equal] instead of [[%equal: Id.t list]] as a
       faster equality function. If this proves too "loose", resulting in unnecessary
       calls to [callback], consider using [[%equal: Id.t list]] instead. *)
    Bonsai.Edge.on_change ~equal:phys_equal ids ~trigger:`Before_display ~callback graph
  in
  let t =
    let%arr { Model.focusable; _ } = model
    and has_focus
    and dom_refs
    and inject
    and set_has_focus in
    { focusable; has_focus; inject; dom_refs; set_has_focus; equal = Id.equal }
  in
  t, inject
;;

let item_attr (type id) (t : id t Bonsai.t) : (id -> Vdom.Attr.t) Bonsai.t =
  let%arr { focusable; inject; dom_refs; equal; _ } = t in
  fun id ->
    let is_focusable =
      match focusable with
      | Some focusable_id -> equal focusable_id id
      | None -> false (* only when ids is empty *)
    in
    Vdom.Attr.many
      [ Keyed_dom_ref.attr dom_refs ~key:id
      ; Vdom.Attr.tabindex (if is_focusable then 0 else -1)
      ; Vdom.Attr.on_click (fun _ -> inject (Focus id) |> Effect.ignore_m)
      ]
;;

let container_attr (type id) (t : id t) : Vdom.Attr.t =
  Vdom.Attr.many
    [ Vdom.Attr.on_focusin (fun _ -> t.set_has_focus true)
    ; Vdom.Attr.on_focusout (fun _ -> t.set_has_focus false)
    ]
;;

module For_testing = struct
  let ascii_render t ~ids ~to_string =
    let open Ascii_table_kernel in
    let columns =
      [ Column.create "Items" (fun (idx, id) ->
          let prefix =
            match t.focusable with
            | Some focusable_id when t.equal focusable_id id -> "->"
            | _ -> "  "
          in
          sprintf "%s %d. %s" prefix idx (to_string id))
      ]
    in
    let rows = Iarray.to_list ids |> List.mapi ~f:(fun idx id -> idx, id) in
    Ascii_table_kernel.to_string_noattr columns rows ~bars:`Unicode
  ;;
end
