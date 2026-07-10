open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

(* This is a generic input, so we can just include it here. *)
include Skyline_input_v1

let component
  ?test_selector
  ?state:external_state
  ?(disabled = Bonsai.return false)
  ~to_string
  choices
  (local_ graph)
  =
  let current, update =
    match external_state with
    | Some state -> state
    | None ->
      let current, update = Bonsai.state None graph in
      let current =
        let%arr current and choices in
        match current with
        | Some value -> value
        | None -> Nonempty_list.hd choices
      in
      let update =
        let%arr update in
        fun value -> update (Some value)
      in
      current, update
  in
  let view =
    let%arr disabled and current and update and choices in
    let current_value = to_string current in
    let equal_to_current choice =
      phys_equal choice current || String.equal (to_string choice) current_value
    in
    let on_change =
      Vdom.Attr.on_change (fun _ value ->
        Nonempty_list.find choices ~f:(fun choice ->
          String.equal (to_string choice) value)
        |> Option.value_map ~f:update ~default:Effect.Ignore)
    in
    let maybe_disabled =
      if disabled
      then
        Vdom.Attr.many
          [ Vdom.Attr.style (Css_gen.create ~field:"cursor" ~value:"not-allowed")
          ; Vdom.Attr.disabled
          ]
      else Vdom.Attr.empty
    in
    let current_choice_exists_in_options =
      Nonempty_list.exists choices ~f:equal_to_current
    in
    let choices =
      Nonempty_list.map choices ~f:(fun choice ->
        let maybe_selected =
          if equal_to_current choice then Vdom.Attr.selected else Vdom.Attr.empty
        in
        let value = to_string choice in
        Vdom.Node.option
          ~attrs:[ Vdom.Attr.value_attr value; maybe_selected ]
          [ Vdom.Node.text value ])
      |> Nonempty_list.to_list
    in
    let maybe_with_empty_choice =
      match current_choice_exists_in_options with
      | false ->
        let empty_choice =
          Vdom.Node.option
          (* We need a key here so that we remove the correct <option> element when the
             DOM is patched. Otherwise the visibly selected option might shift. *)
            ~key:"fallback-missing-option"
            ~attrs:
              [ Vdom.Attr.value_attr current_value
              ; Vdom.Attr.style (Css_gen.display `None)
              ; Vdom.Attr.disabled
              ; (if not current_choice_exists_in_options
                 then Vdom.Attr.selected
                 else Vdom.Attr.empty)
              ]
            [ Vdom.Node.text current_value ]
        in
        empty_choice :: choices
      | true -> choices
    in
    Vdom.Node.select
      ~attrs:
        [ Vdom.Attr.value current_value
        ; on_change
        ; maybe_disabled
        ; Skyline_text_input_v1.Expert.style
        ; Test_selector.attr_of_opt test_selector
        ]
      maybe_with_empty_choice
  in
  Skyline_input_v1.create view current update
;;
