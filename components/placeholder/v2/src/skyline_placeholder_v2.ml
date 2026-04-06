open! Core
open! Private_skyline_prelude

let view ?test_selector ?(attrs = []) ?icon ~title ~message actions =
  let icon_node =
    let%map.Option icon in
    {%html|
      <Bonsai_web_icon.view
        ~icon
        ~stroke_width:%{`Px 1}
        ~size:%{`Px 56}
      />
    |}
  in
  let actions_node =
    match actions with
    | [] -> None
    | actions ->
      Some
        {%html|<div *{Classes.[items_center; flex; flex_col; gap 2.]}>*{actions}</div>|}
  in
  {%html|
    <div
      *{Classes.[flex; flex_col; items_center; justify_center; w_full; gap 4.]}
      %{Test_selector.attr_of_opt test_selector}
      %{Classes.data_skyline_component "placeholder"}
      *{attrs}
    >
      ?{icon_node}
      <div *{Classes.[flex; flex_col; items_center; max_w 90.]} style="text-align: center">
        <span *{Classes.[ font_bold; text_lg ]}>#{title}</span>
        <Skyline_text_v2.view ~size:%{`Md} ~color:%{`Secondary}
          >%{message}
        </>
      </div>
      ?{actions_node}
    </div>
  |}
;;

module For_docs = struct
  let ml_filepath = __FILE__
end
