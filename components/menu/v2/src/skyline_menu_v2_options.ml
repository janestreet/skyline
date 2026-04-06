open! Core
open! Private_skyline_prelude

(* Architecture Note: Config vs State

   This module maintains a separation between two types of data:

   1. CONFIG: Data known at item creation time (when [create items] is called)
      - User-provided styling attrs (config_attrs)
      - Item content (children, icons, items_test_selectors)
      - For submenus: nested listbox container config

   2. STATE: Data known at render time (when [contents'] is called)
      - Which item is currently active (from Bonsai_web_menu state)
      - Hover handlers (to update active state)
      - Click handlers (potentially wrapped with close-on-click)
      - Scroll-to-item selectors
      - Popover positioning (for submenus)

   The data flow is: Config (item creation) → State (rendering with runtime context) →
   Vdom.
*)

module Single_data = struct
  type t =
    { test_selector : Test_selector.t option
    ; config_attrs : Attr.t list (* User-provided styling attrs *)
    ; icon : Bonsai_web_icon.t option
    ; children : size:Skyline_size.t -> Vdom.Node.t list
    }
end

module Item_data = struct
  type t =
    | Single of Single_data.t
    | Inert of (size:Skyline_size.t -> Vdom.Node.t)
    | Submenu of
        { trigger : Single_data.t
        ; container_config_attrs : Attr.t list
        }
end

module Content = struct
  type t = (unit, Item_data.t) Bonsai_web_menu.Item.t
end

type t =
  { wrapper_attrs : Attr.t list
  ; items : (unit, Item_data.t) Bonsai_web_menu.Item.t list
  }

module Styles = struct
  include
    [%css
    stylesheet
      (* This stylesheet ensures items are properly aligned with or without icons. *)
      {|
        @layer skyline-listbox {
          .content_wrapper {
            display: grid;
            grid-template-columns: auto 1fr auto;

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

            .icon_right {
              grid-column: 3;
              margin-left: %{Classes.spacing 1.#Css_gen.Length};
            }

            .full_bleed {
              grid-column: 1 / -1;
            }

            /* Remove left margin when row has no left icon */
            .row:not(:has(> .icon_left)) .icon_left {
              margin-right: 0;
            }

            /* Remove right margin when row has no right icon */
            .row:not(:has(> .icon_right)) .icon_right {
              margin-left: 0;
            }
          }
        }
      |}]

  let row_base ~size =
    let text, padding =
      match size with
      | `Xs ->
        ( Classes.text_2xs
        , {%css|
            padding: %{Classes.spacing 0.25#Css_gen.Length}
              %{Classes.spacing 0.5#Css_gen.Length};
          |}
        )
      | `Sm ->
        ( Classes.text_xs
        , {%css|
            padding: %{Classes.spacing 0.5#Css_gen.Length}
              %{Classes.spacing 1.#Css_gen.Length};
          |}
        )
      | `Md ->
        ( Classes.text_sm
        , {%css|
            padding: %{Classes.spacing 1.#Css_gen.Length}
              %{Classes.spacing 2.#Css_gen.Length};
          |}
        )
      | `Lg ->
        ( Classes.text_base
        , {%css|
            padding: %{Classes.spacing 2.#Css_gen.Length}
              %{Classes.spacing 4.#Css_gen.Length};
          |}
        )
    in
    Attr.many
      [ row
      ; text
      ; padding
      ; {%css|
          text-align: left;
          width: 100%;

          &:focus-visible {
            outline-style: solid;
            outline-width: 1px;
            outline-offset: -1px;
          }
        |}
      ]
  ;;

  let item ~is_active ~is_disabled ~size =
    let bg =
      Attr.many
        (match is_disabled, is_active with
         | true, _ -> [ Classes.bg_one; Classes.text_disabled ]
         | false, true -> [ Classes.bg_three; Classes.text_default ]
         | false, false -> [ Classes.bg_one; Classes.text_default ])
    in
    Attr.many [ row_base ~size; bg ]
  ;;

  let inert_title ~size =
    Attr.many
      [ row_base ~size
      ; Classes.text_secondary
      ; Classes.bg_one
      ; Classes.font_semibold
      ; {%css|
          text-transform: uppercase;
          font-size: 0.75em;
          letter-spacing: 0.025em;
        |}
      ]
  ;;

  let container =
    Attr.many
      [ Classes.border_default
      ; Classes.shadow_md
      ; {%css|
          border-width: 1px;
          border-style: solid;
          border-radius: 4px;
          overflow: hidden;
          padding: 0;
        |}
      ]
  ;;

  let content_wrapper ~size =
    let min_width =
      match size with
      | `Xs -> {%css|min-width: 100px;|}
      | `Sm -> {%css|min-width: 150px;|}
      | `Md -> {%css|min-width: 200px;|}
      | `Lg -> {%css|min-width: 300px;|}
    in
    Attr.many
      [ content_wrapper
      ; min_width
      ; {%css|
          overflow: auto;
          outline: none;
        |}
      ]
  ;;

  let hr ~size =
    let margin =
      match size with
      | `Xs | `Sm -> Classes.spacing 0.25
      | `Md | `Lg -> Classes.spacing 0.5
    in
    Attr.many
      [ full_bleed; Classes.border_default; {%css|margin: %{margin#Css_gen.Length} 0;|} ]
  ;;

  let icon_size ~size =
    match size with
    | `Xs -> `Px 12
    | `Sm -> `Px 14
    | `Md -> `Px 16
    | `Lg -> `Px 18
  ;;
end

module Scroll_selectors = struct
  let attr ~key = Attr.create "data-menu-item" key
  let selector ~path_id ~key = {%string|#%{path_id} [data-menu-item="%{key}"]|}
end

let maybe_icon ?(attrs = []) ~size ~icon () =
  match icon with
  | Some icon -> {%html|<Bonsai_web_icon.view *{attrs} ~size ~icon />|}
  | None -> Node.none
;;

(* Render an item by combining config with state *)
let render_item (config : Single_data.t) ~state_attrs ~is_active ~is_disabled ~size =
  let { Single_data.children; config_attrs; icon; test_selector } = config in
  let is_active_attr =
    if is_active then Attr.create "data-test-is-active" "true" else Attr.empty
  in
  let attrs =
    [ Test_selector.attr_of_opt test_selector
    ; Attr.tabindex (-1)
    ; Attr.many config_attrs
    ; Attr.many state_attrs
    ; Styles.item ~is_active ~is_disabled ~size
    ; is_active_attr
    ]
  in
  let children =
    [ maybe_icon ~attrs:[ Styles.icon_left ] ~size:(Styles.icon_size ~size) ~icon ()
    ; {%html|<div %{Styles.row_content_wrapper}>*{children ~size}</div>|}
    ]
  in
  {%html|<button *{attrs}>*{children}</button>|}
;;

let item ?test_selector ?(attrs = []) ?(disabled = false) ?icon ~key ~on_click children =
  Bonsai_web_menu.Item.Single
    { key
    ; disabled
    ; on_click
    ; item =
        Item_data.Single
          { Single_data.test_selector
          ; config_attrs = attrs
          ; icon
          ; children =
              (fun ~size:_
                (* Size is ignored because this is content from userland and has no use
                   for the ~size arg. *) ->
                children)
          }
    }
;;

let separator ?(attrs = []) () =
  Bonsai_web_menu.Item.Inert
    (Item_data.Inert (fun ~size -> {%html|<hr %{Styles.hr ~size} *{attrs} />|}))
;;

let title ?test_selector ?(attrs = []) children =
  Bonsai_web_menu.Item.Inert
    (Item_data.Inert
       (fun ~size ->
         {%html|
           <div
             %{Styles.inert_title ~size}
             *{attrs}
             %{Test_selector.attr_of_opt test_selector}
           >
             <div %{Styles.row_content_wrapper}>*{children}</div>
           </div>
         |}))
;;

module Sub_menu = struct
  module Trigger = struct
    type t = (unit, Item_data.t) Bonsai_web_menu.Item.t

    let create ?test_selector ?(attrs = []) ?icon children =
      let submenu_trigger_children ~size =
        [ {%html|<div %{Styles.row_content_wrapper}>*{children}</div>|}
        ; {%html|
            <Bonsai_web_icon.view
              ~attrs:%{[ Styles.icon_right ]}
              ~size:%{(Styles.icon_size ~size)}
              ~icon:%{Lucide.chevron_right}
            />
          |}
        ]
      in
      Bonsai_web_menu.Item.Single
        { key =
            ""
            (* [Submenu.Trigger] receives the key from [Submenu.create]. This one will be
               ignored. *)
        ; disabled = false
        ; on_click = Effect.Ignore
        ; item =
            Item_data.Single
              { Single_data.test_selector
              ; config_attrs = attrs
              ; icon
              ; children = (fun ~size -> submenu_trigger_children ~size)
              }
        }
    ;;
  end

  let create ?test_selector ?(attrs = []) items ~key ~trigger =
    Bonsai_web_menu.Item.Submenu
      { key
      ; item =
          (match trigger with
           | Bonsai_web_menu.Item.Single
               { item = Item_data.Single config; key; disabled; on_click } ->
             ignore on_click (* [on_click] is ignored *);
             ignore disabled (* [disabled] is ignored *);
             ignore key (* [key] is ignored. *);
             Item_data.Submenu
               { trigger = config
               ; container_config_attrs = Test_selector.attr_of_opt test_selector :: attrs
               }
           | _ -> assert false)
      ; items
      }
  ;;
end

let create ?(attrs = []) items =
  let items = List.map items ~f:(fun item -> item) in
  { items; wrapper_attrs = attrs }
;;

let on_keydown
  ~close
  ~state
  ~scroll_to_current_item
  (event : Js_of_ocaml.Dom_html.keyboardEvent Js_of_ocaml.Js.t)
  =
  let key_down key =
    Js_of_ocaml.Dom.preventDefault event;
    Js_of_ocaml.Dom_html.stopPropagation event;
    let%bind.Effect () = Bonsai_web_menu.key_down state key in
    scroll_to_current_item
  in
  match Js_of_ocaml.Dom_html.Keyboard_code.of_event event with
  | Escape ->
    Js_of_ocaml.Dom.preventDefault event;
    Js_of_ocaml.Dom_html.stopPropagation event;
    close
  | Enter -> key_down `Enter
  | ArrowUp -> key_down `Up
  | ArrowDown -> key_down `Down
  | ArrowLeft -> key_down `Left
  | ArrowRight -> key_down `Right
  | _ -> Effect.Ignore
;;

let disable_browser_context_menu_within =
  Attr.on_contextmenu (fun event ->
    event##preventDefault;
    Effect.Ignore)
;;

let rec contents'
  ?(config_attrs = [])
  ?items_test_selectors
  ~path_id
  ~set_active_path_rev
  ~current_path_rev
  ~active_path
  ~size
  items
  =
  let is_active (item : (unit, Item_data.t) Bonsai_web_menu.Item.t) =
    match active_path with
    | [] -> false
    | active :: _suffix ->
      (match item with
       | Single { key; _ } | Submenu { key; _ } -> String.equal key active
       | _ -> false)
  in
  let maybe_test_selector_attr items_test_selectors ~key ~current_path_rev =
    match items_test_selectors with
    | Some items_test_selectors ->
      let ts =
        Test_selector.Keyed.get
          items_test_selectors
          (Nonempty_list.reverse (Nonempty_list.create key current_path_rev))
      in
      Test_selector.attr ts
    | None -> Attr.empty
  in
  let children =
    List.map items ~f:(fun child ->
      match (child : (unit, Item_data.t) Bonsai_web_menu.Item.t) with
      | Single { item = Item_data.Single config; key; disabled; on_click } ->
        let maybe_disabled = if disabled then Attr.disabled else Attr.empty in
        let on_click =
          if disabled then Attr.empty else Attr.on_click (fun _ -> on_click)
        in
        let on_mouseenter =
          Attr.on_mouseenter (fun _ -> set_active_path_rev (key :: current_path_rev))
        in
        let maybe_test_selector =
          maybe_test_selector_attr items_test_selectors ~key ~current_path_rev
        in
        let state_attrs =
          [ Scroll_selectors.attr ~key
          ; maybe_disabled
          ; on_click
          ; on_mouseenter
          ; maybe_test_selector
          ]
        in
        render_item
          config
          ~state_attrs
          ~is_active:(is_active child)
          ~is_disabled:disabled
          ~size
      | Single { item = Item_data.Inert _; _ } ->
        (* Inert items should not be in Single *)
        assert false
      | Single { item = Item_data.Submenu _; _ } ->
        (* Submenu items should not be in Single *)
        assert false
      | Inert (Item_data.Inert node) -> node ~size
      | Inert (Item_data.Single _) ->
        (* Single items should not be in Inert *)
        assert false
      | Inert (Item_data.Submenu _) ->
        (* Submenu items should not be in Inert *)
        assert false
      | Section _ -> assert false
      | Submenu
          { items; item = Item_data.Submenu { trigger; container_config_attrs }; key } ->
        let submenu_id = [%string "%{path_id}/%{key}"] in
        let open_submenu = set_active_path_rev (key :: current_path_rev) in
        let submenu_state_attrs =
          match active_path with
          | active_key :: active_path when String.equal key active_key ->
            let safe_triangle =
              if List.is_empty active_path
              then
                Bonsai_web_toplayer_private_vdom.For_bonsai_web_menu.safe_triangle
                  ~submenu_id
              else Attr.empty
            in
            let popover =
              Bonsai_web_toplayer.vdom_popover
                ~popover_attrs:[ Styles.container ]
                ~overflow_auto_wrapper:false
                ~position:Right
                ~alignment:Start
                (contents'
                   ~config_attrs:container_config_attrs
                   ~path_id
                   ~set_active_path_rev
                   ~current_path_rev:(key :: current_path_rev)
                   ~active_path
                   ~size
                   items)
            in
            Attr.combine safe_triangle popover
          | _ -> Attr.empty
        in
        let maybe_test_selector =
          maybe_test_selector_attr items_test_selectors ~key ~current_path_rev
        in
        let on_click = Attr.on_click (fun _ -> open_submenu) in
        let on_mouseenter = Attr.on_mouseenter (fun _ -> open_submenu) in
        let state_attrs =
          [ maybe_test_selector
          ; submenu_state_attrs
          ; on_click
          ; on_mouseenter
          ; Scroll_selectors.attr ~key
          ]
        in
        render_item
          trigger
          ~state_attrs
          ~is_active:(is_active child)
          ~is_disabled:false
          ~size
      | Submenu { item = Item_data.Inert _; _ } | Submenu { item = Item_data.Single _; _ }
        ->
        (* Inert items should not be in Submenu *)
        assert false)
  in
  let attrs = [ Attr.many config_attrs; Styles.content_wrapper ~size; Attr.id path_id ] in
  {%html|<div *{attrs}>*{children}</div>|}
;;

module Expert = struct
  let component
    ?test_selector
    ?items_test_selectors
    ?(size = return `Md)
    ?(focus_on_activate = return false)
    items
    ~close
    (graph @ local)
    =
    let%sub { wrapper_attrs; items } = items in
    let items =
      let%arr close and items in
      List.map items ~f:(fun item ->
        Bonsai_web_menu.Item.map_actions item ~f:(fun on_click ->
          let%bind.Effect () = close in
          on_click))
    in
    let state, reset =
      Bonsai.with_model_resetter ~f:(Bonsai_web_menu.component items) graph
    in
    Bonsai.Edge.lifecycle ~on_deactivate:reset graph;
    let path_id = Bonsai.path_id graph in
    let scroll_to_current_item =
      let%arr path_id
      and state = Bonsai.peek state graph in
      let%bind.Effect state in
      match state with
      | Bonsai.Computation_status.Inactive -> Effect.Ignore
      | Active state ->
        let%bind.Effect active_item = Bonsai_web_menu.active_item state in
        let scroll_effect =
          let%bind.Option active_key =
            match active_item with
            | Some (Bonsai_web_menu.Item.Single { key; _ } | Submenu { key; _ }) ->
              Some key
            | Some (Section _) | Some (Inert _) | None -> None
          in
          let selector = Scroll_selectors.selector ~path_id ~key:active_key in
          let%map.Option element = Private_skyline_dom.Element.get_by_selector selector in
          Private_skyline_dom.Element.scroll_into_view
            ~options:{ block = Nearest; inline = Nearest; behavior = Auto }
            element
        in
        Option.value scroll_effect ~default:Effect.Ignore
    in
    let focus_attr =
      match%sub focus_on_activate with
      | true -> Effect.Focus.on_activate () graph
      | false -> return Attr.empty
    in
    let children =
      let%arr path_id
      and test_selector = Bonsai.transpose_opt test_selector
      and items_test_selectors = Bonsai.transpose_opt items_test_selectors
      and items
      and wrapper_attrs
      and state
      and close
      and scroll_to_current_item
      and size
      and focus_attr in
      let on_keydown =
        Attr.on_keydown (on_keydown ~close ~state ~scroll_to_current_item)
      in
      let state_attrs =
        [ disable_browser_context_menu_within
        ; on_keydown
        ; focus_attr
        ; Attr.tabindex 0
        ; Test_selector.attr_of_opt test_selector
        ]
      in
      (* Combine config attrs (user-provided) with state attrs (runtime) *)
      let all_attrs = Attr.many wrapper_attrs :: state_attrs in
      contents'
        ?items_test_selectors
        ~config_attrs:all_attrs
        ~path_id
        ~set_active_path_rev:(fun path ->
          Bonsai_web_menu.set_active_path state (List.rev path))
        ~current_path_rev:[]
        ~active_path:(Bonsai_web_menu.active_path state)
        ~size
        items
    in
    children
  ;;
end

module For_docs = struct
  let ml_filepath = __FILE__
end
