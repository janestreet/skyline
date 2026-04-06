open! Core

val size_2xs : Css_gen.Length.t
val size_xs : Css_gen.Length.t
val size_sm : Css_gen.Length.t
val size_base : Css_gen.Length.t
val size_lg : Css_gen.Length.t
val size_xl : Css_gen.Length.t
val size_2xl : Css_gen.Length.t
val size_3xl : Css_gen.Length.t
val size_4xl : Css_gen.Length.t
val size_5xl : Css_gen.Length.t
val line_height_2xs : Css_gen.Length.t
val line_height_xs : Css_gen.Length.t
val line_height_sm : Css_gen.Length.t
val line_height_base : Css_gen.Length.t
val line_height_lg : Css_gen.Length.t
val line_height_xl : Css_gen.Length.t
val line_height_2xl : Css_gen.Length.t
val line_height_3xl : Css_gen.Length.t
val line_height_4xl : Css_gen.Length.t
val line_height_5xl : Css_gen.Length.t

module Family : sig
  type t

  val sans : t
  val monospace : t
  val to_string_css : t -> string
end

module Weight : sig
  type t

  val light : t
  val normal : t
  val medium : t
  val semibold : t
  val bold : t
  val to_string_css : t -> string
end
