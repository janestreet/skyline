open! Core
open! Bonsai_web

module Wrap = struct
  type t =
    | Nowrap
    | Wrap
    | Wrap_reverse
  [@@deriving sexp_of, compare, equal]

  let to_css_gen = function
    | Nowrap -> `Nowrap
    | Wrap -> `Wrap
    | Wrap_reverse -> `Wrap_reverse
  ;;
end

module Justify = struct
  type t =
    | Flex_start
    | Flex_end
    | Center
    | Space_between
    | Space_around
    | Space_evenly
  [@@deriving sexp_of, compare, equal]

  let to_css_gen = function
    | Flex_start -> `Flex_start
    | Flex_end -> `Flex_end
    | Center -> `Center
    | Space_between -> `Space_between
    | Space_around -> `Space_around
    | Space_evenly -> `Space_evenly
  ;;
end

module Align = struct
  type t =
    | Flex_start
    | Flex_end
    | Center
    | Stretch
    | Baseline
  [@@deriving sexp_of, compare, equal]

  let to_css_gen = function
    | Flex_start -> `Flex_start
    | Flex_end -> `Flex_end
    | Center -> `Center
    | Stretch -> `Stretch
    | Baseline -> `Baseline
  ;;
end

let style ?wrap ?justify ?align ?gap ?padding direction =
  let flex =
    Css_gen.flex_container
      ~direction
      ?wrap:(Option.map ~f:Wrap.to_css_gen wrap)
      ?justify_content:(Option.map ~f:Justify.to_css_gen justify)
      ?align_items:(Option.map ~f:Align.to_css_gen align)
      ?row_gap:gap
      ?column_gap:gap
      ()
  in
  match padding with
  | None -> flex
  | Some padding -> Css_gen.concat [ flex; Css_gen.uniform_padding padding ]
;;

let row ?(attrs = []) ?(reverse = false) ?wrap ?justify ?align ?gap ?padding children =
  let direction = if reverse then `Row_reverse else `Row in
  let style = Vdom.Attr.style (style ?wrap ?justify ?align ?gap ?padding direction) in
  Vdom.Node.div ~attrs:(style :: attrs) children
;;

let column ?(attrs = []) ?(reverse = false) ?wrap ?justify ?align ?gap ?padding children =
  let direction = if reverse then `Column_reverse else `Column in
  let style = Vdom.Attr.style (style ?wrap ?justify ?align ?gap ?padding direction) in
  Vdom.Node.div ~attrs:(style :: attrs) children
;;
