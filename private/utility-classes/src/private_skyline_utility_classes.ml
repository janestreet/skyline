open! Core
open! Bonsai_web
module Font = Skyline_tokens_v2.Font
include Color

type px = int
type spacing = float

let spacing = Skyline_tokens_v2.spacing
let color_scheme_light = {%css|color-scheme: light;|}
let color_scheme_dark = {%css|color-scheme: dark;|}

(* Shadows. *)
let shadow_2xs = {%css|box-shadow: 0px 1px 0px rgba(0, 0, 0, 0.05);|}
let shadow_xs = {%css|box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.05);|}

let shadow_sm =
  {%css|
    box-shadow: 0px 1px 2px -1px rgba(0, 0, 0, 0.1), 0px 1px 3px
      rgba(0, 0, 0, 0.1);
  |}
;;

let shadow_md =
  {%css|
    box-shadow: 0px 2px 4px -2px rgba(0, 0, 0, 0.1), 0px 4px 6px 1px
      rgba(0, 0, 0, 0.1);
  |}
;;

let shadow_lg =
  {%css|
    box-shadow: 0px 4px 6px -4px rgba(0, 0, 0, 0.1), 0px 10px 15px -3px
      rgba(0, 0, 0, 0.1);
  |}
;;

let shadow_xl =
  {%css|
    box-shadow: 0px 8px 10px -6px rgba(0, 0, 0, 0.1), 0px 20px 25px -5px
      rgba(0, 0, 0, 0.1);
  |}
;;

let shadow_2xl = {%css|box-shadow: 0px 25px 50px -12px rgba(0, 0, 0, 0.25);|}

