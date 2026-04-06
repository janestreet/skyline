open! Core
open! Js_of_ocaml
open! Css_gen

module type S_base = sig
  type color

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

module type S_shadow = sig
  type color

  val shadow : color
end

module type S_ui = sig
  type color

  val primary : color
  val background : color
  val placeholder : color
  val success : color
  val warning : color
  val error : color
end

module type S_derived = sig
  type color

  val accent : color
  val surface : color
  val border : color
end

module type S = sig
  type color

  include S_ui with type color := color
  include S_derived with type color := color
  include S_base with type color := color
end

module type S_theme = sig
  include S_base with type color := Color.t
  include S_ui with type color := Color.t
  include S_shadow with type color := Color.t
end

module Dark : S_theme = struct
  let black = `Hex "#1E1E1E"
  let white = `Hex "#D4D4D4"
  let blue = `Hex "#3794FF"
  let green = `Hex "#57c961"
  let yellow = `Hex "#ffbe01"
  let red = `Hex "#F14C4C"
  let clay = `Hex "#EE9D28"
  let lavender = `Hex "#B180D7"
  let marina = `Hex "#4EC9B0"
  let moss = `Hex "#6A9955"
  let mud = `Hex "#DCDCAA"

  (**)
  let primary = white
  let background = black
  let placeholder = `Hex "#EEE1"

  (**)
  let success = green
  let warning = yellow
  let error = red

  (**)
  let shadow =
    `RGBA (Css_gen.Color.RGBA.create () ~r:0 ~g:0 ~b:0 ~a:(Percent.of_percentage 30.))
  ;;
end

module Light : S_theme = struct
  let black = `Hex "#3B3B3B"
  let white = `Hex "#FFFFFF"
  let blue = `Hex "#1f7eeb"
  let green = `Hex "#177c1f"
  let yellow = `Hex "#ac8100"
  let red = `Hex "#da3a3a"
  let clay = `Hex "#D67E00"
  let lavender = `Hex "#652D90"
  let marina = `Hex "#267F99"
  let moss = `Hex "#008000"
  let mud = `Hex "#795E26"

  (**)
  let primary = black
  let background = white
  let placeholder = `Hex "#EEE1"

  (**)
  let success = green
  let warning = yellow
  let error = red

  (**)
  let shadow =
    `RGBA (Css_gen.Color.RGBA.create () ~r:0 ~g:0 ~b:0 ~a:(Percent.of_percentage 10.))
  ;;
end

module Vscode : S_theme = struct
  let black = `Hex "#000000"
  let white = `Hex "#FFFFFF"
  let blue = `Var "--vscode-textLink-foreground"
  let green = `Var "--vscode-testing-iconPassed"
  let yellow = `Var "--vscode-editorWarning-foreground"
  let red = `Var "--vscode-editorError-foreground"

  (**)
  let clay = `Var "--vscode-symbolIcon-classForeground"
  let lavender = `Var "--vscode-symbolIcon-functionForeground"
  let marina = `Var "--vscode-symbolIcon-variableForeground"
  let moss = green
  let mud = yellow

  (**)
  let primary = `Var "--vscode-editor-foreground"
  let background = `Var "--vscode-editor-background"
  let placeholder = `Hex "#EEE1"

  (**)
  let success = green
  let warning = yellow
  let error = red

  (**)
  let shadow =
    `RGBA (Css_gen.Color.RGBA.create () ~r:0 ~g:0 ~b:0 ~a:(Percent.of_percentage 20.))
  ;;
end

module Constants = struct
  let var ~default name = `Var_with_default (name, default)

  (* Base colors *)
  let black = var ~default:Light.black "--skyline-color-black"
  let white = var ~default:Light.white "--skyline-color-white"
  let blue = var ~default:Light.blue "--skyline-color-blue"
  let green = var ~default:Light.green "--skyline-color-green"
  let yellow = var ~default:Light.yellow "--skyline-color-yellow"
  let red = var ~default:Light.red "--skyline-color-red"
  let clay = var ~default:Light.clay "--skyline-color-clay"
  let lavender = var ~default:Light.lavender "--skyline-color-lavender"
  let marina = var ~default:Light.marina "--skyline-color-marina"
  let moss = var ~default:Light.moss "--skyline-color-moss"
  let mud = var ~default:Light.mud "--skyline-color-mud"

  (* UI colors *)
  let primary = var ~default:Light.primary "--skyline-color-primary"
  let background = var ~default:Light.background "--skyline-color-background"
  let placeholder = var ~default:Light.placeholder "--skyline-color-placeholder"

  (* Intent colors *)
  let success = var ~default:Light.green "--skyline-color-success"
  let warning = var ~default:Light.yellow "--skyline-color-warning"
  let error = var ~default:Light.red "--skyline-color-error"
  let ramp color step = Css_gen.Color.mix ~from:background ~to_:color step

  let fade color step =
    Css_gen.Color.mix
      ~from:color
      ~to_:(`Name "transparent")
      (Percent.of_mult (1.0 -. Percent.to_mult step))
  ;;

  (* Derived colors *)
  let accent = var ~default:Light.blue "--skyline-color-accent"

  let derive_surface pct ~primary =
    Css_gen.Color.mix (Percent.of_percentage 1.5) ~to_:accent ~from:(ramp primary pct)
  ;;

  let surface =
    var
      ~default:(derive_surface (Percent.of_percentage 5.) ~primary)
      "--skyline-color-surface"
  ;;

  let derive_border ~primary = fade primary (Percent.of_percentage 20.)
  let border = var ~default:(derive_border ~primary) "--skyline-color-border"
end

let set_css_property' name value =
  Dom_html.document##.documentElement##.style##setProperty
    (Js.string name)
    (Js.string value)
    Js.undefined
  |> (ignore : _ Js.t -> unit)
;;

let set_css_property (`Var_with_default (name, _)) value =
  set_css_property' name (Css_gen.Color.to_string_css value)
