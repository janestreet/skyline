open! Core
open Private_skyline_prelude

(* Type definitions for local component variants/options. Some like [Size] are shared. *)
module Layout = struct
  type t =
    | One_column
    | Two_columns
  [@@deriving enumerate, to_string, sexp_of, equal]
end

module Pair = struct
  type t = Vdom.Node.t * Vdom.Node.t
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

let key ?icon name =
  let open Classes in
  let icon =
    let%map.Option icon in
    let icon =
      Bonsai_web_icon.view
        ~attrs:[ h_full; w_full; inline_flex ]
        ~size:(spacing 4.0)
        ~color:Colors.Text.secondary
        ~icon
        ()
    in
    {%html|
      <div
        %{flex}
        %{justify_center}
        %{items_center}
        %{w 4.0}
        %{h 4.0}
      >
        %{icon}
      </div>
    |}
  in
  let color = {%css|color: %{Colors.Text.secondary#Css_gen.Color};|} in
  {%html|
    <div
      %{flex}
      %{flex_row}
      %{gap 1.0}
      %{items_center}
      %{color}
    >
      ?{icon}#{name}
    </div>
  |}
;;

let view
  ?(attrs = [])
  ?(layout = Layout.Two_columns)
  ?gap:(user_gap : Skyline_size.t = `Md)
  pairs
  =
  let open Classes in
  let style = Style.layout ~user_gap layout in
  let items =
    match layout with
    | Two_columns ->
      let%bind.List key, value = pairs in
      [ {%html|<div>%{key}</div>|}; {%html|<div>%{value}</div>|} ]
    | One_column ->
      let%map.List key, value = pairs in
      {%html|
        <div %{flex} %{flex_col} %{gap 1.0}>
          <div>%{key}</div>
          <div>%{value}</div>
        </div>
      |}
  in
  {%html|<div *{style} *{attrs}>*{items}</div>|}
;;

module For_docs = struct
  let ml_filepath = __FILE__
end
