open! Core
open! Private_skyline_prelude

module Style = struct
  (* Primary styles for the outer-most element. *)
  let chrome =
    Classes.[ w_full; text_default; border 1; border_solid; border_default; bg_input ]
  ;;

  let input size =
    let text_size =
      match size with
      | `Xs -> Classes.text_xs
      | `Sm | `Md | `Lg -> Classes.text_sm
    in
    [ text_size
    ; {%css|
        outline: none;
        &::placeholder {
          color: %{Css_gen.Color.to_string_css Colors.Text.input_placeholder};
        }
      |}
    ]
  ;;

  let container_size
    =
    (* Set the size via min-height to dodge border issues like [Skyline_button_v2]. *)
    (* NOTE: The container is responsible for vertically centering contents. *)
    function
    | `Xs -> Classes.[ min_h 4.5; Classes.px 0.5; Classes.rounded_xs ]
    | `Sm -> Classes.[ min_h 6.; Classes.px 1.; Classes.rounded_xs ]
    | `Md -> Classes.[ min_h 7.; Classes.px 2.; Classes.rounded_sm ]
    | `Lg -> Classes.[ min_h 8.; Classes.px 2.; Classes.rounded_md ]
  ;;

  let border_color ~disabled intent =
    if disabled
    then Classes.border_default
    else (
      match intent with
      | `Primary -> Classes.border_default
      | `Danger -> Classes.border_danger
      | `Success -> Classes.border_success
      | `Warning -> Classes.border_warning)
  ;;

  let focus_color (intent : Skyline_field_v2.Intent.t) =
    let border, shadow =
      match intent with
      | `Primary -> Colors.Border.primary, Colors.Shadow.primary
      | `Danger -> Colors.Border.danger, Colors.Shadow.danger
      | `Success -> Colors.Border.success, Colors.Shadow.success
      | `Warning -> Colors.Border.warning, Colors.Shadow.warning
    in
    Attr.many
      [ {%css|
          @media not (prefers-reduced-motion: reduce) {
            transition: box-shadow 150ms ease-in-out;
          }
          &.for-testing--force-focus-within,
          /* focus-within includes itself along with dependents, so we can use it for both
            the composite view and the default. */
            &:focus-within {
            background-color: %{Colors.Background.input_active#Css_gen.Color};
            border-color: %{border#Css_gen.Color};
            box-shadow: 0 0 0 3px %{shadow#Css_gen.Color};
          }
        |}
      ]
  ;;

  let disabled = Attr.many Classes.[ bg_input_disabled; text_input_placeholder ]
end

module Elements = struct
  let input ?test_selector ?key ?placeholder ?(attrs = []) ~disabled () =
    let attrs = [ Test_selector.attr_of_opt test_selector; Attr.many attrs ] in
    let placeholder =
      match placeholder with
      | None -> Attr.empty
      | Some placeholder -> Attr.placeholder placeholder
    in
    let maybe_disabled_attr = if disabled then Classes.disabled else Attr.empty in
    {%html|
      <input
        *{attrs}
        ?key
        %{placeholder}
        %{maybe_disabled_attr}
        type="text"
      />
    |}
  ;;
end

let content' ?test_selector ?placeholder ?(attrs = []) ?(error = Ok ()) ~input_attrs () =
  Skyline_field_v2.Content.make' (fun ~size ~intent ~disabled ->
    let attrs =
      [ Attr.many (Style.input size)
      ; Attr.many Style.chrome
      ; Attr.many (Style.container_size size)
      ; Style.border_color ~disabled intent
      ; Style.focus_color intent
      ; (if disabled then Style.disabled else Attr.empty)
      ; Attr.many input_attrs
      ; Attr.many attrs
      ]
    in
    Elements.input ?test_selector ?placeholder ~attrs ~disabled (), error)
;;

let content ?test_selector ?attrs ?placeholder ~state () =
  let value, set_value = state in
  let input_attrs =
    [ Attr.value value; Attr.on_input (fun _ new_value -> set_value new_value) ]
  in
  content' ?test_selector ?placeholder ?attrs ~input_attrs ()
;;

module Composite = struct
  module Content = struct
    type t =
      size:Skyline_size.t -> intent:Skyline_field_v2.Intent.t -> disabled:bool -> Node.t

    module Expert = struct
      let make f : t = f
    end
  end

  let icon ?(attrs = []) ?color ~icon () : Content.t =
    fun ~size ~intent:_ ~disabled ->
    let icon_size =
      match size with
      | `Xs -> Font.size_xs
      | `Sm | `Md | `Lg -> Font.size_sm
    in
    let color =
      match color with
      | Some color -> color ~disabled
      | None -> if disabled then Colors.Text.secondary else Colors.Text.default
    in
    Bonsai_web_icon.view ~size:icon_size ~color ~attrs ~icon ()
  ;;

  let input ?test_selector ?key ?(attrs = []) ?placeholder ~state () : Content.t =
    let value, set_value = state in
    fun ~size ~intent:_ ~disabled ->
      let attrs =
        [ Attr.many (Style.input size)
        ; {%css|
            border: none;
            color: inherit;
            flex: 1;
            min-width: 0;
          |}
        ; Attr.value value
        ; Attr.on_input (fun _ new_value -> set_value new_value)
        ; Attr.many attrs
        ]
      in
      Elements.input ?test_selector ?key ?placeholder ~attrs ~disabled ()
  ;;

  let custom ?test_selector ?key ?(attrs = []) children : Content.t =
    fun ~size:_ ~intent:_ ~disabled:_ ->
    {%html|
      <div
        ?key
        *{attrs}
        %{Test_selector.attr_of_opt test_selector}
        %{Skyline_field_v2.Content.Expert.exclude_from_label_forwarding}
      >
        *{children}
      </div>
    |}
  ;;

  let content ?test_selector ?(attrs = []) children =
    Skyline_field_v2.Content.make (fun ~size ~intent ~disabled ->
      let wrapper_attrs =
        [ Attr.many Style.chrome
        ; Attr.many (Style.container_size size)
        ; Style.border_color ~disabled intent
        ; Style.focus_color intent
        ; (if disabled then Style.disabled else Attr.empty)
        ; {%css|
            display: inline-flex;
            align-items: center;
            gap: %{Classes.spacing 1.#Css_gen.Length};
          |}
        ; Test_selector.attr_of_opt test_selector
        ; Attr.many attrs
        ]
      in
      let children =
        List.map children ~f:(fun (child : Content.t) -> child ~size ~intent ~disabled)
      in
      {%html|<div *{wrapper_attrs}>*{children}</div>|})
  ;;
end

module Numeric = struct
  let prevent_non_numeric_keys =
    Attr.on_keypress (fun event ->
      let ( (* preventDefault on anything non-numeric ([0-9] and [.-_e]. *) ) =
        match Js_of_ocaml.Dom_html.Keyboard_code.of_event event with
        | Minus (* Covers [-] and [_]. *)
        | NumpadSubtract | KeyE (* Float values can use [e] for exponent. *)
        | Period
        | NumpadDecimal
        | Digit0
        | Digit1
        | Digit2
        | Digit3
        | Digit4
        | Digit5
        | Digit6
        | Digit7
        | Digit8
        | Digit9
        | Numpad0
        | Numpad1
        | Numpad2
        | Numpad3
        | Numpad4
        | Numpad5
        | Numpad6
        | Numpad7
        | Numpad8
        | Numpad9 -> ()
        | _ -> event##preventDefault
      in
      Effect.Ignore)
  ;;

  module State = struct
    type 'a t =
      { raw : string
      ; set_raw : string -> unit Effect.t
      ; value : 'a option
      ; error : unit Or_error.t
      }

    let value t = t.value

    let create (type a) (module M : Stringable.S with type t = a) ?state (local_ graph) =
      let to_string = Option.value_map ~default:"" ~f:M.to_string in
      let equal_parsed a b = String.equal (to_string a) (to_string b) in
      let raw, set_raw = Bonsai.state "" graph in
      let parse_result =
        let%arr raw in
        Or_error.try_with (fun () -> M.of_string raw)
      in
      let parsed =
        let%arr parse_result in
        Or_error.ok parse_result
      in
      let set_parsed =
        let%arr set_raw in
        fun value -> set_raw (to_string value)
      in
      let ( (* Sync external state, if provided. *) ) =
        match state with
        | None -> ()
        | Some (store_value, store_set) ->
          Bonsai_kernel_mirror.mirror
            ~trigger:`Before_display
            ~equal:equal_parsed
            ~store_set
            ~store_value
            ~interactive_set:set_parsed
            ~interactive_value:parsed
            graph
      in
      let%arr raw and set_raw and parsed and parse_result in
      let error =
        match parse_result with
        | Ok _ -> Ok ()
        | Error _ when String.is_empty raw -> Ok ()
        | Error e -> Error e
      in
      { raw; set_raw; value = parsed; error }
    ;;
  end

  let content
    ?test_selector
    ?(attrs = [])
    ?placeholder
    ~state:{ State.raw; set_raw; error; value = _ }
    ()
    =
    let input_attrs =
      [ Attr.create "inputmode" "decimal"
      ; prevent_non_numeric_keys
      ; Attr.value raw
      ; Attr.on_input (fun _ new_value -> set_raw new_value)
      ]
    in
    content' ?test_selector ?placeholder ~attrs ~error ~input_attrs ()
  ;;

  module Decimal = struct
    type t = float

    let of_string s =
      let t = Float.of_string s in
      if not (Float.is_finite t)
      then raise_s [%message "Cannot represent non-finite float as decimal" (s : string)];
      t
    ;;

    let to_string t = sprintf "%.12g" t
  end

  module Price = struct
    type t = float [@@deriving sexp_of]

    let of_float_rounded f =
      match Float.is_finite f with
      | true -> Some (Float.round_decimal f ~decimal_digits:2)
      | false -> None
    ;;

    let to_float = Fn.id

    let has_too_many_decimal_places s =
      match String.lsplit2 s ~on:'.' with
      | None -> false
      | Some (_, after_dot) -> String.length after_dot > 2
    ;;

    let of_string s =
      if has_too_many_decimal_places s
      then raise_s [%message "Price cannot have more than 2 decimal places" (s : string)];
      match of_float_rounded (Float.of_string s) with
      | None ->
        raise_s [%message "Cannot represent non-finite float as price" (s : string)]
      | Some t -> t
    ;;

    let to_string t = sprintf "%.2f" t
  end
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
