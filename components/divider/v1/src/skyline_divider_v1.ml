open! Core
open! Private_skyline_prelude

module Style = struct
  let horizontal ~width =
    {%css|
      box-sizing: border-box;
      width: %{width#Css_gen.Length};
      height: 1px;
      margin: 0;
      padding: 0;
      border: 0 solid;
      border-top: 1px solid;
      color: %{Colors.Border.default#Css_gen.Color};
    |}
  ;;

  let vertical ~height =
    {%css|
      box-sizing: border-box;
      width: 1px;
      height: %{height#Css_gen.Length};
      margin: 0;
      padding: 0;
      border: 0 solid;
      border-left: 1px solid;
      color: %{Colors.Border.default#Css_gen.Color};
    |}
  ;;

  let symbol ~line_height =
    {%css|
      color: %{Colors.Text.secondary#Css_gen.Color};
      line-height: %{line_height#Css_gen.Length};
      user-select: none;
    |}
  ;;
end

let horizontal ?(attrs = []) ?(length = `Percent Percent.one_hundred_percent) () =
  {%html|<hr %{Style.horizontal ~width:length} *{attrs} />|}
;;

let vertical ?(attrs = []) ?(length = `Percent Percent.one_hundred_percent) () =
  {%html|<hr %{Style.vertical ~height:length} *{attrs} />|}
;;

let interpunct =
  {%html|
    <span %{Style.symbol
        (* Set small line height so that the interpunct is centered correctly e.g. when in
           a flex container with [Small] text. *)
          ~line_height:(`Px 4)}>#{"\u{00B7}"}</span>
  |}
;;

let slash = {%html|<span %{Style.symbol ~line_height:(`Em 1)}>#{"/"}</span>|}

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
