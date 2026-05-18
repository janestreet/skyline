open! Skyline_tokens_v2

(* $MDX part-begin=ppx_css_usage *)
let _styles =
  {%css|
    color: %{Colors.Text.primary#Css_gen.Color};
    background-color: %{Colors.Background.one#Css_gen.Color};
    border: 1px solid %{Colors.Border.default#Css_gen.Color};
    padding: 16px;
  |}
;;

(* $MDX part-end *)

(* $MDX part-begin=custom_color *)
let _custom = Colors.color ~light:(`Hex "#1a1a1a") ~dark:(`Hex "#fafafa")
(* $MDX part-end *)
