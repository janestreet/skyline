open! Core
open! Bonsai_web
module Colors = Skyline_tokens_v2.Colors

let light_dark = Colors.color

module Private = struct
  let text color = {%css|color: %{ color#Css_gen.Color};|}
  let bg color = {%css|background-color: %{color#Css_gen.Color};|}
  let border_color color = {%css|border-color: %{color#Css_gen.Color};|}
  let shadow color = {%css|box-shadow-color: %{color#Css_gen.Color};|}
  let outline color = {%css|outline-color: %{color#Css_gen.Color};|}

  module Hover = struct
    let text color =
      {%css|
        &:hover,
        &.for-testing--force-hover {
          color: %{color#Css_gen.Color};
        }
      |}
    ;;

    let bg color =
      {%css|
        &:hover,
        &.for-testing--force-hover {
          background-color: %{color#Css_gen.Color};
        }
      |}
    ;;

    let border_color color =
      {%css|
        &:hover,
        &.for-testing--force-hover {
          border-color: %{color#Css_gen.Color};
        }
      |}
    ;;
  end

  module Focus_visible = struct
    let outline color =
      {%css|
        &:focus-visible,
        &.for-testing--force-focus-visible {
          outline-color: %{color#Css_gen.Color};
        }
      |}
    ;;
  end

  module Active = struct
    let text color =
      {%css|
        &:active,
        &.for-testing--force-active {
          color: %{color#Css_gen.Color};
        }
      |}
    ;;

    let bg color =
      {%css|
        &:active,
        &.for-testing--force-active {
          background-color: %{color#Css_gen.Color};
        }
      |}
    ;;

    let border_color color =
      {%css|
        &:active,
        &.for-testing--force-active {
          border-color: %{color#Css_gen.Color};
        }
      |}
    ;;
  end
end

let text ~light ~dark = Private.text (light_dark ~light ~dark)
let bg ~light ~dark = Private.bg (light_dark ~light ~dark)
let border_color ~light ~dark = Private.border_color (light_dark ~light ~dark)
let shadow ~light ~dark = Private.shadow (light_dark ~light ~dark)
let outline ~light ~dark = Private.outline (light_dark ~light ~dark)

module Hover = struct
  let text ~light ~dark = Private.Hover.text (light_dark ~light ~dark)
  let bg ~light ~dark = Private.Hover.bg (light_dark ~light ~dark)
  let border_color ~light ~dark = Private.Hover.border_color (light_dark ~light ~dark)
end

module Focus_visible = struct
  let outline ~light ~dark = Private.Focus_visible.outline (light_dark ~light ~dark)
end

module Active = struct
  let text ~light ~dark = Private.Active.text (light_dark ~light ~dark)
  let bg ~light ~dark = Private.Active.bg (light_dark ~light ~dark)
  let border_color ~light ~dark = Private.Active.border_color (light_dark ~light ~dark)
end

(* Base text colors. *)
let text_default = Private.text Colors.Text.default
let text_inverse = Private.text Colors.Text.inverse
let text_link = Private.text Colors.Text.link
let text_secondary = Private.text Colors.Text.secondary
let text_disabled = Private.text Colors.Text.disabled
let text_input_placeholder = Private.text Colors.Text.input_placeholder
let text_primary = Private.text Colors.Text.primary
let text_danger = Private.text Colors.Text.danger
let text_success = Private.text Colors.Text.success
let text_warning = Private.text Colors.Text.warning

(* Text on filled. *)
let text_on_filled_primary = Private.text Colors.Text.on_filled_primary
let text_on_filled_secondary = Private.text Colors.Text.on_filled_secondary
let text_on_filled_danger = Private.text Colors.Text.on_filled_danger
let text_on_filled_success = Private.text Colors.Text.on_filled_success
let text_on_filled_warning = Private.text Colors.Text.on_filled_warning

(* Text on filled alt. *)
let text_on_filled_alt_primary = Private.text Colors.Text.on_filled_alt_primary
let text_on_filled_alt_secondary = Private.text Colors.Text.on_filled_alt_secondary
let text_on_filled_alt_danger = Private.text Colors.Text.on_filled_alt_danger
let text_on_filled_alt_success = Private.text Colors.Text.on_filled_alt_success
let text_on_filled_alt_warning = Private.text Colors.Text.on_filled_alt_warning

(* Text on soft. *)
let text_on_soft_primary = Private.text Colors.Text.on_soft_primary
let text_on_soft_secondary = Private.text Colors.Text.on_soft_secondary
let text_on_soft_danger = Private.text Colors.Text.on_soft_danger
let text_on_soft_success = Private.text Colors.Text.on_soft_success
let text_on_soft_warning = Private.text Colors.Text.on_soft_warning

(* Shadows. *)
let shadow_default = Private.shadow Colors.Shadow.default
let shadow_primary = Private.shadow Colors.Shadow.primary
let shadow_danger = Private.shadow Colors.Shadow.danger
let shadow_success = Private.shadow Colors.Shadow.success
let shadow_warning = Private.shadow Colors.Shadow.warning

(* Outline. *)
let outline_default_focus_visible =
  Private.Focus_visible.outline Colors.Background.primary
;;

let outline_primary_focus_visible =
  Private.Focus_visible.outline Colors.Background.primary
;;

let outline_danger_focus_visible = Private.Focus_visible.outline Colors.Background.danger

let outline_success_focus_visible =
  Private.Focus_visible.outline Colors.Background.success
;;

let outline_warning_focus_visible =
  Private.Focus_visible.outline Colors.Background.warning
;;

(* Border colors. *)
let border_transparent = Private.border_color Colors.transparent
let border_default = Private.border_color Colors.Border.default
let border_default_alt = Private.border_color Colors.Border.default_alt
let border_primary = Private.border_color Colors.Border.primary
let border_danger = Private.border_color Colors.Border.danger
let border_success = Private.border_color Colors.Border.success
let border_warning = Private.border_color Colors.Border.warning

(* Background surface. *)
let bg_transparent = Private.bg Colors.transparent
let bg_one = Private.bg Skyline_tokens_v2.Colors.Background.one
let bg_two = Private.bg Skyline_tokens_v2.Colors.Background.two
let bg_three = Private.bg Skyline_tokens_v2.Colors.Background.three
let bg_app = Private.bg Skyline_tokens_v2.Colors.Background.app
let bg_input = Private.bg Skyline_tokens_v2.Colors.Background.input
let bg_input_disabled = Private.bg Skyline_tokens_v2.Colors.Background.input_disabled
let bg_input_active = Private.bg Skyline_tokens_v2.Colors.Background.input_active

(* Background intents. *)
let bg_primary = Private.bg Colors.Background.primary
let bg_primary_hover = Private.Hover.bg Colors.Background.primary_hover
let bg_primary_active = Private.Active.bg Colors.Background.primary_active
let bg_secondary = Private.bg Colors.Background.secondary
let bg_secondary_hover = Private.Hover.bg Colors.Background.secondary_hover
let bg_secondary_active = Private.Active.bg Colors.Background.secondary_active
let bg_danger = Private.bg Colors.Background.danger
let bg_danger_hover = Private.Hover.bg Colors.Background.danger_hover
let bg_danger_active = Private.Active.bg Colors.Background.danger_active
let bg_success = Private.bg Colors.Background.success
let bg_success_hover = Private.Hover.bg Colors.Background.success_hover
let bg_success_active = Private.Active.bg Colors.Background.success_active
let bg_warning = Private.bg Colors.Background.warning
let bg_warning_hover = Private.Hover.bg Colors.Background.warning_hover
let bg_warning_active = Private.Active.bg Colors.Background.warning_active

(* Background alt intents. *)
let bg_primary_alt = Private.bg Colors.Background.primary_alt
let bg_secondary_alt = Private.bg Colors.Background.secondary_alt
let bg_danger_alt = Private.bg Colors.Background.danger_alt
let bg_success_alt = Private.bg Colors.Background.success_alt
let bg_warning_alt = Private.bg Colors.Background.warning_alt

(* Background soft intents. *)
let bg_soft_primary = Private.bg Colors.Background.soft_primary
let bg_soft_primary_hover = Private.Hover.bg Colors.Background.soft_primary_hover
let bg_soft_primary_active = Private.Active.bg Colors.Background.soft_primary_active
let bg_soft_secondary = Private.bg Colors.Background.soft_secondary
let bg_soft_secondary_hover = Private.Hover.bg Colors.Background.soft_secondary_hover
let bg_soft_secondary_active = Private.Active.bg Colors.Background.soft_secondary_active
let bg_soft_danger = Private.bg Colors.Background.soft_danger
let bg_soft_danger_hover = Private.Hover.bg Colors.Background.soft_danger_hover
let bg_soft_danger_active = Private.Active.bg Colors.Background.soft_danger_active
let bg_soft_success = Private.bg Colors.Background.soft_success
let bg_soft_success_hover = Private.Hover.bg Colors.Background.soft_success_hover
let bg_soft_success_active = Private.Active.bg Colors.Background.soft_success_active
let bg_soft_warning = Private.bg Colors.Background.soft_warning
let bg_soft_warning_hover = Private.Hover.bg Colors.Background.soft_warning_hover
let bg_soft_warning_active = Private.Active.bg Colors.Background.soft_warning_active

(* Background ghost intents. *)
let bg_primary_ghost_hover = Private.Hover.bg Colors.Background.primary_ghost_hover
let bg_primary_ghost_active = Private.Active.bg Colors.Background.primary_ghost_active
let bg_secondary_ghost_hover = Private.Hover.bg Colors.Background.secondary_ghost_hover
let bg_secondary_ghost_active = Private.Active.bg Colors.Background.secondary_ghost_active
let bg_danger_ghost_hover = Private.Hover.bg Colors.Background.danger_ghost_hover
let bg_danger_ghost_active = Private.Active.bg Colors.Background.danger_ghost_active
let bg_success_ghost_hover = Private.Hover.bg Colors.Background.success_ghost_hover
let bg_success_ghost_active = Private.Active.bg Colors.Background.success_ghost_active
let bg_warning_ghost_hover = Private.Hover.bg Colors.Background.warning_ghost_hover
let bg_warning_ghost_active = Private.Active.bg Colors.Background.warning_ghost_active
