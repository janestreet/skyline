open! Core
open! Bonsai_web

let component (local_ _graph) =
  let module Colors = Tailwind_colors in
  let open Private_skyline_utility_classes in
  Bonsai.return
    {%html.jsx|
      <div *{[ flex; flex_row; gap 4.; border 2; border_solid; border_color ~light:Colors.purple500 ~dark:Colors.purple300; bg ~light:Colors.yellow100 ~dark:Colors.yellow900]}>
        <div *{[flex; flex_col; gap 2.]} *{Hover.[bg ~light:Colors.red500 ~dark:Colors.red500]}>
          <div *{[bg_danger; text_secondary; text_2xs]}>Hello!</div>
          <div *{[bg_primary; text_primary; text_xs]}>Hello!</div>
          <div *{[bg_danger; text_primary; text_sm]}>Hello!</div>
          <div *{[bg_primary; text_secondary; text_base]}>Hello!</div>
          <div *{[bg_danger; text_primary; text_lg]}>Hello!</div>
          <div *{[bg_primary; text_primary; text_xl]}>Hello!</div>
          <div *{[bg_danger; text_secondary; text_2xl]}>Hello!</div>
          <div *{[bg_primary; text_primary; text_3xl]}>Hello!</div>
          <div *{[bg_danger; text_primary; text_4xl]}>Hello!</div>
        </div>
      </div>
    |}
;;
