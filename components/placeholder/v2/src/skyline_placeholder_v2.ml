open! Core
open! Private_skyline_prelude

module Style = struct
  let title_text_size = function
    | `Xs -> Classes.text_default
    | `Sm -> Classes.text_lg
    | `Md -> Classes.text_xl
    | `Lg -> Classes.text_2xl
  ;;

  let container_gap_and_padding = function
    | `Xs -> Classes.[ gap 2.; p 1. ]
    | `Sm -> Classes.[ gap 3.; p 2. ]
    | `Md -> Classes.[ gap 4.; p 4. ]
    | `Lg -> Classes.[ gap 6.; p 6. ]
  ;;

  let icon_size = function
    | `Xs -> `Px 24
    | `Sm -> `Px 36
    | `Md -> `Px 48
    | `Lg -> `Px 64
  ;;
end

let view ?test_selector ?(attrs = []) ?(size = `Md) ?icon ~title ~message actions =
  let icon_node =
    let%map.Option icon in
    {%html.jsx|
      <Bonsai_web_icon.view
        ~icon
        ~stroke_width:%{`Px 1}
        ~size:%{Style.icon_size size}
      />
    |}
  in
  let actions_node =
    match actions with
    | [] -> None
    | actions ->
      Some
        {%html.jsx|<div *{Classes.[items_center; flex; flex_col; gap 2.]}>*{actions}</div>|}
  in
  {%html.jsx|
    <div
      *{Classes.[flex; flex_col; items_center; justify_center]}
      *{Style.container_gap_and_padding size}
      %{Test_selector.attr_of_opt test_selector}
      %{Classes.data_skyline_component "placeholder"}
      *{attrs}
    >
      ?{icon_node}
      <div *{Classes.[flex; flex_col; items_center; w_full]} style="text-align: center">
        <span %{Classes.font_bold} %{Style.title_text_size size}
          >#{title}</span
        >
        <Skyline_text_v2.view
          ~size:%{size :> Skyline_text_v2.Size.t}
          ~color:%{`Secondary}
          >%{message}
        </>
      </div>
      ?{actions_node}
    </div>
  |}
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
