open! Core
open! Private_skyline_prelude

type ('a, 'selection) render_selection =
  | Render : ('a -> Vdom.Node.t) -> ('a, 'a option) render_selection
  | Render_multi : ('a list -> Vdom.Node.t) -> ('a, 'a list) render_selection

let render_button_content
  (type a selection)
  ~(render_selection : (a, selection) render_selection option)
  ~placeholder
  ~(controller : (a, selection) Typeahead_controller.t)
  =
  match render_selection with
  | Some (Render render) ->
    let selected, _ = Typeahead_controller.state controller in
    (match selected with
     | Some item ->
       {%html|
         <Skyline_text_v2.view ~color:%{`Default}
           >%{render item}</>
       |}
     | None ->
       {%html|
         <Skyline_text_v2.view ~color:%{`Secondary}
           >#{placeholder}</>
       |})
  | Some (Render_multi render) ->
    let selected, _ = Typeahead_controller.state controller in
    (match selected with
     | [] ->
       {%html|
         <Skyline_text_v2.view ~color:%{`Secondary}
           >#{placeholder}</>
       |}
     | _ :: _ ->
       {%html|
         <Skyline_text_v2.view ~color:%{`Default}
           >%{render selected}</>
       |})
  | None ->
    let (T selection_mode) = Typeahead_controller.Private.selection_mode controller in
    (match selection_mode with
     | Multi_ux _ ->
       let selected, _ = Typeahead_controller.state controller in
       let to_string = Typeahead_controller.Private.to_string controller in
       (match selected with
        | [] ->
          {%html|
            <Skyline_text_v2.view ~color:%{`Secondary}
              >#{placeholder}</>
          |}
        | [ item ] ->
          {%html|
            <Skyline_text_v2.view ~color:%{`Default}
              >#{to_string item}</>
          |}
        | _ :: _ :: _ ->
          let count = List.length selected in
          let tooltip_text = List.map selected ~f:to_string |> String.concat ~sep:", " in
          {%html|
            <Skyline_text_v2.view ~color:%{`Default}>
              <span
                %{Skyline_tooltip_v2.text_attr tooltip_text}
                style="
                  text-decoration: underline dotted;
                  text-underline-offset: 2px;
                  cursor: default;
                  text-wrap: nowrap;
                "
              >
                #{[%string "%{count#Int} selected"]}
              </span>
            </>
          |})
     | Single_ux _ ->
       let selected, _ = Typeahead_controller.state controller in
       let to_string = Typeahead_controller.Private.to_string controller in
       (match selected with
        | None ->
          {%html|
            <Skyline_text_v2.view ~color:%{`Secondary}
              >#{placeholder}</>
          |}
        | Some item ->
          {%html|
            <Skyline_text_v2.view ~color:%{`Default}
              >#{to_string item}</>
          |})
     | Effect_only ->
       {%html|
         <Skyline_text_v2.view ~color:%{`Secondary}
           >#{placeholder}</>
       |})
;;

module Elements = struct
  let anchor ?test_selector ?(attrs = []) children =
    Skyline_field_v2.Content.make (fun ~size ~intent ~disabled ->
      let button_intent =
        match intent with
        | `Primary -> `Secondary
        | intent -> (intent :> Skyline_intent.t)
      in
      let size_adjustment =
        (* Adjust size to match [Select_input] *)
        match size with
        | `Xs | `Sm | `Md -> Attr.empty
        | `Lg -> Classes.py 1.5
      in
      let border_color =
        match button_intent with
        | `Primary -> Colors.Border.primary
        | `Secondary -> Colors.Border.default
        | `Danger -> Colors.Border.danger
        | `Success -> Colors.Border.success
        | `Warning -> Colors.Border.warning
      in
      {%html|
        <Skyline_button_v2.view
          ~type_attr:%{Submit}
          ~variant:%{Skyline_button_v2.Variant.Outlined}
          ~disabled
          ~intent:%{button_intent}
          ~size
          ~on_click:%{Effect.Ignore}
          style="border-color: %{border_color#Css_gen.Color}; width: 100%"
          %{size_adjustment}
          %{Test_selector.attr_of_opt test_selector}
          *{attrs}
        >
          <div *{Classes.[w_full; flex; items_center; justify_between; gap 1.]} style="text-wrap: nowrap">
            *{children}
            <Skyline_button_v2.Icon.view ~icon:%{Lucide.chevron_down} />
          </div>
        </>
      |})
  ;;
end

let attr controller = Typeahead_controller.Private.for_select_anchor controller

let content
  (type a selection)
  ?test_selector
  ?(attrs = [])
  ?render_selection
  ~placeholder
  ~(controller : (a, selection) Typeahead_controller.t)
  ()
  =
  {%html|
    <Elements.anchor
      ?test_selector
      *{attrs}
      %{Typeahead_controller.Private.for_select_anchor controller}
    >
      %{render_button_content ~render_selection ~placeholder ~controller}
    </>
  |}
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
