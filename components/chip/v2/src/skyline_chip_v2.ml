open! Core
open! Bonsai_web
open! Private_skyline_prelude

module Variant = struct
  type t =
    | Filled
    | Soft
    | Outlined
    | Dashed
  [@@deriving enumerate, to_string ~capitalize:"Sentence case"]
end

module Color = struct
  module Hue = struct
    type t =
      [ `Red
      | `Orange
      | `Amber
      | `Yellow
      | `Lime
      | `Green
      | `Emerald
      | `Teal
      | `Cyan
      | `Sky
      | `Blue
      | `Indigo
      | `Violet
      | `Purple
      | `Fuchsia
      | `Pink
      | `Rose
      | `Zinc
      ]
    [@@deriving enumerate, to_string, equal, compare]

    let to_tailwind_hue = function
      | `Red -> `red
      | `Orange -> `orange
      | `Amber -> `amber
      | `Yellow -> `yellow
      | `Lime -> `lime
      | `Green -> `green
      | `Emerald -> `emerald
      | `Teal -> `teal
      | `Cyan -> `cyan
      | `Sky -> `sky
      | `Blue -> `blue
      | `Indigo -> `indigo
      | `Violet -> `violet
      | `Purple -> `purple
      | `Fuchsia -> `fuchsia
      | `Pink -> `pink
      | `Rose -> `rose
      | `Zinc -> `slate
    ;;
  end

  type t =
    [ Skyline_intent.t
    | Hue.t
    ]
  [@@deriving enumerate, to_string ~capitalize:"Sentence case"]
end

