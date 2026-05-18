open! Core
open! Bonsai_web
open! Js_of_ocaml
open Bonsai.Let_syntax

type 'key t =
  { attr : key:'key -> Vdom.Attr.t
  ; get : key:'key -> Dom_html.element Js.t option Effect.t
  }
[@@deriving fields ~getters]

let create (type key cmp) ((module Key) : (key, cmp) Comparator.Module.t) (local_ graph) =
  let hook_id =
    Bonsai.Expert.thunk
      ~f:(fun () -> Type_equal.Id.create ~name:"keyed-dom-ref" sexp_of_opaque)
      graph
  in
  let key_id =
    Bonsai.Expert.thunk
      ~f:(fun () ->
        Type_equal.Id.create
          ~name:"keyed-dom-ref-key"
          (Comparator.sexp_of_t Key.comparator))
      graph
  in
  let tracker_state =
    Bonsai.Expert.thunk ~f:(fun () -> ref (Map.empty (module Key))) graph
  in
  let%arr hook_id and key_id and tracker_state in
  let find_element ~key = Map.find !tracker_state key in
  let attr ~key =
    Vdom.Attr.create_hook
      "keyed-dom-ref"
      (Vdom.Attr.Hooks.unsafe_create
         ~combine_inputs:(fun _ i -> i)
         ~id:hook_id
         ~extra:(key, key_id)
         ~init:(fun key element ->
           tracker_state := Map.set !tracker_state ~key ~data:element;
           key, (), ())
         ~update:(fun key (_, (), ()) _element -> key, (), ())
         ~destroy:(fun (key, (), ()) _element ->
           tracker_state := Map.remove !tracker_state key))
  in
  let get ~key = Effect.of_thunk (fun () -> find_element ~key) in
  { attr; get }
;;

let focus t ~key =
  let { get; _ } = t in
  match%map.Effect get ~key with
  | None -> ()
  | Some el -> el##focus
;;
