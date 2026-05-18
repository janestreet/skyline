open! Core
open! Private_skyline_prelude

module Styles = struct
  include
    [%css
    stylesheet
      {|
        @layer skyline-select {
          .content_wrapper {
            display: grid;
            grid-template-columns: auto 1fr;

            .row {
              align-items: center;
              display: grid;
              grid-column: 1 / -1;
              grid-template-columns: subgrid;
            }

            .icon_left {
              grid-column: 1;
              margin-right: %{Classes.spacing 1.#Css_gen.Length};
            }

            .row_content_wrapper {
              align-items: center;
              column-gap: %{Classes.spacing 1.#Css_gen.Length};
              display: flex;
              flex-grow: 1;
              grid-column: 2;
              justify-content: space-between;
            }

            .row:not(:has(> .icon_left)) .icon_left {
              margin-right: 0;
            }
          }
        }
      |}]

  let item_extra_style = Attr.many [ row; {%css|text-wrap: nowrap;|} ]

  let icon_size ~size =
    match size with
    | `Xs -> `Px 12
    | `Sm -> `Px 14
    | `Md -> `Px 16
    | `Lg -> `Px 18
  ;;
end

module Item = struct
  type 'a t =
    { value : 'a
    ; attrs : Attr.t list
    ; disabled : bool
    ; icon : Bonsai_web_icon.t option
    ; children : Vdom.Node.t list
    }

  let maybe_icon ~size ~icon =
    match icon with
    | Some icon ->
      {%html.jsx|
        <Bonsai_web_icon.view
          ~attrs:%{[ Styles.icon_left ]}
          ~size:%{Styles.icon_size ~size}
          ~icon
        />
      |}
    | None -> Node.none
  ;;

  let render { children; attrs; icon; disabled; value = _ } ~item_attr ~is_focused ~size =
    let maybe_disabled = if disabled then Attr.disabled else Attr.empty in
    let item_attrs =
      [ Attr.many attrs; item_attr; maybe_disabled; Styles.item_extra_style ]
    in
    {%html.jsx|
      <Private_skyline_listbox.Item.view
        *{item_attrs}
        ~size
        ~is_active:%{is_focused}
        ~is_disabled:%{disabled}
      >
        %{maybe_icon ~size ~icon}
        <div %{Styles.row_content_wrapper}>*{children}</div>
      </>
    |}
  ;;
end

type 'a t =
  { items : 'a Item.t list
  ; size : Skyline_size.t
  ; attrs : Attr.t list
  }

let item ?test_selector ?(attrs = []) ?(disabled = false) ?icon ~value children =
  let attrs = Test_selector.attr_of_opt test_selector :: attrs in
  { Item.value; attrs; disabled; icon; children }
;;

let create ?(attrs = []) ?(size = `Md) items = { items; size; attrs }

let enabled_values t =
  List.filter_map t.items ~f:(fun (item : _ Item.t) ->
    if item.disabled then None else Some item.value)
;;

let all_values t = List.map t.items ~f:(fun (item : _ Item.t) -> item.value)

let view ?(attrs = []) ~is_focused ~item_attr options =
  let { items; size; attrs = create_attrs } = options in
  let children =
    List.map items ~f:(fun (item : _ Item.t) ->
      let is_focused = is_focused item.value in
      let item_attr = item_attr item.value in
      Item.render item ~item_attr ~is_focused ~size)
  in
  {%html.jsx|
    <Private_skyline_listbox.Container.view
      %{Styles.content_wrapper}
      %{Attr.tabindex 0}
      *{create_attrs}
      *{attrs}
    >
      *{children}
    </>
  |}
;;
