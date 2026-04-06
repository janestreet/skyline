module Colors = Colors
module Font = Font
module Palette = Tailwind_colors

let spacing_unit_px = 4
let spacing_unit_px_float = Float.of_int spacing_unit_px
let spacing units = `Px (Int.of_float (spacing_unit_px_float *. units))
