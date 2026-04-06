open! Core
open! Bonsai_web

val light_dark
  :  light:[< Css_gen.Color.t ]
  -> dark:[< Css_gen.Color.t ]
  -> Css_gen.Color.t

val text : light:[< Css_gen.Color.t ] -> dark:[< Css_gen.Color.t ] -> Vdom.Attr.t
val bg : light:[< Css_gen.Color.t ] -> dark:[< Css_gen.Color.t ] -> Vdom.Attr.t
val border_color : light:[< Css_gen.Color.t ] -> dark:[< Css_gen.Color.t ] -> Vdom.Attr.t
val shadow : light:[< Css_gen.Color.t ] -> dark:[< Css_gen.Color.t ] -> Vdom.Attr.t
val outline : light:[< Css_gen.Color.t ] -> dark:[< Css_gen.Color.t ] -> Vdom.Attr.t

module Hover : sig
  val text : light:[< Css_gen.Color.t ] -> dark:[< Css_gen.Color.t ] -> Vdom.Attr.t
  val bg : light:[< Css_gen.Color.t ] -> dark:[< Css_gen.Color.t ] -> Vdom.Attr.t

  val border_color
    :  light:[< Css_gen.Color.t ]
    -> dark:[< Css_gen.Color.t ]
    -> Vdom.Attr.t
end

module Focus_visible : sig
  val outline : light:[< Css_gen.Color.t ] -> dark:[< Css_gen.Color.t ] -> Vdom.Attr.t
end

module Active : sig
  val text : light:[< Css_gen.Color.t ] -> dark:[< Css_gen.Color.t ] -> Vdom.Attr.t
  val bg : light:[< Css_gen.Color.t ] -> dark:[< Css_gen.Color.t ] -> Vdom.Attr.t

  val border_color
    :  light:[< Css_gen.Color.t ]
    -> dark:[< Css_gen.Color.t ]
    -> Vdom.Attr.t
end

(* Base text colors. *)
val text_default : Vdom.Attr.t
val text_inverse : Vdom.Attr.t
val text_link : Vdom.Attr.t
val text_secondary : Vdom.Attr.t
val text_disabled : Vdom.Attr.t
val text_input_placeholder : Vdom.Attr.t
val text_primary : Vdom.Attr.t
val text_danger : Vdom.Attr.t
val text_success : Vdom.Attr.t
val text_warning : Vdom.Attr.t

(* Text on filled. *)
val text_on_filled_primary : Vdom.Attr.t
val text_on_filled_secondary : Vdom.Attr.t
val text_on_filled_danger : Vdom.Attr.t
val text_on_filled_success : Vdom.Attr.t
val text_on_filled_warning : Vdom.Attr.t

(* Text on filled alt. *)
val text_on_filled_alt_primary : Vdom.Attr.t
val text_on_filled_alt_secondary : Vdom.Attr.t
val text_on_filled_alt_danger : Vdom.Attr.t
val text_on_filled_alt_success : Vdom.Attr.t
val text_on_filled_alt_warning : Vdom.Attr.t

(* Text on soft. *)
val text_on_soft_primary : Vdom.Attr.t
val text_on_soft_secondary : Vdom.Attr.t
val text_on_soft_danger : Vdom.Attr.t
val text_on_soft_success : Vdom.Attr.t
val text_on_soft_warning : Vdom.Attr.t

(* Shadows. *)
val shadow_default : Vdom.Attr.t
val shadow_primary : Vdom.Attr.t
val shadow_danger : Vdom.Attr.t
val shadow_success : Vdom.Attr.t
val shadow_warning : Vdom.Attr.t

(* Outline. *)
val outline_default_focus_visible : Vdom.Attr.t
val outline_primary_focus_visible : Vdom.Attr.t
val outline_danger_focus_visible : Vdom.Attr.t
val outline_success_focus_visible : Vdom.Attr.t
val outline_warning_focus_visible : Vdom.Attr.t

(* Border colors. *)
val border_transparent : Vdom.Attr.t
val border_default : Vdom.Attr.t
val border_default_alt : Vdom.Attr.t
val border_primary : Vdom.Attr.t
val border_danger : Vdom.Attr.t
val border_success : Vdom.Attr.t
val border_warning : Vdom.Attr.t

(* Background surface. *)
val bg_transparent : Vdom.Attr.t
val bg_one : Vdom.Attr.t
val bg_two : Vdom.Attr.t
val bg_three : Vdom.Attr.t
val bg_app : Vdom.Attr.t
val bg_input : Vdom.Attr.t
val bg_input_disabled : Vdom.Attr.t
val bg_input_active : Vdom.Attr.t

(* Background intents. *)
val bg_primary : Vdom.Attr.t
val bg_primary_hover : Vdom.Attr.t
val bg_primary_active : Vdom.Attr.t
val bg_secondary : Vdom.Attr.t
val bg_secondary_hover : Vdom.Attr.t
val bg_secondary_active : Vdom.Attr.t
val bg_danger : Vdom.Attr.t
val bg_danger_hover : Vdom.Attr.t
val bg_danger_active : Vdom.Attr.t
val bg_success : Vdom.Attr.t
val bg_success_hover : Vdom.Attr.t
val bg_success_active : Vdom.Attr.t
val bg_warning : Vdom.Attr.t
val bg_warning_hover : Vdom.Attr.t
val bg_warning_active : Vdom.Attr.t

(* Background alt intents. *)
val bg_primary_alt : Vdom.Attr.t
val bg_secondary_alt : Vdom.Attr.t
val bg_danger_alt : Vdom.Attr.t
val bg_success_alt : Vdom.Attr.t
val bg_warning_alt : Vdom.Attr.t

(* Background soft intents. *)
val bg_soft_primary : Vdom.Attr.t
val bg_soft_primary_hover : Vdom.Attr.t
val bg_soft_primary_active : Vdom.Attr.t
val bg_soft_secondary : Vdom.Attr.t
val bg_soft_secondary_hover : Vdom.Attr.t
val bg_soft_secondary_active : Vdom.Attr.t
val bg_soft_danger : Vdom.Attr.t
val bg_soft_danger_hover : Vdom.Attr.t
val bg_soft_danger_active : Vdom.Attr.t
val bg_soft_success : Vdom.Attr.t
val bg_soft_success_hover : Vdom.Attr.t
val bg_soft_success_active : Vdom.Attr.t
val bg_soft_warning : Vdom.Attr.t
val bg_soft_warning_hover : Vdom.Attr.t
val bg_soft_warning_active : Vdom.Attr.t

(* Background ghost intents. *)
val bg_primary_ghost_hover : Vdom.Attr.t
val bg_primary_ghost_active : Vdom.Attr.t
val bg_secondary_ghost_hover : Vdom.Attr.t
val bg_secondary_ghost_active : Vdom.Attr.t
val bg_danger_ghost_hover : Vdom.Attr.t
val bg_danger_ghost_active : Vdom.Attr.t
val bg_success_ghost_hover : Vdom.Attr.t
val bg_success_ghost_active : Vdom.Attr.t
val bg_warning_ghost_hover : Vdom.Attr.t
val bg_warning_ghost_active : Vdom.Attr.t
