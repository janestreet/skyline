open! Core
open! Private_skyline_prelude
module Options = Select_options

let prevent_and_stop event =
  let open Js_of_ocaml in
  Dom.preventDefault event;
  Dom_html.stopPropagation event
;;

module Controller = struct
  type 'a t =
    { select_attr : Attr.t
    ; selected : 'a
    ; all_values : 'a list
    }

  let component
    (type a)
    (module M : Comparable.S_plain with type t = a)
    ~state:(selected, set_selected)
    ~options
    (graph @ local)
    =
    let enabled_values =
      let%arr options in
      Options.enabled_values options |> Iarray.of_list
    in
    let focusable_list, inject_focusable =
      Bonsai_web_focusable_list.create (module M) enabled_values graph
    in
    let ( (* Make sure the focus stays in sync with any external state. *) ) =
      let callback =
        let%arr focusable_list and inject_focusable in
        fun value ->
          let current_focused = Bonsai_web_focusable_list.focusable focusable_list in
          if [%equal: M.t option] (Some value) current_focused
          then Effect.Ignore
          else inject_focusable (Focus value) |> Effect.ignore_m
      in
      Bonsai.Edge.on_change ~equal:M.equal ~callback selected graph
    in
    let popover =
      Skyline_popover_v2.component'
        ~position:(return Skyline_popover_v2.Position.Bottom)
        ~alignment:(return Skyline_popover_v2.Alignment.Start)
        ~match_anchor_side_length:
          (return Skyline_popover_v2.Match_anchor_side.Grow_to_match)
        ~close_on_click_outside:(return true)
        (fun ~hide:close graph ->
          let on_keydown =
            let%arr close and focusable_list and inject_focusable and set_selected in
            fun event ->
              let open Js_of_ocaml in
              match Dom_html.Keyboard_code.of_event event with
              | Escape ->
                prevent_and_stop event;
                close
              | Enter | NumpadEnter ->
                prevent_and_stop event;
                (match Bonsai_web_focusable_list.focusable focusable_list with
                 | None -> Effect.Ignore
                 | Some focused_value ->
                   let%bind.Effect () = set_selected focused_value in
                   close)
              | ArrowDown ->
                prevent_and_stop event;
                inject_focusable Bonsai_web_focusable_list.Action.Next |> Effect.ignore_m
              | ArrowUp ->
                prevent_and_stop event;
                inject_focusable Prev |> Effect.ignore_m
              | _ -> Effect.Ignore
          in
          let on_select =
            let%arr set_selected and close and inject_focusable in
            fun value ->
              let%bind.Effect () = set_selected value in
              let%bind.Effect _ = inject_focusable (Focus value) in
              close
          in
          let focus_attr = Effect.Focus.on_activate () graph in
          let item_attr = Bonsai_web_focusable_list.item_attr focusable_list in
          let%arr options
          and focus_attr
          and focusable_list
          and item_attr
          and on_keydown
          and on_select in
          let attrs =
            [ focus_attr
            ; Attr.on_keydown on_keydown
            ; Bonsai_web_focusable_list.container_attr focusable_list
            ; {%css|padding: %{Classes.spacing 2.#Css_gen.Length};|}
            ]
          in
          let is_focused value =
            match Bonsai_web_focusable_list.focusable focusable_list with
            | Some focused_value -> M.compare focused_value value = 0
            | None -> false
          in
          let item_attr value =
            Attr.many [ Attr.on_click (fun _ -> on_select value); item_attr value ]
          in
          {%html.jsx|<div %{Classes.pt 0.5}>%{Options.view ~attrs ~is_focused ~item_attr options}</div>|})
        graph
    in
    let close_popover =
      let%arr popover in
      popover.Skyline_popover_v2.set_is_open false
    in
    Bonsai.Edge.lifecycle ~on_deactivate:close_popover graph;
    let%arr popover and selected and set_selected and inject_focusable and options in
    let { Skyline_popover_v2.anchor; is_open = _; set_is_open } = popover in
    let on_keydown =
      Attr.on_keydown (fun event ->
        let open Js_of_ocaml in
        match Dom_html.Keyboard_code.of_event event with
        | ArrowDown ->
          prevent_and_stop event;
          (match%bind.Effect inject_focusable Next with
           | None -> Effect.Ignore
           | Some value -> set_selected value)
        | ArrowUp ->
          prevent_and_stop event;
          (match%bind.Effect inject_focusable Prev with
           | None -> Effect.Ignore
           | Some value -> set_selected value)
        | _ -> Effect.Ignore)
    in
    let select_attr =
      Attr.many [ anchor; Attr.on_click (fun _ -> set_is_open true); on_keydown ]
    in
    let all_values = Options.all_values options in
    { select_attr; selected; all_values }
  ;;
end

let max_sizer_items = 100

module Elements = struct
  module Anchor = struct
    let view
      ?test_selector
      ?(attrs = [])
      ~rendered_selection
      ?(items_for_sizer = [])
      ?(size = `Md)
      ?(intent = `Primary)
      ?(disabled = false)
      suffix_content
      =
      let intent =
        match intent with
        | `Primary -> `Secondary
        | intent -> (intent :> Skyline_intent.t)
      in
      let sizer =
        match items_for_sizer with
        | ([] | _) when am_running_test -> Vdom.Node.none
        | [] -> Vdom.Node.none
        | items_for_sizer ->
          let option_sizers =
            List.take items_for_sizer max_sizer_items
            |> List.map ~f:(fun value ->
              {%html.jsx|
                <div *{Classes.[flex; justify_between; gap 1.]}>
                  %{value} *{suffix_content}
                </div>
              |})
          in
          {%html.jsx|
            <div
              style="grid-area: 1 / 1; visibility: hidden; height: 0; overflow: hidden"
              %{Attr.create "aria-hidden" "true"}
            >
              *{option_sizers}
            </div>
          |}
      in
      let content =
        {%html.jsx|
          <div style="display: grid" *{Classes.[w_full]}>
            %{sizer}
            <div style="grid-area: 1 / 1" *{Classes.[flex; justify_between; items_center; gap 1.]}>
              %{rendered_selection} *{suffix_content}
            </div>
          </div>
        |}
      in
      {%html.jsx|
        <Skyline_button_v2.view
          ~variant:%{Skyline_button_v2.Variant.Outlined}
          ~disabled
          ~intent
          ~size
          ~on_click:%{Effect.Ignore}
          style="width: 100%"
          %{Test_selector.attr_of_opt test_selector}
          *{attrs}
        >
          %{content}
        </>
      |}
    ;;
  end
end

let content ?test_selector ?(attrs = []) ~render_anchor_content ~controller () =
  let { Controller.select_attr; selected; all_values } = controller in
  Skyline_field_v2.Content.make (fun ~size ~intent ~disabled ->
    let items_for_sizer =
      List.map all_values ~f:(fun value -> render_anchor_content value)
    in
    Elements.Anchor.view
      ?test_selector
      ~attrs:[ select_attr; Attr.many attrs ]
      ~rendered_selection:(render_anchor_content selected)
      ~items_for_sizer
      ~size
      ~intent
      ~disabled
      [ {%html.jsx|<Skyline_button_v2.Icon.view ~icon:%{Lucide.chevron_down} />|} ])
;;

module Optional = struct
  module Controller = struct
    type 'a t = 'a option Controller.t

    let component
      (type a)
      (module M : Comparable.S_plain with type t = a)
      ~state:(selected, set_selected)
      ~options
      (graph @ local)
      =
      Controller.component
        (module struct
          type t = M.t option [@@deriving compare]

          let sexp_of_t = Option.sexp_of_t (Comparator.sexp_of_t M.comparator)

          include functor Comparable.Make_plain
        end)
        ~state:(selected, set_selected)
        ~options
        graph
    ;;
  end

  let content ?test_selector ?attrs ~placeholder ~render_anchor_content ~controller () =
    content
      ?test_selector
      ?attrs
      ~render_anchor_content:(function
        | Some value ->
          {%html.jsx|
            <Skyline_text_v2.view ~color:%{`Default}
              >%{render_anchor_content value}</>
          |}
        | None ->
          {%html.jsx|
            <Skyline_text_v2.view ~color:%{`Secondary}
              >#{placeholder}</>
          |})
      ~controller
      ()
  ;;
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
