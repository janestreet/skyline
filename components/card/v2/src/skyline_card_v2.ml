open! Core
open! Private_skyline_prelude

module Style = struct
  let to_padding = function
    | `Xs -> Classes.p 1.
    | `Sm -> Classes.p 2.
    | `Md -> Classes.p 3.
    | `Lg -> Classes.p 4.
  ;;

  let to_style size =
    let base = Attr.many Classes.[ text_default ] in
    let rounded_attr =
      match size with
      | `Xs -> Classes.rounded_xs
      | `Sm -> Classes.rounded_sm
      | `Md -> Classes.rounded_md
      | `Lg -> Classes.rounded_lg
    in
    Attr.many [ base; rounded_attr ]
  ;;

  let full_bleed = {%css|display: contents;|}
end

module Elevation = struct
  type t =
    | Zero
    | One
    | Two
    | Three
    | Four
  [@@deriving sexp, equal, enumerate, to_string]

  let to_style t =
    let border_style = Classes.[ border 1; border_default ] in
    let style =
      match t with
      | Zero -> []
      | One -> border_style
      | Two -> Classes.shadow_sm :: border_style
      | Three -> Classes.shadow_md :: border_style
      | Four -> Classes.shadow_lg :: border_style
    in
    Attr.many style
  ;;
end

module Surface_color = struct
  type t =
    | One
    | Two
    | Three
  [@@deriving sexp, equal, enumerate, to_string]

  let to_style = function
    | One -> Classes.bg_one
    | Two -> Classes.bg_two
    | Three -> Classes.bg_three
  ;;
end

module Content = struct
  type t = size:Skyline_size.t -> Node.t
end

let view
  ?test_selector
  ?(attrs = [])
  ?(size = `Md)
  ?(elevation = Elevation.One)
  ?(surface_color = Surface_color.One)
  children
  =
  let attrs =
    [ Test_selector.attr_of_opt test_selector
    ; Style.to_style size
    ; Elevation.to_style elevation
    ; Surface_color.to_style surface_color
    ; Classes.data_skyline_component "card"
    ; Attr.many attrs
    ]
  in
  Node.div ~attrs (List.map children ~f:(fun content -> content ~size))
;;

module Section = struct
  let content ?test_selector ?(full_bleed = false) ?(attrs = []) children ~size =
    let attrs =
      Test_selector.attr_of_opt test_selector
      :: (if full_bleed then Style.full_bleed else Style.to_padding size)
      :: attrs
    in
    Node.div ~attrs children
  ;;

  let text ?test_selector ?full_bleed ?attrs children ~size =
    Skyline_text_v2.view
      ~size:(size :> Skyline_text_v2.Size.t)
      ~layout:`Contents
      [ content ?test_selector ?full_bleed ?attrs children ~size ]
  ;;

  let title ?test_selector ?full_bleed ?(attrs = []) children ~size =
    Skyline_text_v2.view
      ~size:(size :> Skyline_text_v2.Size.t)
      ~weight:`Bold
      ~layout:`Contents
      [ content ?test_selector ?full_bleed ~attrs:(Classes.pb 0. :: attrs) children ~size
      ]
  ;;
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
