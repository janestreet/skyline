open! Core
open! Bonsai_web

(** The style that e.g. determines which colors are used. *)
module Style :
  module type of Private_skyline_theme.Style with type t = Private_skyline_theme.Style.t

(** The selection of accent colors that can be used to theme an application. *)
module Accent : sig
  type t =
    [ `Blue
    | `Clay
    | `Lavender
    | `Marina
    | `Moss
    | `Mud
    ]
  [@@deriving sexp, compare, equal]

  val to_css : [< t ] -> Css_gen.Color.t
  val to_string_css : [< t ] -> string
end

module Color : sig
  type t = Css_gen.Color.t [@@deriving sexp, compare, equal]

  val to_css : [< t ] -> Css_gen.Color.t
  val to_string_css : [< t ] -> string
end

(** [{#Colors}]

    Skyline defines constants for colors. Colors are available as named constants (e.g.
    [red] or [green]) and as design tokens (e.g. [error] or [success]). You should usually
    prefer to use color tokens based on intent unless you simply need a list of different
    colors. *)

(** \@@inline *)
include module type of Private_skyline_theme.Colors.Constants
