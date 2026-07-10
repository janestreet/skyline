open! Core
open! Private_skyline_prelude

module Intent = struct
  type t =
    [ `Primary
    | `Success
    | `Danger
    | `Warning
    ]
  [@@deriving to_string]

  (* Type assertion to verify [t] is a subset of [Skyline_intent.t] *)
  let _to_other_intent : t -> Skyline_intent.t = function
    | a -> (a :> Skyline_intent.t)
  ;;
end

module Label_position = struct
  type t =
    | Top
    | Left
    | Right
  [@@deriving to_string]
end

module Label_forwarding = struct
  open Js_of_ocaml

  let data_exclude_from_label_forwarding =
    "data-skyline-field-exclude-from-label-forwarding"
  ;;

  let coerce_to_html_element (element : #Browser_types.event_target Js.t Js.Opt.t) =
    let%bind.Option element = Js.Opt.to_option element in
    let%bind.Option window = Browser_expert.Global.window () in
    Browser_expert.coerce ~to_:window##._HTMLElement_t element
  ;;

  let for_label_attr =
    (* Do nothing in environments that might not implement target/preventDefault. *)
    if not Am_running_how_js.(am_in_browser_like_api am_running_how)
    then Attr.empty
    else (
      let selectors = Js.string [%string "[%{data_exclude_from_label_forwarding}]"] in
      let handler (event : Dom_html.mouseEvent Js.t) =
        let event = Browser_extra.Coercion.of_jsoo_event event in
        let should_prevent_default =
          match coerce_to_html_element event##.target with
          | None -> false
          | Some target -> Js.Opt.test (target##closest ~selectors)
        in
        if should_prevent_default
        then
          (* We disable native browser label forwarding behavior by preventing default
             click behavior on the <label> element. *)
          event##preventDefault;
        Effect.Ignore
      in
      Attr.many
        [ (* For some reason we have to do both of these to disable label forwarding. *)
          Attr.on_click handler
        ; Attr.on_mousedown handler
        ])
  ;;
end

module Content = struct
  type t =
    size:Skyline_size.t -> intent:Intent.t -> disabled:bool -> Node.t * unit Or_error.t

  let make
    (f : size:Skyline_size.t -> intent:Intent.t -> disabled:bool -> Node.t)
    ~size
    ~intent
    ~disabled
    =
    f ~size ~intent ~disabled, Ok ()
  ;;

  let make' f = f

  module Expert = struct
    let exclude_from_label_forwarding =
      Attr.create Label_forwarding.data_exclude_from_label_forwarding ""
    ;;
  end
end

module Style = struct
  let row_gap = `Px 2

  let column_gap = function
    | `Xs | `Sm -> `Px 4
    | `Md -> `Px 6
    | `Lg -> `Px 8
  ;;

  let block_layout ~in_group =
    let base_styles =
      [%css
        {|
          display: flex;
          flex-direction: column;
          height: fit-content;
          gap: %{row_gap#Css_gen.Length};
        |}]
    in
    let row_styles =
      if in_group then [%css {|grid-column: 1 / -1;|}] else Vdom.Attr.empty
    in
    Attr.many [ base_styles; row_styles ]
  ;;

  let inline_layout ~size ~in_group =
    let base_styles =
      [%css
        {|
          display: grid;
          align-items: start;
          row-gap: %{row_gap#Css_gen.Length};
          column-gap: %{(column_gap size)#Css_gen.Length};
        |}]
    in
    let column_styles =
      if in_group
      then
        [%css
          {|
            grid-template-columns: subgrid;
            grid-column: 1 / -1;
          |}]
      else
        [%css
          {|
            height: fit-content;
            width: 100%;
            grid-template-columns: auto 1fr;
          |}]
    in
    Attr.many [ base_styles; column_styles ]
  ;;
end

module Label = struct
  type t = size:Skyline_size.t -> intent:Intent.t -> disabled:bool -> Vdom.Node.t

  let make f = f

  module Style = struct
    let text size =
      let text_size =
        match size with
        | `Xs -> Classes.text_2xs
        | `Sm -> Classes.text_xs
        | `Md -> Classes.text_sm
        | `Lg -> Classes.text_base
      in
      Attr.many [ text_size ]
    ;;
  end

  let content ?test_selector ?(attrs = []) children =
    make (fun ~size ~intent:_ ~disabled:_ ->
      {%html|
        <div
          %{Test_selector.attr_of_opt test_selector}
          %{Style.text size}
          *{attrs}
        >
          *{children}
        </div>
      |})
  ;;
end

module Footer = struct
  type t = size:Skyline_size.t -> intent:Intent.t -> disabled:bool -> Node.t

  let make f = f

  module Style = struct
    let text size =
      let text_size =
        match size with
        | `Xs -> Classes.text_2xs
        | `Sm -> Classes.text_xs
        | `Md -> Classes.text_sm
        | `Lg -> Classes.text_base
      in
      Attr.many [ text_size; Classes.text_default ]
    ;;

    let color ~disabled (intent : Intent.t) =
      if disabled
      then Classes.text_secondary
      else (
        match intent with
        | `Primary -> Classes.text_secondary
        | `Success -> Classes.text_success
        | `Danger -> Classes.text_danger
        | `Warning -> Classes.text_warning)
    ;;
  end

  let content ?test_selector ?(attrs = []) children =
    make (fun ~size ~intent ~disabled ->
      {%html|
        <div
          %{Test_selector.attr_of_opt test_selector}
          %{Style.text size}
          %{Style.color ~disabled intent}
          *{attrs}
        >
          *{children}
        </div>
      |})
  ;;
end

let view'
  ?test_selector
  ?(attrs = [])
  ?(label_position = Label_position.Top)
  ?(size = `Md)
  ?(intent = `Primary)
  ?(disabled = false)
  ?(in_group = false)
  ?label
  ?footer
  (contents : Content.t list)
  =
  let module Elements = struct
    let label ?(attrs = []) () =
      match label with
      | Some label ->
        let text_color =
          match label_position with
          | Top -> Classes.text_default
          | Left | Right ->
            if disabled then Classes.text_disabled else Classes.text_default
        in
        {%html|<div *{attrs} %{text_color}>%{label ~size ~intent ~disabled}</div>|}
      | None -> Node.none
    ;;

    let content_nodes_and_error =
      let evaluated_contents =
        List.map contents ~f:(fun content -> content ~size ~intent ~disabled)
      in
      let nodes, errors = List.unzip evaluated_contents in
      let error = Or_error.all_unit errors in
      nodes, error
    ;;

    let footer ?(attrs = []) () =
      let _, error = content_nodes_and_error in
      match error with
      | Ok () ->
        (match footer with
         | Some footer -> {%html|<div *{attrs}>%{footer ~size ~intent ~disabled}</div>|}
         | None -> Node.none)
      | Error error ->
        let error_text = Error.to_string_hum error in
        {%html|
          <div
            %{Footer.Style.text size}
            %{Footer.Style.color ~disabled `Danger}
            *{attrs}
          >
            %{error_text#String}
          </div>
        |}
    ;;

    let contents ?(attrs = []) () =
      let nodes, _ = content_nodes_and_error in
      (* Flex ensures we don't impose our line-height on inline children. *)
      {%html|<div *{attrs} %{Classes.flex} %{Classes.flex_col}>*{nodes}</div>|}
    ;;
  end
  in
  match label_position with
  | Top ->
    {%html|
      <label
        *{attrs}
        %{Label_forwarding.for_label_attr}
        %{Test_selector.attr_of_opt test_selector}
        %{Style.block_layout ~in_group }
      >
        <Elements.label />
        <Elements.contents />
        <Elements.footer />
      </label>
    |}
  | Left ->
    {%html|
      <label
        *{attrs}
        %{Label_forwarding.for_label_attr}
        %{Test_selector.attr_of_opt test_selector}
        %{Style.inline_layout ~size ~in_group }
      >
        <Elements.label style="grid-column: 1; align-self: center" />
        <Elements.contents style="grid-column: 2" />
        <Elements.footer style="grid-column: 2" />
      </label>
    |}
  | Right ->
    {%html|
      <label
        *{attrs}
        %{Label_forwarding.for_label_attr}
        %{Test_selector.attr_of_opt test_selector}
        %{Style.inline_layout ~size ~in_group }
      >
        <Elements.contents style="grid-column: 1; width: max-content" />
        <Elements.label style="grid-column: 2; align-self: center" />
        <Elements.footer style="grid-column: 2" />
      </label>
    |}
;;

let view
  ?test_selector
  ?attrs
  ?label_position
  ?size
  ?intent
  ?disabled
  ?label
  ?footer
  contents
  =
  view'
    ?test_selector
    ?attrs
    ?label_position
    ?size
    ?intent
    ?disabled
    ?label
    ?footer
    contents
;;

module Grid = struct
  let field
    ?test_selector
    ?attrs
    ?(label_position = Label_position.Left)
    ?(size = `Md)
    ?(intent = `Primary)
    ?(disabled = false)
    ?label
    ?footer
    (contents : Content.t list)
    : Vdom.Node.t
    =
    view'
      ?test_selector
      ?attrs
      ~label_position
      ~size
      ~intent
      ~disabled
      ~in_group:true
      ?label
      ?footer
      contents
  ;;

  let view ?test_selector ?(attrs = []) (fields : Vdom.Node.t list) =
    {%html|
      <fieldset
        style="display: grid; grid-template-columns: auto 1fr"
        *{attrs}
        %{Test_selector.attr_of_opt test_selector}
      >
        *{fields}
      </fieldset>
    |}
  ;;
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
