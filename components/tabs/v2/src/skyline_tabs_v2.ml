open! Core
open! Private_skyline_prelude
module Button = Skyline_button_v2

module Style = struct
  let border_bottom =
    {%css|
      /* We use inset borders so that the height of Tabs is exactly the same as Buttons. */
      box-shadow: inset 0 -1px 0 0 %{Colors.Border.default#Css_gen.Color};
    |}
  ;;

  let tab_active size =
    let height =
      match size with
      | `Xs | `Sm -> `Px (-1)
      | `Md | `Lg -> `Px (-2)
    in
    {%css|
      box-shadow: inset 0 %{height#Css_gen.Length} 0 0
        %{Colors.Border.primary#Css_gen.Color};
    |}
  ;;
end

type 'a t =
  { value : 'a
  ; set_value : 'a -> unit Effect.t
  ; view : Vdom.Node.t
  }

module Item = struct
  let view ?test_selector ~attrs ~size ~is_selected ~is_disabled ~on_click children =
    let intent =
      match is_selected with
      | true -> `Primary
      | false -> `Secondary
    in
    let on_click =
      match is_disabled with
      | true -> Effect.Ignore
      | false -> on_click
    in
    let selected_attr =
      match is_selected with
      | true -> Some (Style.tab_active size)
      | false -> None
    in
    {%html|
      <div
        ?{selected_attr}
        style="
          /* prevent inline elements from inheriting line height and being too tall */
          line-height: 0;
        "
      >
        <Button.view
          ~type_attr:%{Submit}
          style="
            /* We apply border-radius: 0 to opt out of the default rounded corners for
               hover/active/focus states. */
            border-radius: 0;
          "
          *{attrs}
          ?test_selector
          ~disabled:%{is_disabled}
          ~intent
          ~variant:%{Ghost}
          ~size
          ~on_click
          >*{children}</>
      </div>
    |}
  ;;
end

let view
  ?test_selectors
  ?(attrs = [])
  ?(item_attrs = Fn.const [])
  ?(size = `Md)
  ?(is_disabled = Fn.const false)
  items
  ~equal
  ~state:(value, set_value)
  ~label
  =
  let tabs =
    Nonempty_list.to_list items
    |> List.map ~f:(fun item ->
      let test_selector =
        Option.map test_selectors ~f:(fun selectors ->
          Test_selector.Keyed.get selectors item)
      in
      let attrs = item_attrs item in
      let is_selected = equal item value in
      let is_disabled = is_disabled item in
      let on_click = set_value item in
      let item_label = label item in
      {%html|
        <Item.view ?test_selector ~attrs ~size ~is_selected ~is_disabled ~on_click
          >%{item_label}</>
      |})
  in
  {%html|
    <div
      *{Classes.[flex]}
      %{Style.border_bottom}
      *{attrs}
      %{Classes.data_skyline_component "tabs"}
    >
      *{tabs}
    </div>
  |}
;;

let component
  ?test_selectors
  ?attrs
  ?item_attrs
  ?size
  ?state
  ?is_disabled
  ~equal
  ~items
  ~label
  graph
  =
  let value, set_value =
    match state with
    | None -> Bonsai_kernel_selection_state.One_of_many.create ~equal items graph
    | Some state -> state
  in
  let%arr value
  and set_value
  and items
  and size = Bonsai.transpose_opt size
  and attrs = Bonsai.transpose_opt attrs
  and item_attrs = Bonsai.transpose_opt item_attrs
  and is_disabled = Bonsai.transpose_opt is_disabled
  and label in
  let view =
    view
      ?test_selectors
      ?attrs
      ?item_attrs
      ?size
      ?is_disabled
      items
      ~equal
      ~state:(value, set_value)
      ~label
  in
  { value; set_value; view }
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
