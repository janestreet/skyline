open! Core
open! Bonsai_web
include module type of Color

(** Type alias: refers to things defined in raw pixels (1 = 1px). *)
type px = int

(** Type alias: refers to things defined in our 4x spacing (1 = 4px). *)
type spacing = float

val spacing : spacing -> Css_gen.Length.t
val color_scheme_light : Vdom.Attr.t
val color_scheme_dark : Vdom.Attr.t

(* Borders. *)
val border : px -> Vdom.Attr.t
val border_t : px -> Vdom.Attr.t
val border_r : px -> Vdom.Attr.t
val border_b : px -> Vdom.Attr.t
val border_l : px -> Vdom.Attr.t
val border_solid : Vdom.Attr.t
val border_dashed : Vdom.Attr.t
val border_dotted : Vdom.Attr.t
val border_double : Vdom.Attr.t
val border_hidden : Vdom.Attr.t
val border_none : Vdom.Attr.t

(* Fonts. *)
val text_2xs : Vdom.Attr.t
val text_xs : Vdom.Attr.t
val text_sm : Vdom.Attr.t
val text_base : Vdom.Attr.t
val text_lg : Vdom.Attr.t
val text_xl : Vdom.Attr.t
val text_2xl : Vdom.Attr.t
val text_3xl : Vdom.Attr.t
val text_4xl : Vdom.Attr.t
val text_5xl : Vdom.Attr.t
val font_light : Vdom.Attr.t
val font_normal : Vdom.Attr.t
val font_medium : Vdom.Attr.t
val font_semibold : Vdom.Attr.t
val font_bold : Vdom.Attr.t

(* Font Family. *)
val font_sans : Vdom.Attr.t
val font_monospace : Vdom.Attr.t

(* Text deocration. *)
val underline : Vdom.Attr.t
val overline : Vdom.Attr.t
val line_through : Vdom.Attr.t

(* Cursors. *)
val cursor_auto : Vdom.Attr.t
val cursor_default : Vdom.Attr.t
val cursor_pointer : Vdom.Attr.t
val cursor_move : Vdom.Attr.t
val cursor_not_allowed : Vdom.Attr.t
val cursor_help : Vdom.Attr.t

(* Box shadows. *)
val shadow_2xs : Vdom.Attr.t
val shadow_xs : Vdom.Attr.t
val shadow_sm : Vdom.Attr.t
val shadow_md : Vdom.Attr.t
val shadow_lg : Vdom.Attr.t
val shadow_xl : Vdom.Attr.t
val shadow_2xl : Vdom.Attr.t

(* Heights. *)
val h_auto : Vdom.Attr.t
val h_full : Vdom.Attr.t
val h_screen : Vdom.Attr.t
val h_min : Vdom.Attr.t
val h_max : Vdom.Attr.t
val h_fit : Vdom.Attr.t
val h : spacing -> Vdom.Attr.t

(* Min/max heights. *)
val min_h_full : Vdom.Attr.t
val min_h : spacing -> Vdom.Attr.t
val max_h_full : Vdom.Attr.t
val max_h : spacing -> Vdom.Attr.t

(* Widths. *)
val w_auto : Vdom.Attr.t
val w_full : Vdom.Attr.t
val w_screen : Vdom.Attr.t
val w_min : Vdom.Attr.t
val w_max : Vdom.Attr.t
val w_fit : Vdom.Attr.t
val w : spacing -> Vdom.Attr.t

(* Min/max width. *)
val min_w_full : Vdom.Attr.t
val min_w : spacing -> Vdom.Attr.t
val max_w_full : Vdom.Attr.t
val max_w : spacing -> Vdom.Attr.t

(* Flex. *)
val flex : Vdom.Attr.t
val inline_flex : Vdom.Attr.t
val flex_row : Vdom.Attr.t
val flex_col : Vdom.Attr.t
val flex_wrap : Vdom.Attr.t
val gap : spacing -> Vdom.Attr.t

(* Grid. *)
val grid : Vdom.Attr.t
val grid_rows : int -> Vdom.Attr.t
val grid_cols : int -> Vdom.Attr.t

(* Padding. *)
val p : spacing -> Vdom.Attr.t
val px : spacing -> Vdom.Attr.t
val py : spacing -> Vdom.Attr.t
val pt : spacing -> Vdom.Attr.t
val pb : spacing -> Vdom.Attr.t
val pl : spacing -> Vdom.Attr.t
val pr : spacing -> Vdom.Attr.t

(* Margin. *)
val m : spacing -> Vdom.Attr.t
val mx : spacing -> Vdom.Attr.t
val my : spacing -> Vdom.Attr.t
val mt : spacing -> Vdom.Attr.t
val mb : spacing -> Vdom.Attr.t
val ml : spacing -> Vdom.Attr.t
val mr : spacing -> Vdom.Attr.t

(* Z-index. *)
val z : int -> Vdom.Attr.t

(* Justify content. *)
val justify_normal : Vdom.Attr.t
val justify_start : Vdom.Attr.t
val justify_end : Vdom.Attr.t
val justify_center : Vdom.Attr.t
val justify_between : Vdom.Attr.t
val justify_around : Vdom.Attr.t
val justify_evenly : Vdom.Attr.t
val justify_stretch : Vdom.Attr.t

(* Align items. *)
val items_start : Vdom.Attr.t
val items_end : Vdom.Attr.t
val items_center : Vdom.Attr.t
val items_baseline : Vdom.Attr.t
val items_stretch : Vdom.Attr.t

(* Border radius *)
val rounded_2xs : Vdom.Attr.t
val rounded_xs : Vdom.Attr.t
val rounded_sm : Vdom.Attr.t
val rounded_md : Vdom.Attr.t
val rounded_lg : Vdom.Attr.t
val rounded_xl : Vdom.Attr.t
val rounded_none : Vdom.Attr.t
val rounded_full : Vdom.Attr.t

(* Higher-level utils for applying styles to your app. *)
module Root : sig
  val font : Vdom.Attr.t
  val layout : [ `Dark | `Light ] -> Vdom.Attr.t
end

val data_skyline_component : string -> Vdom.Attr.t

(* Prefer over [Vdom.Attr.disabled]. *)
val disabled : Vdom.Attr.t
