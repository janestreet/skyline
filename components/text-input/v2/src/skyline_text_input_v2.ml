open! Core
open! Private_skyline_prelude

module Style = struct
  let base =
    Classes.
      [ w_full
      ; text_default
      ; border 1
      ; border_solid
      ; border_default
      ; bg_input
      ; {%css|
          outline: none;

          &.for-testing--force-focus-visible,
          &:focus {
            background-color: %{Colors.Background.input_active#Css_gen.Color};
          }

          &::placeholder {
            color: %{Css_gen.Color.to_string_css Colors.Text.input_placeholder};
          }
        |}
      ]
  ;;

  let size = function
    | `Xs -> Classes.[ text_xs; px 0.5; rounded_xs ]
    | `Sm -> Classes.[ text_sm; px 1.; rounded_xs ]
    | `Md -> Classes.[ text_sm; px 2.; py 1.; rounded_sm ]
    | `Lg -> Classes.[ text_sm; px 2.; py 2.; rounded_md ]
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
          &.for-testing--force-focus-visible,
          &:focus {
            border-color: %{border#Css_gen.Color};
            box-shadow: 0 0 0 3px %{shadow#Css_gen.Color};
          }
        |}
      ]
  ;;

  let disabled = Attr.many Classes.[ bg_input_disabled; text_input_placeholder ]
end

let content' ?test_selector ?placeholder ?(attrs = []) ~input_attrs () =
  Skyline_field_v2.Content.make (fun ~size ~intent ~disabled ->
    let attrs =
      [ Attr.many Style.base
      ; Attr.many (Style.size size)
      ; Style.border_color ~disabled intent
      ; Style.focus_color intent
      ; (if disabled then Style.disabled else Attr.empty)
      ; Test_selector.attr_of_opt test_selector
      ; Attr.many attrs
      ]
    in
    let placeholder =
      match placeholder with
      | None -> Attr.empty
      | Some placeholder -> Attr.placeholder placeholder
    in
    let maybe_disabled_attr = if disabled then Classes.disabled else Attr.empty in
    {%html|
      <input
        *{input_attrs}
        *{attrs}
        %{placeholder}
        %{maybe_disabled_attr}
        type="text"
      />
    |})
;;

let content ?test_selector ?attrs ?placeholder ~state () =
  let value, set_value = state in
  let input_attrs =
    [ Attr.value_prop value; Attr.on_input (fun _ new_value -> set_value new_value) ]
  in
  content' ?test_selector ?placeholder ?attrs ~input_attrs ()
;;

module Numeric = struct
  let content
    (type a)
    ~(stringable : (module Stringable.S with type t = a))
    ?test_selector
    ?attrs
    ?placeholder
    ~state:(value, set_value)
    ()
    =
    let module M = (val stringable) in
    let value_attr =
      let of_string_opt s = Option.try_with (fun () -> M.of_string s) in
      let is_or_could_be_valid s =
        let is_valid s = of_string_opt s |> Option.is_some in
        (* Also check for values that could be valid if the user types another digit. *)
        is_valid s || is_valid (s ^ "0")
      in
      let parse s = Option.map (of_string_opt s) ~f:M.to_string in
      let value = Option.value_map value ~default:"" ~f:M.to_string in
      let set_value s = set_value (of_string_opt s) in
      Input_value_hook.create
        ~filter_input:is_or_could_be_valid
        ~parse
        ~state:(value, set_value)
        ()
    in
    let input_attrs =
      [ (* Hint to browser that this input is numeric. *)
        Attr.create "inputmode" "decimal"
      ; value_attr
      ]
    in
    content' ?test_selector ?placeholder ?attrs ~input_attrs ()
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
  let ml_filepath = __FILE__
end

module For_testing = struct
  module Input_value_hook = Input_value_hook
end
