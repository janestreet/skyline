open! Core

val color : light:[< Css_gen.Color.t ] -> dark:[< Css_gen.Color.t ] -> Css_gen.Color.t
val transparent : Css_gen.Color.t

module Text : sig
  (* Base text colors. *)
  val default : Css_gen.Color.t
  val inverse : Css_gen.Color.t
  val link : Css_gen.Color.t
  val secondary : Css_gen.Color.t
  val disabled : Css_gen.Color.t
  val input_placeholder : Css_gen.Color.t
  val primary : Css_gen.Color.t
  val danger : Css_gen.Color.t
  val success : Css_gen.Color.t
  val warning : Css_gen.Color.t

  (* Text on filled. *)
  val on_filled_primary : Css_gen.Color.t
  val on_filled_secondary : Css_gen.Color.t
  val on_filled_danger : Css_gen.Color.t
  val on_filled_success : Css_gen.Color.t
  val on_filled_warning : Css_gen.Color.t

  (* Text on filled alt. *)
  val on_filled_alt_primary : Css_gen.Color.t
  val on_filled_alt_secondary : Css_gen.Color.t
  val on_filled_alt_danger : Css_gen.Color.t
  val on_filled_alt_success : Css_gen.Color.t
  val on_filled_alt_warning : Css_gen.Color.t

  (* Text on soft. *)
  val on_soft_primary : Css_gen.Color.t
  val on_soft_secondary : Css_gen.Color.t
  val on_soft_danger : Css_gen.Color.t
  val on_soft_success : Css_gen.Color.t
  val on_soft_warning : Css_gen.Color.t
end

module Shadow : sig
  val default : Css_gen.Color.t
  val primary : Css_gen.Color.t
  val danger : Css_gen.Color.t
  val success : Css_gen.Color.t
  val warning : Css_gen.Color.t
end

module Outline : sig
  val default_focus_visible : Css_gen.Color.t
  val primary_focus_visible : Css_gen.Color.t
  val danger_focus_visible : Css_gen.Color.t
  val success_focus_visible : Css_gen.Color.t
  val warning_focus_visible : Css_gen.Color.t
end

module Border : sig
  (* Border colors. *)
  val default : Css_gen.Color.t
  val default_alt : Css_gen.Color.t
  val primary : Css_gen.Color.t
  val danger : Css_gen.Color.t
  val success : Css_gen.Color.t
  val warning : Css_gen.Color.t
end

module Background : sig
  (* Background surface. *)
  val one : Css_gen.Color.t
  val two : Css_gen.Color.t
  val three : Css_gen.Color.t
  val app : Css_gen.Color.t
  val input : Css_gen.Color.t
  val input_disabled : Css_gen.Color.t
  val input_active : Css_gen.Color.t
  val code : Css_gen.Color.t

  (* Background intents. *)
  val primary : Css_gen.Color.t
  val primary_hover : Css_gen.Color.t
  val primary_active : Css_gen.Color.t
  val secondary : Css_gen.Color.t
  val secondary_hover : Css_gen.Color.t
  val secondary_active : Css_gen.Color.t
  val danger : Css_gen.Color.t
  val danger_hover : Css_gen.Color.t
  val danger_active : Css_gen.Color.t
  val success : Css_gen.Color.t
  val success_hover : Css_gen.Color.t
  val success_active : Css_gen.Color.t
  val warning : Css_gen.Color.t
  val warning_hover : Css_gen.Color.t
  val warning_active : Css_gen.Color.t

  (* Background alt intents. *)
  val primary_alt : Css_gen.Color.t
  val secondary_alt : Css_gen.Color.t
  val danger_alt : Css_gen.Color.t
  val success_alt : Css_gen.Color.t
  val warning_alt : Css_gen.Color.t

  (* Background soft intents. *)
  val soft_primary : Css_gen.Color.t
  val soft_primary_hover : Css_gen.Color.t
  val soft_primary_active : Css_gen.Color.t
  val soft_secondary : Css_gen.Color.t
  val soft_secondary_hover : Css_gen.Color.t
  val soft_secondary_active : Css_gen.Color.t
  val soft_danger : Css_gen.Color.t
  val soft_danger_hover : Css_gen.Color.t
  val soft_danger_active : Css_gen.Color.t
  val soft_success : Css_gen.Color.t
  val soft_success_hover : Css_gen.Color.t
  val soft_success_active : Css_gen.Color.t
  val soft_warning : Css_gen.Color.t
  val soft_warning_hover : Css_gen.Color.t
  val soft_warning_active : Css_gen.Color.t

  (* Background ghost intents. *)
  val primary_ghost_hover : Css_gen.Color.t
  val primary_ghost_active : Css_gen.Color.t
  val secondary_ghost_hover : Css_gen.Color.t
  val secondary_ghost_active : Css_gen.Color.t
  val danger_ghost_hover : Css_gen.Color.t
  val danger_ghost_active : Css_gen.Color.t
  val success_ghost_hover : Css_gen.Color.t
  val success_ghost_active : Css_gen.Color.t
  val warning_ghost_hover : Css_gen.Color.t
  val warning_ghost_active : Css_gen.Color.t
end

module For_docs : sig
  val ml_filepath : string
end