module Style = struct
  let base = Attr.many Classes.[ inline_flex; items_center; font_medium; text_xs ]

  let border_radius size ~pill =
    if pill
    then {%css|border-radius: 1000px;|}
    else (
      match size with
      | `Xs -> Classes.rounded_xs
      | `Sm -> Classes.rounded_sm
      | `Md -> Classes.rounded_md
      | `Lg -> Classes.rounded_lg)
  ;;

  let padding size ~pill =
    let open Classes in
    match size with
    | `Xs ->
      let px = px (if pill then 1.75 else 1.25) in
      let py = py 0. in
      Attr.many [ px; py ]
    | `Sm ->
      let px = px (if pill then 1.75 else 1.25) in
      let py = py 0.25 in
      Attr.many [ px; py ]
    | `Md ->
      let px = px (if pill then 1.75 else 1.25) in
      let py = py 0.5 in
      Attr.many [ px; py ]
    | `Lg ->
      let px = px 2.25 in
      let py = py 1. in
      Attr.many [ px; py ]
  ;;

  let of_size size ~pill = Attr.many [ border_radius size ~pill; padding size ~pill ]

  type colors =
    { background : Css_gen.Color.t
    ; text : Css_gen.Color.t
    ; border : Css_gen.Color.t
    }

  let intent_colors ~variant (intent : Skyline_intent.t) =
    let open Colors in
    match variant, intent with
    | Variant.Filled, `Primary ->
      { background = Background.primary
      ; text = Text.on_filled_primary
      ; border = transparent
      }
    | Filled, `Success ->
      { background = Background.success
      ; text = Text.on_filled_success
      ; border = transparent
      }
    | Filled, `Warning ->
      { background = Background.warning
      ; text = Text.on_filled_warning
      ; border = transparent
      }
    | Filled, `Danger ->
      { background = Background.danger
      ; text = Text.on_filled_danger
      ; border = transparent
      }
    | Filled, `Secondary ->
      { background = Background.secondary
      ; text = Text.on_filled_secondary
      ; border = Border.default
      }
    | Soft, `Primary ->
      { background = Background.soft_primary
      ; text = Text.on_soft_primary
      ; border = transparent
      }
    | Soft, `Success ->
      { background = Background.soft_success
      ; text = Text.on_soft_success
      ; border = transparent
      }
    | Soft, `Warning ->
      { background = Background.soft_warning
      ; text = Text.on_soft_warning
      ; border = transparent
      }
    | Soft, `Danger ->
      { background = Background.soft_danger
      ; text = Text.on_soft_danger
      ; border = transparent
      }
    | Soft, `Secondary ->
      { background = Background.soft_secondary
      ; text = Text.on_soft_secondary
      ; border = transparent
      }
    | (Outlined | Dashed), `Primary ->
      { background = transparent; text = Text.primary; border = Border.primary }
    | (Outlined | Dashed), `Success ->
      { background = transparent; text = Text.success; border = Border.success }
    | (Outlined | Dashed), `Warning ->
      { background = transparent; text = Text.warning; border = Border.warning }
    | (Outlined | Dashed), `Danger ->
      { background = transparent; text = Text.danger; border = Border.danger }
    | (Outlined | Dashed), `Secondary ->
      { background = transparent; text = Text.secondary; border = Border.default }
  ;;

  let hue_colors ~variant hue =
    let light_dark light dark =
      Css_gen.Color.light_dark (light :> Css_gen.Color.t) (dark :> Css_gen.Color.t)
    in
    match variant with
    | Variant.Filled ->
      let is_secondary = Tailwind_colors.Stable.Hue.V1.equal hue `zinc in
      let background =
        let light =
          if is_secondary
          then Tailwind_colors.create hue `_200
          else Tailwind_colors.create hue `_500
        in
        let dark =
          if is_secondary
          then Tailwind_colors.create hue `_600
          else Tailwind_colors.create hue `_500
        in
        light_dark light dark
      in
      let text =
        let light =
          if is_secondary then Tailwind_colors.black else Tailwind_colors.white
        in
        let dark = `Name "white" in
        light_dark light dark
      in
      let border =
        let light =
          if is_secondary
          then (Tailwind_colors.create hue `_300 :> Css_gen.Color.t)
          else `Name "transparent"
        in
        let dark = `Name "transparent" in
        light_dark light dark
      in
      { background; text; border }
    | Soft ->
      let base_color = (Tailwind_colors.create hue `_500 :> Css_gen.Color.t) in
      let background =
        let fade = Css_gen.Color.mix ~from:base_color ~to_:(`Name "transparent") in
        let light = fade (Percent.of_percentage 92.) in
        let dark = fade (Percent.of_percentage 80.) in
        light_dark light dark
      in
      let text =
        let light = Tailwind_colors.create hue `_600 in
        let dark = Tailwind_colors.create hue `_100 in
        light_dark light dark
      in
      let border = `Name "transparent" in
      { background; text; border }
    | Outlined | Dashed ->
      let background = `Name "transparent" in
      let text =
        let light = Tailwind_colors.create hue `_600 in
        let dark = Tailwind_colors.create hue `_500 in
        light_dark light dark
      in
      let border =
        let light = Tailwind_colors.create hue `_300 in
        let dark = Tailwind_colors.create hue `_400 in
        light_dark light dark
      in
      { background; text; border }
  ;;

  let of_variant ~variant ~color =
    let { background; text; border } =
      match color with
      | #Skyline_intent.t as intent -> intent_colors ~variant intent
      (* Zinc looks really bad if it uses the same heuristics as the rest of the hues.
         Therefore we single it out and map it to `Secondary. We could have special cased
         it within the [intent_colors] function, but this keeps the overall logic nicer. *)
      | `Zinc -> intent_colors ~variant `Secondary
      | `Green -> intent_colors ~variant `Success
      | `Amber -> intent_colors ~variant `Warning
      | #Color.Hue.t as hue -> hue_colors ~variant (Color.Hue.to_tailwind_hue hue)
    in
    let border_style =
      match variant with
      | Variant.Dashed -> "dashed"
      | Filled | Soft | Outlined -> "solid"
    in
    {%css|
      background-color: %{background#Css_gen.Color};
      color: %{text#Css_gen.Color};
      /* We want this 1px to render as a true 1px hairline on high DPI screens (aka
         0.66px), so we avoid `box-shadow` here.
         We use `outline` instead of `border` because we want to be able to specify
         `padding` in whole px values. (If we used `border` we would have to specify a
         1.33px border.) */
      outline: 1px %{border_style} %{border#Css_gen.Color};
      outline-offset: -1px;
    |}
  ;;

  let make ~size ~variant ~pill ~color ~attrs =
    [ base; of_size size ~pill; of_variant ~variant ~color; Attr.many attrs ]
  ;;
end

let view
  ?test_selector
  ?(attrs = [])
  ?(size = `Md)
  ?(variant = Variant.Filled)
  ?(pill = false)
  ?(color : Color.t = `Secondary)
  (content : Node.t list)
  =
  let attrs = Style.make ~size ~variant ~pill ~color ~attrs in
  {%html|
    <div
      %{Test_selector.attr_of_opt test_selector}
      %{Attr.many attrs}
      %{Classes.data_skyline_component "chip"}
    >
      *{content}
    </div>
  |}
;;

module For_docs = struct
  let ml_filepath = __FILE__
end
