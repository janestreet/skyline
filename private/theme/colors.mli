open! Core
open! Css_gen

module type S = sig
  type color

  (** The primary text / foreground color. *)
  val primary : color

  (** The background color. *)
  val background : color

  (** Color for input text placeholders. *)
  val placeholder : color

  (** Color for a positive 'success' state. *)
  val success : color

  (** Color for a 'warning' state. *)
  val warning : color

  (** Color for an 'error' state. *)
  val error : color

  (** Accent color used e.g. for text selecting. *)
  val accent : color

  (** Background color for raised elements like cards. *)
  val surface : color

  (** Color that can be used for borders separating elements of regular and raised
      elements. *)
  val border : color

  val black : color
  val white : color
  val blue : color
  val green : color
  val yellow : color
  val red : color
  val clay : color
  val lavender : color
  val marina : color
  val moss : color
  val mud : color
end

module Constants : sig
  include S with type color := Color.t

  (** [ramp base step] produces colors by interpolating between the background color and
      the the provided [base] color, using the [step].

      {2 Examples}
      {[
        let mostly_mossy = ramp moss (Percent.of_mult 0.9) in
        let mildly_mossy = ramp moss (Percent.of_mult 0.2) in
      ]} *)
  val ramp : Color.t -> Percent.t -> Color.t

  (** [fade color step] produces colors that fade from [color] to transparent. The [step]
      represents how close to the [color] it should be.

      {2 Examples}
      {[
        let mostly_mossy = ramp moss (Percent.of_mult 0.9) in
        let mostly_transparent = ramp moss (Percent.of_mult 0.2) in
      ]} *)
  val fade : Color.t -> Percent.t -> Color.t
end

val install
  :  Style.t
  -> accent:[ `Blue | `Clay | `Lavender | `Marina | `Moss | `Mud ]
  -> unit

val clear : unit -> unit
