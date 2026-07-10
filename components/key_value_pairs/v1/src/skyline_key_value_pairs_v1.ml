open! Core
open Private_skyline_prelude

(* Type definitions for local component variants/options. Some like [Size] are shared. *)
module Layout = struct
  type t =
    | One_column
    | Two_columns
  [@@deriving enumerate, to_string, sexp_of, equal]
end

module Style = struct
  let layout : user_gap:Skyline_size.t -> Layout.t -> Vdom.Attr.t list =
    let open Classes in
    fun ~user_gap -> function
      | Layout.One_column ->
        let gap =
          gap
            (match user_gap with
             | `Xs -> 1.0
             | `Sm -> 2.0
             | `Md -> 3.0
             | `Lg -> 6.0)
        in
        [ flex; gap; flex_col ]
      | Layout.Two_columns ->
        let gap =
          match user_gap with
          | `Xs -> 0.5
          | `Sm -> 1.0
          | `Md -> 2.0
          | `Lg -> 4.0
        in
        [ grid
        ; {%css|
            grid-template-columns: auto 1fr;
            row-gap: %{spacing gap#Css_gen.Length};
            column-gap: %{spacing 4.0#Css_gen.Length};
          |}
        ]
  ;;
end

module Pair = struct
  type t = size:Skyline_size.t -> Vdom.Node.t * Vdom.Node.t list

  let content ~key children : t = fun ~size:_ -> key, children

  let text ?icon ~key children : t =
    fun ~size ->
    let icon =
      let%map.Option icon in
      let icon_size =
        match size with
        | `Xs -> Font.size_xs
        | `Sm -> Font.size_sm
        | `Md -> Font.size_base
        | `Lg -> Font.size_lg
      in
      Bonsai_web_icon.view
        ~attrs:Classes.[ h_full; w_full; inline_flex ]
        ~size:icon_size
        ~color:Colors.Text.secondary
        ~icon
        ()
    in
    let size = (size :> Skyline_text_v2.Size.t) in
    let key =
      {%html|
        <Skyline_text_v2.view
          *{Classes.[inline_flex; flex_row; gap 1.0; items_center]}
          ~size
          ~color:%{`Secondary}
          >?{icon}#{key}</>
      |}
    in
    let children =
      List.map children ~f:(fun child -> {%html|<Skyline_text_v2.view ~size>%{child}</>|})
    in
    key, children
  ;;
end

let view ?(attrs = []) ?(size = `Md) ?(layout = Layout.Two_columns) (pairs : Pair.t list) =
  let open Classes in
  let style = Style.layout ~user_gap:size layout in
  let render_key_value (pair : Pair.t) =
    let key, value = pair ~size in
    [ {%html|<div *{Classes.[flex; items_start]}>%{key}</div>|}
    ; {%html|<div %{flex} %{flex_col}>*{value}</div>|}
    ]
  in
  let items =
    match layout with
    | Two_columns ->
      let%bind.List pair = pairs in
      render_key_value pair
    | One_column ->
      let%map.List pair = pairs in
      {%html|
        <div %{flex} %{flex_col} %{gap 1.0}>
          *{render_key_value pair}
        </div>
      |}
  in
  {%html|<div *{style} *{attrs}>*{items}</div>|}
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
