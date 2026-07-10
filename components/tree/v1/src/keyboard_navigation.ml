open! Core
open! Bonsai_web
open! Js_of_ocaml

(* Keyboard accessible focus for tree rows. *)

let row_attr ~on_enter =
  let is_keyboard_navigable (element : Dom_html.element Js.t) =
    (* [Vdom.Attr.tabindex] renders as an attribute (not the [tabIndex] property) *)
    match Js.Opt.to_option (element##getAttribute (Js.string "tabindex")) with
    | Some tab_index -> not (String.equal (Js.to_string tab_index) "-1")
    | None -> false
  in
  (* Walks past non-navigable siblings (e.g. disabled rows, which the tree renders without
     a [tabindex], and nodes that are not HTML elements). *)
  let rec keyboard_navigable_sibling (element : Dom.element Js.t) which =
    match which element |> Js.Opt.to_option with
    | None -> None
    | Some sibling ->
      (match Dom_html.CoerceTo.element (sibling :> Dom.node Js.t) |> Js.Opt.to_option with
       | Some html_sibling when is_keyboard_navigable html_sibling -> Some html_sibling
       | Some (_ : Dom_html.element Js.t) | None ->
         keyboard_navigable_sibling sibling which)
  in
  let focus_sibling_row event which =
    let row_to_focus =
      let%bind.Option current = event##.currentTarget |> Js.Opt.to_option in
      let%bind.Option current = Dom_html.CoerceTo.element current |> Js.Opt.to_option in
      keyboard_navigable_sibling (current :> Dom.element Js.t) which
    in
    Option.iter row_to_focus ~f:(fun element -> element##focus);
    Dom.preventDefault event;
    Effect.Stop_propagation
  in
  let on_key_down event =
    let has_modifier =
      Js.to_bool event##.ctrlKey
      || Js.to_bool event##.altKey
      || Js.to_bool event##.metaKey
    in
    match Dom_html.Keyboard_code.of_event event with
    | Enter ->
      let event_target_is_whole_row =
        (* We do not want to trigger the effect when we press [Enter] on something like a
           collapse chevron in the tree view. *)
        phys_equal event##.currentTarget (Js.Opt.return (Dom_html.eventTarget event))
      in
      if event_target_is_whole_row
      then (
        let%bind.Effect () = on_enter in
        Effect.Stop_propagation)
      else Effect.Ignore
    (* Up / Down arrows move focus to the next / previous row. *)
    | ArrowDown -> focus_sibling_row event (fun elem -> elem##.nextElementSibling)
    | ArrowUp -> focus_sibling_row event (fun elem -> elem##.previousElementSibling)
    (* Vim-like motion keys. We need to check for the modifier, since otherwise this could
       eat interesting keyboard shortcuts. *)
    | KeyJ when not has_modifier ->
      focus_sibling_row event (fun elem -> elem##.nextElementSibling)
    | KeyK when not has_modifier ->
      focus_sibling_row event (fun elem -> elem##.previousElementSibling)
    | _ -> Effect.Ignore
  in
  Vdom.Attr.on_keydown on_key_down
;;
