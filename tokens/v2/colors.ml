open! Core

module Vscode = struct
  module Stylesheet =
    (* Inject some global CSS variables that defines our color palette. Crucially, these
       variables are only properly defined if we're in a VSCode webview. *)
    [%css
    stylesheet
      ~dont_hash:
        [ (* VSCode gives us a limited color palette from which we must derive our other
             colors. *)
          "--vscode-editor-background"
        ; "--vscode-editor-foreground"
        ; "--vscode-button-background"
        ; "--vscode-button-hoverBackground"
        ; "--vscode-button-foreground"
        ; "--vscode-editorWarning-foreground"
        ]
      {|
        html {
          --vscode-bg-app: var(--vscode-editor-background);
          --vscode-bg-primary: var(--vscode-button-background);
          --vscode-bg-primary-hover: var(--vscode-button-hoverBackground);
          --vscode-bg-primary-active: color-mix(
            in oklch,
            var(--vscode-button-background),
            var(--vscode-editor-foreground) 10%
          );

          --vscode-bg-primary-ghost-hover: color-mix(
            in oklch,
            transparent,
            var(--vscode-button-background) 8%
          );
          --vscode-bg-primary-ghost-active: color-mix(
            in oklch,
            transparent,
            var(--vscode-button-background) 16%
          );

          --vscode-text-default: var(--vscode-editor-foreground);
          --vscode-text-primary: color-mix(
            in oklch,
            var(--vscode-button-background),
            var(--vscode-button-foreground) 20%
          );
          --vscode-text-on-filled-primary: var(--vscode-button-foreground);

          --vscode-text-warning: var(--vscode-editorWarning-foreground);
          --vscode-bg-warning-alt: color-mix(
            in oklch,
            var(--vscode-bg-app),
            var(--vscode-editorWarning-foreground) 20%
          );

          --vscode-bg-one: color-mix(
            in oklch,
            var(--vscode-bg-app),
            var(--vscode-text-default) 5%
          );
          --vscode-bg-two: color-mix(
            in oklch,
            var(--vscode-bg-app),
            var(--vscode-text-default) 15%
          );
          --vscode-bg-three: color-mix(
            in oklch,
            var(--vscode-bg-app),
            var(--vscode-text-default) 25%
          );
        }
      |}]

  let bg_app = Stylesheet.For_referencing.vscode_bg_app
  let bg_one = Stylesheet.For_referencing.vscode_bg_one
  let bg_two = Stylesheet.For_referencing.vscode_bg_two
  let bg_three = Stylesheet.For_referencing.vscode_bg_three
  let text_default = Stylesheet.For_referencing.vscode_text_default
  let text_primary = Stylesheet.For_referencing.vscode_text_primary
  let bg_primary = Stylesheet.For_referencing.vscode_bg_primary
  let bg_primary_hover = Stylesheet.For_referencing.vscode_bg_primary_hover
  let bg_primary_active = Stylesheet.For_referencing.vscode_bg_primary_active
  let bg_primary_ghost_hover = Stylesheet.For_referencing.vscode_bg_primary_ghost_hover
  let bg_primary_ghost_active = Stylesheet.For_referencing.vscode_bg_primary_ghost_active
  let text_on_filled_primary = Stylesheet.For_referencing.vscode_text_on_filled_primary
  let text_warning = Stylesheet.For_referencing.vscode_text_warning
  let bg_warning_alt = Stylesheet.For_referencing.vscode_bg_warning_alt
end

let with_vscode_override name color : Css_gen.Color.t = `Var_with_default (name, color)

let color ~light ~dark =
  Css_gen.Color.light_dark (light :> Css_gen.Color.t) (dark :> Css_gen.Color.t)
;;

(* [a] matches figma units, which is int percents. 16 means 16%. *)
let alpha oklch a =
  match oklch with
  | `OKLCHA oklch ->
    `OKLCHA
      (Css_gen.Color.OKLCHA.create
         ~l:(Css_gen.Color.OKLCHA.l oklch)
         ~c:(Css_gen.Color.OKLCHA.c oklch)
         ~h:(Css_gen.Color.OKLCHA.h oklch)
         ~a:(Percent.of_percentage (Float.of_int a))
         ())
;;

open Tailwind_colors

let transparent = `Name "transparent"

module Text = struct
  (* Base text colors. *)
  let default =
    color ~light:zinc900 ~dark:white |> with_vscode_override Vscode.text_default
  ;;

  let inverse = color ~light:white ~dark:zinc900
  let link = color ~light:blue500 ~dark:blue500
  let secondary = color ~light:zinc500 ~dark:zinc400
  let disabled = color ~light:zinc400 ~dark:zinc500
  let input_placeholder = color ~light:zinc400 ~dark:zinc400

  let primary =
    color ~light:blue600 ~dark:blue400 |> with_vscode_override Vscode.text_primary
  ;;

  let danger = color ~light:red600 ~dark:red400
  let success = color ~light:green600 ~dark:green400

  let warning =
    color ~light:amber600 ~dark:amber400 |> with_vscode_override Vscode.text_warning
  ;;

  (* Text on filled. *)
  let on_filled_primary =
    color ~light:white ~dark:white |> with_vscode_override Vscode.text_on_filled_primary
  ;;

  let on_filled_secondary = default
  let on_filled_danger = on_filled_primary
  let on_filled_success = on_filled_primary
  let on_filled_warning = on_filled_primary

  (* Text on filled alt. *)
  let on_filled_alt_primary = color ~light:blue700 ~dark:blue200
  let on_filled_alt_secondary = secondary
  let on_filled_alt_danger = color ~light:red700 ~dark:red200
  let on_filled_alt_success = color ~light:green700 ~dark:green200
  let on_filled_alt_warning = color ~light:amber700 ~dark:amber200

  (* Text on soft / ghost. *)
  let on_soft_primary = color ~light:blue600 ~dark:blue500
  let on_soft_secondary = color ~light:zinc900 ~dark:zinc400
  let on_soft_danger = color ~light:red600 ~dark:red500
  let on_soft_success = color ~light:green600 ~dark:green500
  let on_soft_warning = color ~light:amber600 ~dark:amber500
end

module Shadow = struct
  (* Shadows. *)
  let default = color ~light:(alpha zinc300 40) ~dark:(alpha white 20)
  let primary = color ~light:(alpha blue500 24) ~dark:(alpha blue500 32)
  let danger = color ~light:(alpha red500 24) ~dark:(alpha red500 32)
  let success = color ~light:(alpha green500 24) ~dark:(alpha green500 32)
  let warning = color ~light:(alpha amber500 24) ~dark:(alpha amber500 32)
end

module Outline = struct
  let default_focus_visible = color ~light:(alpha zinc300 40) ~dark:(alpha zinc300 40)
  let primary_focus_visible = color ~light:(alpha blue500 40) ~dark:(alpha blue500 40)
  let danger_focus_visible = color ~light:(alpha red500 40) ~dark:(alpha red500 40)
  let success_focus_visible = color ~light:(alpha green500 40) ~dark:(alpha green500 40)
  let warning_focus_visible = color ~light:(alpha amber500 40) ~dark:(alpha amber500 40)
end

module Border = struct
  (* Border colors. *)
  let default = color ~light:(alpha zinc900 16) ~dark:(alpha white 24)
  let default_alt = color ~light:(alpha zinc900 32) ~dark:(alpha white 40)
  let primary = color ~light:blue500 ~dark:blue500
  let danger = color ~light:red500 ~dark:red500
  let success = color ~light:green500 ~dark:green500
  let warning = color ~light:amber500 ~dark:amber500
end

module Background = struct
  (* Background surface. *)
  let one = color ~light:white ~dark:zinc800 |> with_vscode_override Vscode.bg_one
  let two = color ~light:zinc50 ~dark:zinc700 |> with_vscode_override Vscode.bg_two
  let three = color ~light:zinc100 ~dark:zinc600 |> with_vscode_override Vscode.bg_three
  let app = color ~light:zinc50 ~dark:zinc900 |> with_vscode_override Vscode.bg_app
  let input = color ~light:white ~dark:(alpha zinc900 40)
  let input_disabled = color ~light:zinc100 ~dark:zinc600
  let input_active = color ~light:white ~dark:zinc900
  let code = color ~light:zinc100 ~dark:zinc600

  (* Background intents. *)
  let primary =
    color ~light:blue500 ~dark:blue600 |> with_vscode_override Vscode.bg_primary
  ;;

  let primary_hover =
    color ~light:blue600 ~dark:blue700 |> with_vscode_override Vscode.bg_primary_hover
  ;;

  let primary_active =
    color ~light:blue800 ~dark:blue900 |> with_vscode_override Vscode.bg_primary_active
  ;;

  let secondary = color ~light:zinc200 ~dark:zinc600
  let secondary_hover = color ~light:zinc300 ~dark:zinc500
  let secondary_active = color ~light:zinc400 ~dark:zinc700
  let danger = color ~light:red500 ~dark:red500
  let danger_hover = color ~light:red600 ~dark:red600
  let danger_active = color ~light:red700 ~dark:red700
  let success = color ~light:green500 ~dark:green500
  let success_hover = color ~light:green600 ~dark:green600
  let success_active = color ~light:green700 ~dark:green700
  let warning = color ~light:amber500 ~dark:amber500
  let warning_hover = color ~light:amber600 ~dark:amber600
  let warning_active = color ~light:amber700 ~dark:amber700

  (* Background alt intents. *)
  let primary_alt = color ~light:blue100 ~dark:blue900
  let secondary_alt = color ~light:zinc100 ~dark:zinc900
  let danger_alt = color ~light:red100 ~dark:red900
  let success_alt = color ~light:green100 ~dark:green900

  let warning_alt =
    color ~light:amber100 ~dark:amber900 |> with_vscode_override Vscode.bg_warning_alt
  ;;

  (* Background soft intents. *)
  let soft_primary = color ~light:(alpha blue500 8) ~dark:(alpha blue500 20)
  let soft_primary_hover = color ~light:(alpha blue500 16) ~dark:(alpha blue500 40)
  let soft_primary_active = color ~light:(alpha blue500 32) ~dark:(alpha blue500 60)
  let soft_secondary = color ~light:(alpha zinc500 8) ~dark:(alpha zinc500 20)
  let soft_secondary_hover = color ~light:(alpha zinc500 16) ~dark:(alpha zinc500 40)
  let soft_secondary_active = color ~light:(alpha zinc500 32) ~dark:(alpha zinc500 60)
  let soft_danger = color ~light:(alpha red500 8) ~dark:(alpha red500 20)
  let soft_danger_hover = color ~light:(alpha red500 16) ~dark:(alpha red500 40)
  let soft_danger_active = color ~light:(alpha red500 32) ~dark:(alpha red500 60)
  let soft_success = color ~light:(alpha green500 8) ~dark:(alpha green500 20)
  let soft_success_hover = color ~light:(alpha green500 16) ~dark:(alpha green500 40)
  let soft_success_active = color ~light:(alpha green500 32) ~dark:(alpha green500 60)
  let soft_warning = color ~light:(alpha amber500 8) ~dark:(alpha amber500 20)
  let soft_warning_hover = color ~light:(alpha amber500 16) ~dark:(alpha amber500 40)
  let soft_warning_active = color ~light:(alpha amber500 32) ~dark:(alpha amber500 60)

  (* Background ghost intents. *)
  let primary_ghost_hover =
    color ~light:(alpha blue500 8) ~dark:(alpha blue500 24)
    |> with_vscode_override Vscode.bg_primary_ghost_hover
  ;;

  let primary_ghost_active =
    color ~light:(alpha blue500 16) ~dark:(alpha blue500 16)
    |> with_vscode_override Vscode.bg_primary_ghost_active
  ;;

  let secondary_ghost_hover = color ~light:(alpha zinc500 8) ~dark:(alpha zinc500 24)
  let secondary_ghost_active = color ~light:(alpha zinc500 16) ~dark:(alpha zinc500 16)
  let danger_ghost_hover = color ~light:(alpha red500 8) ~dark:(alpha red500 24)
  let danger_ghost_active = color ~light:(alpha red500 16) ~dark:(alpha red500 16)
  let success_ghost_hover = color ~light:(alpha green500 8) ~dark:(alpha green500 24)
  let success_ghost_active = color ~light:(alpha green500 16) ~dark:(alpha green500 16)
  let warning_ghost_hover = color ~light:(alpha amber500 8) ~dark:(alpha amber500 24)
  let warning_ghost_active = color ~light:(alpha amber500 16) ~dark:(alpha amber500 16)
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
