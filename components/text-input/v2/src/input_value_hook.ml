open! Core
open! Bonsai_web

(* This handles all the DOM manipulation we need to do for the [html_input_element]. *)
module Element = struct
  open Js_of_ocaml

  type t = Browser_types.html_input_element Js.t

  let of_dom_element (element : Dom_html.element Js.t) : t option =
    let%bind.Option window = Browser_expert.Global.window () in
    Browser_expert.coerce ~to_:window##._HTMLInputElement_t element
  ;;

  let get_dom_value (t : t) = t##.value |> Js.to_string
  let set_dom_value (t : t) (value : string) = t##.value := Js.string value

  let is_active (t : t) : bool =
    match
      let%bind.Option window = Browser_expert.Global.window () in
      window##.document##.activeElement |> Js.Opt.to_option
    with
    | None -> false
    | Some document_active_element ->
      phys_equal (t :> Browser_types.element Js.t) document_active_element
  ;;

  let update_value (t : t) ~event ~parse ~set_value ~last_valid_value value =
    last_valid_value := value;
    (* Don't set the value when not necessary to avoid resetting the cursor. *)
    if not (String.equal value (get_dom_value t)) then set_dom_value t value;
    (* We want to avoid updating the state while the user is typing something that could
       become valid, so we only update on empty strings and strings that parse. *)
    if String.is_empty value || Option.is_some (parse value)
    then
      Effect.Expert.handle
        ~on_exn:raise
        (Browser_extra.Coercion.to_jsoo_event event)
        (set_value value)
  ;;

  let install_change_handler (t : t) ~parse ~set_value ~last_valid_value =
    Browser_extra.add_event_listener_with_cleanup
      t
      ~type_:Browser_extra.Event_type.change
      ~listener:(fun t ~event ->
        let parsed = parse (get_dom_value t) |> Option.value ~default:"" in
        update_value t ~event ~parse ~set_value ~last_valid_value parsed)
  ;;

  let install_input_handler (t : t) ~filter_input ~parse ~set_value ~last_valid_value =
    Browser_extra.add_event_listener_with_cleanup
      t
      ~type_:Browser_extra.Event_type.input
      ~listener:(fun t ~event ->
        let current_value = get_dom_value t in
        match filter_input current_value with
        | true -> update_value t ~event ~parse ~set_value ~last_valid_value current_value
        | false ->
          (* Restore cursor. We only save start because this is post-edit, to get the
             original end we'd need to register a [before_input] listener as well. *)
          let cursor_pos =
            let%map.Option pos = t##.selectionStart |> Js.Opt.to_option in
            Float.max 0. (Js.float_of_number pos -. 1.)
          in
          set_dom_value t !last_valid_value;
          Option.iter cursor_pos ~f:(fun pos ->
            let pos = Js.number_of_float pos in
            t##setSelectionRange ~start:pos ~end_:pos ~direction:Js.undefined))
  ;;
end

module Hook = struct
  module Input = struct
    type t =
      { value : string
      ; set_value : string -> unit Effect.t
      ; parse : string -> string option
      ; filter_input : string -> bool
      }

    let sexp_of_t { value; _ } = Sexp.Atom value
    let combine _left right = right
  end

  module State = struct
    type t =
      { mutable event_listener_ids : Browser_js_types.event_id list
      ; last_valid_value : string ref
      }
  end

  let install_handlers element ~parse ~filter_input ~set_value ~last_valid_value =
    let change_listener_id =
      Element.install_change_handler element ~parse ~set_value ~last_valid_value
    in
    let input_listener_id =
      Element.install_input_handler
        element
        ~filter_input
        ~parse
        ~set_value
        ~last_valid_value
    in
    [ change_listener_id; input_listener_id ]
  ;;

  let remove_handlers handlers =
    List.iter handlers ~f:Browser_js_types.remove_event_listener
  ;;

  let init { Input.value; set_value; parse; filter_input } element =
    match Element.of_dom_element element with
    | None ->
      (* Not a valid [input], do nothing. *)
      { State.event_listener_ids = []; last_valid_value = ref "" }
    | Some element ->
      let last_valid_value = ref value in
      Element.set_dom_value element value;
      let event_listener_ids =
        install_handlers element ~parse ~filter_input ~set_value ~last_valid_value
      in
      { State.event_listener_ids; last_valid_value }
  ;;

  let on_mount = `Do_nothing
  let destroy _input (state : State.t) _element = remove_handlers state.event_listener_ids

  let update
    ~old_input:_
    ~new_input:{ Input.value; set_value; parse; filter_input }
    (state : State.t)
    element
    =
    (* Update the DOM value, but be careful not to fight with user input. *)
    match Element.of_dom_element element with
    | None -> ()
    | Some element ->
      let should_update =
        let current_value = Element.get_dom_value element in
        match Element.is_active element with
        | true ->
          (* When focused, check if the input's current value parses to something
             different than what we want. This allows "1." to persist (parses to "1") *)
          (match parse current_value with
           | Some parsed_current -> not (String.equal parsed_current value)
           | None -> not (String.equal current_value value))
        | false ->
          (* Not focused, always update. *)
          not (String.equal current_value value)
      in
      if should_update
      then (
        Element.set_dom_value element value;
        state.last_valid_value := value);
      (* Always reinstall the event handlers to capture the latest functions *)
      remove_handlers state.event_listener_ids;
      state.event_listener_ids
      <- install_handlers
           element
           ~parse
           ~filter_input
           ~set_value
           ~last_valid_value:state.last_valid_value
  ;;

  include functor Vdom.Attr.Hooks.Make
end

let create
  ?(filter_input = Fn.const true)
  ?(parse = Option.some)
  ~state:(value, set_value)
  ()
  =
  Vdom.Attr.create_hook
    "skyline.input_value_hook"
    (Hook.create { value; set_value; parse; filter_input })
;;