;;

let install (style : Style.t) ~accent =
  let (module Colors : S_theme) =
    match style with
    | Dark -> (module Dark)
    | Light -> (module Light)
    | Vscode _ -> (module Vscode)
  in
  (* Named colors *)
  set_css_property Constants.black Colors.black;
  set_css_property Constants.white Colors.white;
  set_css_property Constants.blue Colors.blue;
  set_css_property Constants.green Colors.green;
  set_css_property Constants.yellow Colors.yellow;
  set_css_property Constants.red Colors.red;
  (* Additional named colors *)
  set_css_property Constants.clay Colors.clay;
  set_css_property Constants.lavender Colors.lavender;
  set_css_property Constants.marina Colors.marina;
  set_css_property Constants.moss Colors.moss;
  set_css_property Constants.mud Colors.mud;
  (* UI colors *)
  set_css_property Constants.primary Colors.primary;
  set_css_property Constants.background Colors.background;
  set_css_property Constants.placeholder Colors.placeholder;
  (* Intent colors *)
  set_css_property Constants.success Colors.success;
  set_css_property Constants.warning Colors.warning;
  set_css_property Constants.error Colors.error;
  (* Derived UI colors *)
  set_css_property Constants.border (Constants.derive_border ~primary:Colors.primary);
  set_css_property
    Constants.accent
    (match accent with
     | `Blue -> Colors.blue
     | `Clay -> Colors.clay
     | `Lavender -> Colors.lavender
     | `Marina -> Colors.marina
     | `Moss -> Colors.moss
     | `Mud -> Colors.mud);
  (* Surface ramp *)
  set_css_property
    Constants.surface
    (Constants.derive_surface ~primary:Colors.primary (Percent.of_percentage 5.));
  set_css_property'
    "--skyline-color-surface-nested-first"
    (Constants.derive_surface ~primary:Colors.primary (Percent.of_percentage 5.)
     |> Css_gen.Color.to_string_css);
  set_css_property'
    "--skyline-color-surface-nested-second"
    (Constants.derive_surface ~primary:Colors.primary (Percent.of_percentage 10.)
     |> Css_gen.Color.to_string_css);
  set_css_property'
    "--skyline-color-surface-nested-third"
    (Constants.derive_surface ~primary:Colors.primary (Percent.of_percentage 15.)
     |> Css_gen.Color.to_string_css);
  (* Shadows *)
  set_css_property' "--skyline-shadow" (Css_gen.Color.to_string_css Colors.shadow);
  (* Fonts *)
  set_css_property' "--skyline-font-sans" "Inter, sans-serif";
  set_css_property' "--skyline-font-mono" "'Fira Mono', monospace";
  (* Color-scheme *)
  let color_scheme =
    match style with
    | Dark | Vscode { is_dark = true } -> "dark"
    | Light | Vscode { is_dark = false } -> "light"
  in
  set_css_property' "--skyline-color-scheme" color_scheme;
  set_css_property' "color-scheme" color_scheme
;;

let clear () =
  let style = Js.Unsafe.coerce Dom_html.document##.documentElement##.style in
  let length = Int.of_float (Js.to_float style##.length) in
  for idx = 0 to length - 1 do
    let (property : Js.js_string Js.t) =
      Js.Optdef.get (Js.array_get style idx) (fun () -> Js.string "")
    in
    if String.is_prefix (Js.to_string property) ~prefix:"--skyline-"
    then style##removeProperty property
  done
;;
