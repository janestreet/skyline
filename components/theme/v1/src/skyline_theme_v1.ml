open! Core
open! Bonsai_web

module Accent = struct
  type t =
    [ `Blue
    | `Clay
    | `Lavender
    | `Marina
    | `Moss
    | `Mud
    ]
  [@@deriving sexp, compare, equal]

  let to_css = function
    | `Blue -> Private_skyline_theme.Colors.Constants.blue
    | `Clay -> Private_skyline_theme.Colors.Constants.clay
    | `Lavender -> Private_skyline_theme.Colors.Constants.lavender
    | `Marina -> Private_skyline_theme.Colors.Constants.marina
    | `Moss -> Private_skyline_theme.Colors.Constants.moss
    | `Mud -> Private_skyline_theme.Colors.Constants.mud
  ;;

  let to_string_css t = Css_gen.Color.to_string_css (to_css t)
end

module Color = struct
  type t = Css_gen.Color.t [@@deriving sexp, compare, equal]

  let to_css (t : [< t ]) = (t :> t)
  let to_string_css = Css_gen.Color.to_string_css
end

(* Public exports. *)
module Style = Private_skyline_theme.Style
include Private_skyline_theme.Colors.Constants