(* Font sizes. *)
let text_2xs =
  {%css|
    font-size: %{Font.size_2xs#Css_gen.Length};
    line-height: %{Font.line_height_2xs#Css_gen.Length};
  |}
;;

let text_xs =
  {%css|
    font-size: %{Font.size_xs#Css_gen.Length};
    line-height: %{Font.line_height_xs#Css_gen.Length};
  |}
;;

let text_sm =
  {%css|
    font-size: %{Font.size_sm#Css_gen.Length};
    line-height: %{Font.line_height_sm#Css_gen.Length};
  |}
;;

let text_base =
  {%css|
    font-size: %{Font.size_base#Css_gen.Length};
    line-height: %{Font.line_height_base#Css_gen.Length};
  |}
;;

let text_lg =
  {%css|
    font-size: %{Font.size_lg#Css_gen.Length};
    line-height: %{Font.line_height_lg#Css_gen.Length};
  |}
;;

let text_xl =
  {%css|
    font-size: %{Font.size_xl#Css_gen.Length};
    line-height: %{Font.line_height_xl#Css_gen.Length};
  |}
;;

let text_2xl =
  {%css|
    font-size: %{Font.size_2xl#Css_gen.Length};
    line-height: %{Font.line_height_2xl#Css_gen.Length};
  |}
;;

let text_3xl =
  {%css|
    font-size: %{Font.size_3xl#Css_gen.Length};
    line-height: %{Font.line_height_3xl#Css_gen.Length};
  |}
;;

let text_4xl =
  {%css|
    font-size: %{Font.size_4xl#Css_gen.Length};
    line-height: %{Font.line_height_4xl#Css_gen.Length};
  |}
;;

let text_5xl =
  {%css|
    font-size: %{Font.size_5xl#Css_gen.Length};
    line-height: %{Font.line_height_5xl#Css_gen.Length};
  |}
;;

let font_light = {%css|font-weight: %{Font.Weight.light#Font.Weight};|}
let font_normal = {%css|font-weight: %{Font.Weight.normal#Font.Weight};|}
let font_medium = {%css|font-weight: %{Font.Weight.medium#Font.Weight};|}
let font_semibold = {%css|font-weight: %{Font.Weight.semibold#Font.Weight};|}
let font_bold = {%css|font-weight: %{Font.Weight.bold#Font.Weight};|}
let font_sans = {%css|font-family: %{Font.Family.sans#Font.Family};|}
let font_monospace = {%css|font-family: %{Font.Family.monospace#Font.Family};|}

(* Text decoration. *)
let underline = {%css|text-decoration: underline;|}
let overline = {%css|text-decoration: overline;|}
let line_through = {%css|text-decoration: line-through;|}

(* Cursors. *)
let cursor_auto = {%css|cursor: auto;|}
let cursor_default = {%css|cursor: default;|}
let cursor_pointer = {%css|cursor: pointer;|}
let cursor_not_allowed = {%css|cursor: not-allowed;|}
let cursor_move = {%css|cursor: move;|}
let cursor_help = {%css|cursor: help;|}

(* Borders. *)
let border n =
  {%css|
    border-style: solid;
    border-width: %{`Px n#Css_gen.Length};
  |}
;;

let border_t n =
  {%css|
    border-style: solid;
    border-top-width: %{`Px n#Css_gen.Length};
  |}
;;

let border_r n =
  {%css|
    border-style: solid;
    border-right-width: %{`Px n#Css_gen.Length};
  |}
;;

let border_b n =
  {%css|
    border-style: solid;
    border-bottom-width: %{`Px n#Css_gen.Length};
  |}
;;

let border_l n =
  {%css|
    border-style: solid;
    border-left-width: %{`Px n#Css_gen.Length};
  |}
;;

let border_solid = {%css|border-style: solid;|}
let border_dashed = {%css|border-style: dashed;|}
let border_dotted = {%css|border-style: dotted;|}
let border_double = {%css|border-style: double;|}
let border_hidden = {%css|border-style: hidden;|}
let border_none = {%css|border-style: none;|}

(* Heights. *)
let h_auto = {%css|height: auto;|}
let h_full = {%css|height: 100%;|}
let h_screen = {%css|height: 100vh;|}
let h_min = {%css|height: min-content;|}
let h_max = {%css|height: max-content;|}
let h_fit = {%css|height: fit-content;|}
let h n = {%css|height: %{spacing n#Css_gen.Length};|}

(* Min/max heights. *)
let min_h_full = {%css|min-height: 100%;|}
let min_h n = {%css|min-height: %{spacing n#Css_gen.Length};|}
let max_h_full = {%css|max-height: 100%;|}
let max_h n = {%css|max-height: %{spacing n#Css_gen.Length};|}

(* Min/max widths. *)
let min_w_full = {%css|min-width: 100%;|}
let min_w n = {%css|min-width: %{spacing n#Css_gen.Length};|}
let max_w_full = {%css|max-width: 100%;|}
let max_w n = {%css|max-width: %{spacing n#Css_gen.Length};|}

(* Widths. *)
let w_auto = {%css|width: auto;|}
let w_full = {%css|width: 100%;|}
let w_screen = {%css|width: 100vw;|}
let w_min = {%css|width: min-content;|}
let w_max = {%css|width: max-content;|}
let w_fit = {%css|width: fit-content;|}
let w n = {%css|width: %{spacing n#Css_gen.Length};|}

(* Flex. *)
let flex = {%css|display: flex;|}
let inline_flex = {%css|display: inline-flex;|}
let flex_row = {%css|flex-direction: row;|}
let flex_col = {%css|flex-direction: column;|}
let flex_wrap = {%css|flex-wrap: wrap;|}
let gap n = {%css|gap: %{spacing n#Css_gen.Length};|}

(* Grid. *)
let raw_int n = `Raw (Int.to_string n)
let grid = {%css|display: grid;|}

let grid_rows n =
  {%css|grid-template-rows: repeat(%{raw_int n#Css_gen.Length}, minmax(0, 1fr));|}
;;

let grid_cols n =
  {%css|grid-template-columns: repeat(%{raw_int n#Css_gen.Length}, minmax(0, 1fr));|}
;;

(* Padding. *)
let p n = {%css|padding: %{spacing n#Css_gen.Length};|}

let px n =
  {%css|
    padding-left: %{spacing n#Css_gen.Length};
    padding-right: %{spacing n#Css_gen.Length};
  |}
;;

let py n =
  {%css|
    padding-top: %{spacing n#Css_gen.Length};
    padding-bottom: %{spacing n#Css_gen.Length};
  |}
;;

let pt n = {%css|padding-top: %{spacing n#Css_gen.Length};|}
let pb n = {%css|padding-bottom: %{spacing n#Css_gen.Length};|}
let pl n = {%css|padding-left: %{spacing n#Css_gen.Length};|}
let pr n = {%css|padding-right: %{spacing n#Css_gen.Length};|}

(* Margin. *)
let m n = {%css|margin: %{spacing n#Css_gen.Length};|}

let mx n =
  {%css|
    margin-left: %{spacing n#Css_gen.Length};
    margin-right: %{spacing n#Css_gen.Length};
  |}
;;

let my n =
  {%css|
    margin-top: %{spacing n#Css_gen.Length};
    margin-bottom: %{spacing n#Css_gen.Length};
  |}
;;

let mt n = {%css|margin-top: %{spacing n#Css_gen.Length};|}
let mb n = {%css|margin-bottom: %{spacing n#Css_gen.Length};|}
let ml n = {%css|margin-left: %{spacing n#Css_gen.Length};|}
let mr n = {%css|margin-right: %{spacing n#Css_gen.Length};|}

(* Z-index. *)
let z n = {%css|z-index: %{n * 10 |> Int.to_string};|}

(* Flex item positioning. *)
let justify_normal = {%css|justify-content: normal;|}
let justify_start = {%css|justify-content: start;|}
let justify_end = {%css|justify-content: end;|}
let justify_center = {%css|justify-content: center;|}
let justify_between = {%css|justify-content: space-between;|}
let justify_around = {%css|justify-content: space-around;|}
let justify_evenly = {%css|justify-content: space-evenly;|}
let justify_stretch = {%css|justify-content: stretch;|}
let items_start = {%css|align-items: flex-start;|}
let items_end = {%css|align-items: flex-end;|}
let items_center = {%css|align-items: center;|}
let items_baseline = {%css|align-items: baseline;|}
let items_stretch = {%css|align-items: stretch;|}

(* Border radius *)
let rounded_2xs = {%css|border-radius: 1px;|}
let rounded_xs = {%css|border-radius: 2px;|}
let rounded_sm = {%css|border-radius: 4px;|}
let rounded_md = {%css|border-radius: 6px;|}
let rounded_lg = {%css|border-radius: 8px;|}
let rounded_xl = {%css|border-radius: 12px;|}
let rounded_none = {%css|border-radius: 0px;|}
let rounded_full = {%css|border-radius: 50%;|}

module Root = struct
  let font =
    Vdom.Attr.many
      [ text_base; text_default; font_sans; {%css|font-variant-numeric: tabular-nums;|} ]
  ;;

  let layout color_scheme =
    let color_scheme =
      match color_scheme with
      | `Light -> color_scheme_light
      | `Dark -> color_scheme_dark
    in
    Vdom.Attr.many [ color_scheme; bg_app; font ]
  ;;
end

let data_skyline_component name =
  Vdom.Attr.create "data-skyline-component" name |> Vdom.Attr.suppress_merge_warnings
;;

(* vimium and other dom traversal tools look for aria-disabled in addition to the disabled
   attribute. This is just a helper to set both. *)
let disabled =
  Vdom.Attr.many [ Vdom.Attr.disabled; Vdom.Attr.create "aria-disabled" "true" ]
;;
