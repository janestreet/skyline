open! Core
open! Private_skyline_prelude
module Focusable_list = Bonsai_web_focusable_list

(** We use data attrs to implement scroll-into-view behavior rather than passing around
    dom refs. *)
module Scroll_selectors = struct
  let owner_attr = "data-typeahead-scroll-owner"
  let index_attr = "data-typeahead-scroll-index"

  let item_attr ~owner ~index =
    Attr.many
      [ Attr.create owner_attr owner; Attr.create index_attr (Int.to_string index) ]
  ;;

  let selector ~owner ~index =
    [%string "[%{owner_attr}=\"%{owner}\"][%{index_attr}=\"%{index#Int}\"]"]
  ;;
end

module Selection_mode = struct
  type ('a, 'selection, 'on_select_payload) t =
    | Single_ux :
        { comparator :
            (module Comparator.S with type t = 'a and type comparator_witness = 'cmp)
        }
        -> ('a, 'a option, 'a option) t
    | Effect_only : ('a, unit, 'a) t
    | Multi_ux :
        { comparator :
            (module Comparator.S with type t = 'a and type comparator_witness = 'cmp)
        }
        -> ('a, 'a list, 'a list) t

  type ('a, 'selection) packed = T : ('a, 'selection, _) t -> ('a, 'selection) packed

  let single_ux comparator = Single_ux { comparator }
  let multi_ux comparator = Multi_ux { comparator }
end

type ('a, 'selection) t =
  { query : string
  ; selected : 'selection
  ; set_selected : 'selection -> unit Effect.t
  ; to_string : 'a -> string
  ; is_open : bool
  ; open_ : unit Effect.t
  ; close : unit Effect.t
  ; set_query_and_open : string -> unit Effect.t
  ; set_query_input_only : string -> unit Effect.t
  ; set_query_data_only : string -> unit Effect.t
  ; select_item : 'a option -> unit Effect.t
  ; deselect_item : 'a -> unit Effect.t
  ; deselect_last : unit Effect.t
  ; suggestions : 'a list
  ; focusable_list : int Focusable_list.t
  ; item_attr : int -> Vdom.Attr.t
  ; inject_focus : int Focusable_list.Action.t -> int option Effect.t
  ; render_suggestion : 'a -> highlight:(string -> Highlighted_splits.t) -> Vdom.Node.t
  ; highlight : string -> Highlighted_splits.t
  ; for_combobox_anchor : Vdom.Attr.t
  ; combobox_input_state : string * (string -> unit Effect.t)
  ; for_combobox_input :
      on_backspace_when_empty:unit Effect.t
      -> on_arrow_left_at_start:unit Effect.t option
      -> tab_selects_current_item:bool
      -> Vdom.Attr.t
  ; focus_combobox_input : unit Effect.t
  ; for_select_anchor : Vdom.Attr.t
  ; selection_mode : ('a, 'selection) Selection_mode.packed
  ; path_id : string
  }

let state t = t.selected, t.set_selected

module Private = struct
  let to_string t = t.to_string
  let deselect_item t = t.deselect_item
  let selection_mode t = t.selection_mode
  let for_combobox_anchor t = t.for_combobox_anchor
  let combobox_input_state t = t.combobox_input_state

  let for_combobox_input
    ~on_backspace_when_empty
    ?on_arrow_left_at_start
    ?(tab_selects_current_item = false)
    t
    =
    t.for_combobox_input
      ~on_backspace_when_empty
      ~on_arrow_left_at_start
      ~tab_selects_current_item
  ;;

  let focus_combobox_input t = t.focus_combobox_input
  let for_select_anchor t = t.for_select_anchor
  let path_id t = t.path_id
  let deselect_last t = t.deselect_last
end

module Selection_checkbox = struct
  let checkbox_size_for_suggestion_size = function
    | `Xs -> `Xs
    | `Sm -> `Sm
    | `Md | `Lg ->
      (* We map [`Md] to [`Lg] just because we think the Lg checkbox looks a bit better
         next to the Md text that [Private_skyline_listbox.Item] uses internally. *)
      `Lg
  ;;

  (** An inert checkbox. Not clickable or interactable at all. *)
  let view ~suggestion_size ~checked () =
    let size = checkbox_size_for_suggestion_size suggestion_size in
    let state = checked, fun (_ : bool) -> Effect.Ignore in
    {%html|
      <Skyline_field_v2.view
        ~size
        ~intent:%{`Primary}
        style="pointer-events: none"
      >
        <Skyline_checkbox_input_v2.content ~state style="line-height: 1em" />
      </>
    |}
  ;;
end

(** Renders suggestion items as a [Vdom.Node.t list]. Shared by the interactive-anchor and
    static-anchor popover bodies to avoid duplicating item rendering logic. *)
let render_suggestion_items
  ?is_multi_selected
  ~suggestions
  ~focusable_list
  ~path_id
  ~item_attr
  ~render_suggestion
  ~highlight
  ~on_select_item
  ~size
  ()
  =
  let focusable = Focusable_list.focusable focusable_list in
  List.mapi suggestions ~f:(fun index item ->
    let is_active =
      match focusable with
      | Some id -> id = index
      | None -> false
    in
    let on_click _ = on_select_item item in
    let on_mousedown (evt : Js_of_ocaml.Dom_html.mouseEvent Js_of_ocaml.Js.t) =
      evt##preventDefault;
      Effect.Ignore
    in
    let content =
      match is_multi_selected with
      | None -> render_suggestion item ~highlight
      | Some is_multi_selected ->
        {%html|
          <div style="display: flex; align-items: center; gap: 8px">
            <Selection_checkbox.view
              ~checked:%{is_multi_selected item}
              ~suggestion_size:%{size}
            />
            %{render_suggestion item ~highlight}
          </div>
        |}
    in
    {%html|
      <Private_skyline_listbox.Item.view
        ~size
        ~is_active:%{is_active}
        ~is_disabled:%{false}
        *{[ Scroll_selectors.item_attr ~owner:path_id ~index
           ; item_attr index
           ; Attr.on_click on_click
           ; Attr.on_mousedown on_mousedown
           ]}
      >
        %{content}
      </>
    |})
;;

let compact_spacing_for_size = function
  | `Xs -> `Px 1
  | `Sm -> `Px 2
  | `Md | `Lg -> `Px 4
;;

let suggestion_list_gap = function
  | `Xs | `Sm -> `Px 0
  | `Md | `Lg -> `Px 4
;;

let suggestion_list_style ~size =
  let gap = suggestion_list_gap size in
  let padding_bottom = compact_spacing_for_size size in
  [%css
    {|
      display: flex;
      flex-direction: column;
      flex: 1 1 auto;
      min-height: 0;
      overflow-y: auto;
      gap: %{gap#Css_gen.Length};
      padding-bottom: %{padding_bottom#Css_gen.Length};
    |}]
;;

let select_search_input_wrapper_style ~size =
  let padding = compact_spacing_for_size size in
  [%css {|padding: %{padding#Css_gen.Length};|}]
;;

(** The popover open/close state for the typeahead controller. *)
let open_state ?controlled_state (local_ graph) =
  let is_open, set_open =
    match controlled_state with
    | Some (is_open, set_open) -> is_open, set_open
    | None -> Bonsai.state false graph
  in
  let open_ =
    let%arr set_open in
    set_open true
  in
  let close =
    let%arr set_open in
    set_open false
  in
  ~is_open, ~open_, ~close, ~set_open
;;

let keeps_popover_open
  : type a selection on_select_payload.
    (a, selection, on_select_payload) Selection_mode.t -> bool
  = function
  | Single_ux _ | Effect_only -> false
  | Multi_ux _ -> true
;;

module Input_state = struct
  module Action = struct
    type ('a, 'selection) t =
      | Set_query of string
      | Set_query_input_only of string
      | Set_query_data_only of string
      | Set_selected of 'selection
      | Select_item of 'a option
      | Deselect_item of 'a
      | Reset_query_to_selection
      (** Reset the query state in preparation for a fresh user search session.
          [input_query] is set to the display text of [model.selected] (so the input shows
          the committed label) and [data_query] is intentionally reset to [""] regardless
          of [selected] so that re-opening the picker shows all suggestions rather than a
          stale filter. The two queries therefore diverge whenever anything is selected. *)
    [@@deriving sexp_of]
  end

  module Model = struct
    type 'selection t =
      { (* We store 2 copies of the query because sometimes they need to diverge: we may
           show one string in the UI, but use another for computing the suggestions. A few
           cases where we do this:
           1. After selecting an item, when the popover is re-opened we want [data_query]
              to be [""] so that there isn't just a single exact-match suggestion.
           2. When navigating up/down in the focusable list, we update the [input_query]
              only. *)
        input_query : string
      ; data_query : string
      ; selected : 'selection
      }
    [@@deriving sexp_of, equal]
  end

  module Selection_ops = struct
    type ('a, 'selection, 'on_select_payload) t =
      { empty : 'selection
      ; update_with_item : current:'selection -> 'a option -> 'selection
      ; deselect_item : current:'selection -> 'a -> 'selection
      ; display_text : 'selection -> string
      ; on_select_payload_of_select :
          item:'a option -> new_selection:'selection -> 'on_select_payload option
      ; on_select_payload_of_deselect :
          new_selection:'selection -> 'on_select_payload option
      }
  end

  type ('a, 'selection) t =
    { selected : 'selection Bonsai.t
    ; input_query : string Bonsai.t
    ; data_query : string Bonsai.t
    ; set_query_and_open_picker : (string -> unit Effect.t) Bonsai.t
    ; set_query_input_only : (string -> unit Effect.t) Bonsai.t
    ; set_query_data_only : (string -> unit Effect.t) Bonsai.t
    ; set_selected : ('selection -> unit Effect.t) Bonsai.t
    ; select_item : ('a option -> unit Effect.t) Bonsai.t
    ; deselect_item : ('a -> unit Effect.t) Bonsai.t
    ; reset_query_to_selection : unit Effect.t Bonsai.t
    }

  let create
    (type item selection on_select_payload)
    ~(selection_mode : (item, selection, on_select_payload) Selection_mode.t)
    ?state:controlled_state
    ~open_
    ~close
    ~on_select
    ~(to_string : item -> string)
    (local_ graph)
    =
    let selection_ops : (item, selection, on_select_payload) Selection_ops.t =
      match selection_mode with
      | Single_ux _ ->
        { empty = None
        ; update_with_item = (fun ~current:_ item -> item)
        ; deselect_item = (fun ~current:_ _ -> None)
        ; display_text =
            (fun selection ->
              Option.map selection ~f:to_string |> Option.value ~default:"")
        ; on_select_payload_of_select = (fun ~item:_ ~new_selection -> Some new_selection)
        ; on_select_payload_of_deselect = (fun ~new_selection -> Some new_selection)
        }
      | Effect_only ->
        { empty = ()
        ; update_with_item = (fun ~current:_ _ -> ())
        ; deselect_item = (fun ~current:_ _ -> ())
        ; display_text = (fun () -> "")
        ; on_select_payload_of_select = (fun ~item ~new_selection:_ -> item)
        ; on_select_payload_of_deselect = (fun ~new_selection:_ -> None)
        }
      | Multi_ux { comparator = comparator_m; _ } ->
        let module C = (val comparator_m) in
        let compare a b = Base.Comparator.compare C.comparator a b in
        let mem list item = List.exists list ~f:(fun x -> compare x item = 0) in
        { empty = []
        ; update_with_item =
            (fun ~current item ->
              match item with
              | None -> current
              | Some item ->
                if mem current item
                then List.filter current ~f:(fun x -> compare x item <> 0)
                else current @ [ item ])
        ; deselect_item =
            (fun ~current item -> List.filter current ~f:(fun x -> compare x item <> 0))
        ; display_text = (fun (_ : _ list) -> "")
        ; on_select_payload_of_select = (fun ~item:_ ~new_selection -> Some new_selection)
        ; on_select_payload_of_deselect = (fun ~new_selection -> Some new_selection)
        }
    in
    let state, inject =
      Bonsai.state_machine
        ~default_model:
          { Model.input_query = ""; data_query = ""; selected = selection_ops.empty }
        ~apply_action:(fun _ctx model (action : (item, selection) Action.t) ->
          match action with
          | Set_query query -> { model with input_query = query; data_query = query }
          | Set_query_input_only query -> { model with input_query = query }
          | Set_query_data_only query -> { model with data_query = query }
          | Set_selected selected ->
            let input_query = selection_ops.display_text selected in
            { input_query; data_query = ""; selected }
          | Select_item item ->
            let selected = selection_ops.update_with_item ~current:model.selected item in
            let input_query = selection_ops.display_text selected in
            { input_query; data_query = ""; selected }
          | Deselect_item item ->
            let selected = selection_ops.deselect_item ~current:model.selected item in
            let input_query = selection_ops.display_text selected in
            { model with input_query; selected }
          | Reset_query_to_selection ->
            { model with
              input_query = selection_ops.display_text model.selected
            ; data_query = ""
            })
        graph
    in
    let%sub { selected; input_query; data_query; _ } = state in
    (* Controlled-selection sync, external -> internal only. The reverse direction is
       manually wired into the effect APIs below. *)
    let set_controlled : (selection -> unit Effect.t) Bonsai.t =
      match controlled_state with
      | None -> Bonsai.return (fun (_ : selection) -> Effect.Ignore)
      | Some (controlled_selected, set_controlled) ->
        let equal_selection : selection -> selection -> bool =
          match selection_mode with
          | Single_ux { comparator = comparator_m; _ } ->
            let module C = (val comparator_m) in
            Option.equal (Comparable.equal (Base.Comparator.compare C.comparator))
          | Effect_only -> Unit.equal
          | Multi_ux { comparator = comparator_m; _ } ->
            let module C = (val comparator_m) in
            List.equal (Comparable.equal (Base.Comparator.compare C.comparator))
        in
        Bonsai.Edge.on_change
          ~trigger:`Before_display
          ~equal:equal_selection
          controlled_selected
          ~callback:
            (let%arr inject in
             fun new_selected -> inject (Set_selected new_selected))
          graph;
        set_controlled
    in
    let set_query_input_only =
      let%arr inject in
      fun new_query -> inject (Set_query_input_only new_query)
    in
    let set_query_data_only =
      let%arr inject in
      fun new_query -> inject (Set_query_data_only new_query)
    in
    let set_selected =
      let%arr inject and set_controlled in
      fun selected ->
        let%bind.Effect () = set_controlled selected in
        inject (Set_selected selected)
    in
    let select_item =
      let%arr inject and close and on_select and state and set_controlled in
      fun item ->
        let new_selection =
          selection_ops.update_with_item ~current:state.Model.selected item
        in
        let on_select_effect =
          match selection_ops.on_select_payload_of_select ~item ~new_selection with
          | None -> Effect.Ignore
          | Some payload -> on_select payload
        in
        let close_effect =
          if keeps_popover_open selection_mode then Effect.Ignore else close
        in
        let%bind.Effect () = set_controlled new_selection in
        Effect.Many [ inject (Select_item item); close_effect; on_select_effect ]
    in
    let deselect_item =
      let%arr inject and on_select and state and set_controlled in
      fun item ->
        let new_selection =
          selection_ops.deselect_item ~current:state.Model.selected item
        in
        let on_select_effect =
          match selection_ops.on_select_payload_of_deselect ~new_selection with
          | None -> Effect.Ignore
          | Some payload -> on_select payload
        in
        let%bind.Effect () = set_controlled new_selection in
        Effect.Many [ inject (Deselect_item item); on_select_effect ]
    in
    let set_query_and_open_picker =
      let%arr inject and open_ in
      fun new_query -> Effect.Many [ inject (Set_query new_query); open_ ]
    in
    let reset_query_to_selection =
      let%arr inject in
      inject Reset_query_to_selection
    in
    { selected
    ; input_query
    ; data_query
    ; set_query_and_open_picker
    ; set_query_input_only
    ; set_query_data_only
    ; set_selected
    ; select_item
    ; deselect_item
    ; reset_query_to_selection
    }
  ;;
end

module Highlighted_splits = Highlighted_splits

let component
  (type item selection on_select_payload)
  ~(selection_mode : (item, selection, on_select_payload) Selection_mode.t)
  ?state
  ?open_state:controlled_open_state
  ?(on_select = Bonsai.return (fun (_ : on_select_payload) -> Effect.Ignore))
  ?(size = Bonsai.return (`Md : Skyline_size.t))
  ~(to_string : item -> string)
  ~data:(data_source : item Typeahead_data_source.t)
  ?render_suggestion
  ?render_popover_contents
  (local_ graph)
  =
  let render_popover_contents =
    Option.value render_popover_contents ~default:(Bonsai.return Fn.id)
  in
  let render_suggestion =
    Option.value
      render_suggestion
      ~default:
        (Bonsai.return (fun item ~highlight ->
           highlight (to_string item) |> Highlighted_splits.view))
  in
  let ~is_open, ~open_, ~close, ~set_open =
    open_state ?controlled_state:controlled_open_state graph
  in
  let%tydi { selected
           ; input_query
           ; data_query
           ; set_query_and_open_picker
           ; set_query_input_only
           ; set_query_data_only
           ; set_selected
           ; select_item
           ; deselect_item
           ; reset_query_to_selection
           }
    =
    Input_state.create
      ~selection_mode
      ?state
      ~open_
      ~close
      ~on_select
      ~to_string
      (local_ graph)
  in
  let suggestions =
    let items = data_source ~query_for_suggestions:data_query graph in
    let%arr items and is_open in
    if is_open then items else []
  in
  let path_id = Bonsai.path_id graph in
  let combobox_input_focus = Effect.Focus.on_effect () graph in
  let focusable_list, inject_focus =
    let suggestion_ids =
      let%arr suggestions in
      Iarray.init (List.length suggestions) ~f:Fn.id
    in
    Focusable_list.create ~wrap_around:(return true) (module Int) suggestion_ids graph
  in
  let item_attr = Focusable_list.item_attr focusable_list in
  let focused_suggestion_index = Bonsai.map focusable_list ~f:Focusable_list.focusable in
  let () =
    match Am_running_how_js.(am_in_browser_like_api am_running_how) with
    | false -> ()
    | true ->
      Bonsai.Edge.on_change
        ~trigger:`After_display
        (Bonsai.both is_open focused_suggestion_index)
        ~equal:[%equal: bool * int option]
        ~callback:
          (let%arr path_id in
           fun (is_open, focused_suggestion_index) ->
             match is_open, focused_suggestion_index with
             | true, Some focused_suggestion_index ->
               let selector =
                 Scroll_selectors.selector ~owner:path_id ~index:focused_suggestion_index
               in
               let scroll_effect =
                 let%map.Option element =
                   Private_skyline_dom.Element.get_by_selector selector
                 in
                 Private_skyline_dom.Element.scroll_into_view
                   ~options:{ block = Nearest; inline = Nearest; behavior = Auto }
                   element
               in
               Option.value scroll_effect ~default:Effect.Ignore
             | _ -> Effect.Ignore)
        graph
  in
  let highlight =
    let%arr input_query in
    Highlighted_splits.of_string ~needle:input_query
  in
  let is_multi_selected =
    match selection_mode with
    | Single_ux _ | Effect_only -> Bonsai.return None
    | Multi_ux { comparator = comparator_m; _ } ->
      let module C = (val comparator_m) in
      let compare a b = Base.Comparator.compare C.comparator a b in
      let%arr selected in
      Some (fun item -> List.exists selected ~f:(fun x -> compare x item = 0))
  in
  (* Combobox-style UX: the text input is in the anchor. Uses [Combobox_popover] which has
     some extra UX for this. *)
  let for_combobox_anchor =
    Combobox_popover.component
      ~is_open
      ~close
      ~content:(fun _graph ->
        let%arr suggestions
        and select_item
        and focusable_list
        and item_attr
        and highlight
        and render_suggestion
        and path_id
        and is_multi_selected
        and render_popover_contents
        and size in
        let suggestions_list =
          if List.is_empty suggestions
          then Node.none
          else (
            let items =
              render_suggestion_items
                ?is_multi_selected
                ~suggestions
                ~focusable_list
                ~path_id
                ~item_attr
                ~render_suggestion
                ~highlight
                ~on_select_item:(fun item -> select_item (Some item))
                ~size
                ()
            in
            {%html|
              <div %{Focusable_list.container_attr focusable_list} %{suggestion_list_style ~size}>
                *{items}
              </div>
            |})
        in
        {%html|
          <Private_skyline_listbox.Container.view
            style="display: flex; flex-direction: column; overflow: hidden"
          >
            %{render_popover_contents suggestions_list}
          </>
        |})
      graph
  in
  let static_anchor_attr =
    Skyline_popover_v2.component'
      ~state:(is_open, set_open)
      ~position:(return Skyline_popover_v2.Position.Bottom)
      ~alignment:(return Skyline_popover_v2.Alignment.Start)
      ~match_anchor_side_length:
        (return Skyline_popover_v2.Match_anchor_side.Grow_to_match)
      ~focus_on_show:(return true)
      ~close_on_click_outside:(return true)
        (* We don't need [~hide] because it's the same as [close]. *)
      (fun ~hide:_ _graph ->
        let popover_close = close in
        let keeps_popover_open = keeps_popover_open selection_mode in
        let%arr controller_suggestions = suggestions
        and controller_focusable_list = focusable_list
        and controller_inject_focus = inject_focus
        and controller_select_item = select_item
        and controller_input_query = input_query
        and controller_set_query_and_open = set_query_and_open_picker
        and controller_render_suggestion = render_suggestion
        and controller_highlight = highlight
        and controller_path_id = path_id
        and controller_item_attr = item_attr
        and controller_is_multi_selected = is_multi_selected
        and controller_render_popover_contents = render_popover_contents
        and controller_size = size
        and popover_close in
        let close_if_needed =
          if keeps_popover_open then Effect.Ignore else popover_close
        in
        let on_keydown (evt : Js_of_ocaml.Dom_html.keyboardEvent Js_of_ocaml.Js.t) =
          match Js_of_ocaml.Dom_html.Keyboard_code.of_event evt with
          | ArrowDown ->
            evt##preventDefault;
            controller_inject_focus Focusable_list.Action.Next |> Effect.ignore_m
          | ArrowUp ->
            evt##preventDefault;
            controller_inject_focus Focusable_list.Action.Prev |> Effect.ignore_m
          | Enter | NumpadEnter ->
            evt##preventDefault;
            (match Focusable_list.focusable controller_focusable_list with
             | None -> Effect.Ignore
             | Some idx ->
               (match List.nth controller_suggestions idx with
                | None -> Effect.Ignore
                | Some item ->
                  Effect.Many [ controller_select_item (Some item); close_if_needed ]))
          | Escape ->
            evt##preventDefault;
            popover_close
          | _ -> Effect.Ignore
        in
        let suggestions_list =
          if List.is_empty controller_suggestions
          then Node.none
          else (
            let items =
              render_suggestion_items
                ?is_multi_selected:controller_is_multi_selected
                ~suggestions:controller_suggestions
                ~focusable_list:controller_focusable_list
                ~path_id:controller_path_id
                ~item_attr:controller_item_attr
                ~render_suggestion:controller_render_suggestion
                ~highlight:controller_highlight
                ~on_select_item:(fun item ->
                  Effect.Many [ controller_select_item (Some item); close_if_needed ])
                ~size:controller_size
                ()
            in
            {%html|
              <div
                %{Focusable_list.container_attr controller_focusable_list}
                %{suggestion_list_style ~size:controller_size}
              >
                *{items}
              </div>
            |})
        in
        {%html|
          <Private_skyline_listbox.Container.view
            style="display: flex; flex-direction: column; overflow: hidden"
          >
            <div %{select_search_input_wrapper_style ~size:controller_size}>
              <Skyline_field_v2.view ~size:%{controller_size} ~intent:%{`Primary}>
                <Skyline_text_input_v2.content
                  %{Attr.autofocus true}
                  %{Attr.on_keydown on_keydown}
                  style="min-width: 14ch"
                  ~placeholder:%{"Search..."}
                  ~state:%{( controller_input_query
                           , controller_set_query_and_open
                           )}
              /></>
            </div>
            %{controller_render_popover_contents suggestions_list}
          </>
        |})
      graph
  in
  let deselect_last : unit Effect.t Bonsai.t =
    match selection_mode with
    | Single_ux _ ->
      let%arr select_item in
      select_item None
    | Effect_only -> Bonsai.return Effect.Ignore
    | Multi_ux _ ->
      let%arr selected and deselect_item in
      (match List.last selected with
       | None -> Effect.Ignore
       | Some item -> deselect_item item)
  in
  let%arr for_combobox_anchor
  and static_anchor_attr
  and open_
  and close
  and is_open
  and suggestions
  and focusable_list
  and item_attr
  and inject_focus
  and input_query
  and set_query_input_only
  and set_query_data_only
  and set_query_and_open_picker
  and selected
  and set_selected
  and select_item
  and deselect_item
  and deselect_last
  and render_suggestion
  and highlight
  and path_id
  and reset_query_to_selection
  and combobox_input_focus in
  let { Skyline_popover_v2.anchor = static_popover_anchor; is_open = _; set_is_open = _ } =
    static_anchor_attr
  in
  let combobox_input_state = input_query, set_query_and_open_picker in
  let focused_suggestion =
    (* [suggestions] is [[]] while the popover is closed, so this is [None] unless the
       popover is open. *)
    Option.bind (Focusable_list.focusable focusable_list) ~f:(List.nth suggestions)
  in
  let for_combobox_input
    ~on_backspace_when_empty
    ~on_arrow_left_at_start
    ~tab_selects_current_item
    =
    let set_input_query_to ~focused_idx =
      match focused_idx with
      | None -> Effect.Ignore
      | Some idx ->
        (match List.nth suggestions idx with
         | None -> Effect.Ignore
         | Some item -> set_query_input_only (to_string item))
    in
    let on_keydown (evt : Js_of_ocaml.Dom_html.keyboardEvent Js_of_ocaml.Js.t) =
      match Js_of_ocaml.Dom_html.Keyboard_code.of_event evt with
      | ArrowDown ->
        evt##preventDefault;
        if is_open
        then (
          let%bind.Effect focused_idx =
            inject_focus Bonsai_web_focusable_list.Action.Next
          in
          set_input_query_to ~focused_idx)
        else open_
      | ArrowUp ->
        evt##preventDefault;
        if is_open
        then (
          let%bind.Effect focused_idx =
            inject_focus Bonsai_web_focusable_list.Action.Prev
          in
          set_input_query_to ~focused_idx)
        else open_
      | ArrowLeft ->
        (match on_arrow_left_at_start with
         | None -> Effect.Ignore
         | Some effect ->
           let cursor_at_start =
             match
               Js_of_ocaml.Js.Opt.(
                 to_option (bind evt##.target Js_of_ocaml.Dom_html.CoerceTo.input))
             with
             | None -> false
             | Some input -> input##.selectionStart = 0 && input##.selectionEnd = 0
           in
           (match cursor_at_start with
            | false -> Effect.Ignore
            | true ->
              evt##preventDefault;
              effect))
      | Enter | NumpadEnter ->
        if is_open
        then (
          evt##preventDefault;
          match focused_suggestion with
          | None -> Effect.Ignore
          | Some item -> select_item (Some item))
        else Effect.Ignore
      | Escape ->
        evt##preventDefault;
        if is_open then close else select_item None
      | Backspace ->
        if String.is_empty input_query then on_backspace_when_empty else Effect.Ignore
      | Tab ->
        (* Like Enter, Tab commits the focused suggestion, but doesn't call
           [preventDefault] as aggressively as Enter. *)
        let tab_should_select =
          (* Shift+Tab means "go back"; it should never commit a selection. *)
          tab_selects_current_item && not (Js_of_ocaml.Js.to_bool evt##.shiftKey)
        in
        (match focused_suggestion with
         | Some item when tab_should_select ->
           evt##preventDefault;
           Effect.Many
             [ select_item (Some item)
             ; (* [select_item] already closes the popover in single-select modes, but
                  [Multi_ux] keeps it open. Closing ensures the next Tab has nothing to
                  commit and falls through to normal focus navigation, rather than
                  trapping the user in the input. *)
               close
             ]
         | Some _ | None -> Effect.Ignore)
      | _ -> Effect.Ignore
    in
    let on_click _ = if not is_open then open_ else Effect.Ignore in
    let on_blur _evt =
      (* We interpret a blur as the end of a user session, and call
         [reset_query_to_selection] to update the text input contents and prepare for a
         potential next session. *)
      Effect.Many [ close; reset_query_to_selection ]
    in
    Attr.many
      [ Attr.on_keydown on_keydown
      ; Attr.on_click on_click
      ; Attr.on_blur on_blur
      ; combobox_input_focus.attr
      ]
  in
  let for_select_anchor =
    Attr.many
      [ static_popover_anchor
      ; Attr.on_click (fun _ ->
          Effect.Many
            [ open_
            ; (* We intentionally reset only [data_query] so that when the picker reopens
                 all suggestions are shown, [input_query] is preserved so the search field
                 is pre-filled with the previous text. This way the user can immediately
                 refine their query without retyping it. *)
              set_query_data_only ""
            ])
      ]
  in
  { query = input_query
  ; selected
  ; set_selected
  ; to_string
  ; is_open
  ; open_
  ; close
  ; set_query_and_open = set_query_and_open_picker
  ; set_query_input_only
  ; set_query_data_only
  ; select_item
  ; deselect_item
  ; deselect_last
  ; suggestions
  ; focusable_list
  ; item_attr
  ; inject_focus
  ; render_suggestion
  ; highlight
  ; for_combobox_anchor
  ; combobox_input_state
  ; for_combobox_input
  ; focus_combobox_input = combobox_input_focus.focus
  ; for_select_anchor
  ; selection_mode = Selection_mode.T selection_mode
  ; path_id
  }
;;

module For_testing = struct
  let query t = t.query
  let open_ t = t.open_
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
