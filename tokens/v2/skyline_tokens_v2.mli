module Colors = Colors
module Font = Font
module Palette = Tailwind_colors

(** Defines the main spacing unit size in pixels *)
val spacing_unit_px : int

(** Create a css length based on a number of spacing units *)
val spacing : float -> Css_gen.Length.t
