open! Core
open! Bonsai_web

module Font_family = struct
  type t =
    | Sans_serif
    | Monospace
  [@@deriving sexp_of, equal, compare]
end

module Font_style = struct
  type t =
    | Regular
    | Medium_weight
    | Bold
    | Italic
  [@@deriving sexp_of, equal, compare]
end

module Font_size = struct
  type t =
    | Small
    | Regular
    | Large
  [@@deriving sexp_of, equal, compare]
end

module Text_decoration = struct
  type t =
    | None
    | Underline
    | Line_through
  [@@deriving sexp_of, equal, compare]
end

let font_family (family : Font_family.t) =
  match family with
  | Sans_serif -> Css_gen.create ~field:"font-family" ~value:"var(--skyline-font-sans)"
  | Monospace -> Css_gen.create ~field:"font-family" ~value:"var(--skyline-font-mono)"
;;

let font_size kind (size : Font_size.t) =
  let length =
    match kind, size with
    | `Heading, Large -> Private_skyline_theme.Typography.extra_large_font_size
    | `Heading, Regular | `Span, Large -> Private_skyline_theme.Typography.large_font_size
    | `Heading, Small | `Span, Regular ->
      Private_skyline_theme.Typography.regular_font_size
    | `Span, Small -> Private_skyline_theme.Typography.small_font_size
  in
  Css_gen.font_size length
;;

let line_height kind (size : Font_size.t) =
  let line_height =
    match kind, size with
    | `Heading, Large -> `Rem 3.0
    | `Heading, Regular -> Private_skyline_theme.Typography.extra_large_font_size
    | `Heading, Small -> Private_skyline_theme.Typography.large_font_size
    | `Span, Large -> `Rem 1.5
    | `Span, Regular -> `Rem 1.1
    | `Span, Small ->
      (* Intentionally overly-compact. This is for squeezing text in tight spaces - even
         if it feels a bit ugly. *)
      Private_skyline_theme.Typography.small_font_size
  in
  Css_gen.line_height line_height
;;

let font_weight (style : Font_style.t) =
  let weight =
    match style with
    | Regular | Italic -> `Number 400
    | Medium_weight -> `Number 500
    | Bold -> `Number 700
  in
  Css_gen.font_weight weight
;;

let font_style (style : Font_style.t) =
  match style with
  | Bold | Regular | Medium_weight -> Css_gen.empty
  | Italic -> Css_gen.font_style `Italic
;;

let text_decoration (decoration : Text_decoration.t) =
  match decoration with
  | None -> Css_gen.empty
  | Underline -> Css_gen.text_decoration ~line:[ `Underline ] ()
  | Line_through -> Css_gen.text_decoration ~line:[ `Line_through ] ()
;;

let color ~secondary ~intent =
  let fade_50 color =
    Css_gen.color (Skyline_theme_v1.fade color (Percent.of_percentage 50.))
  in
  if secondary
  then fade_50 (Option.value intent ~default:Skyline_theme_v1.primary)
  else Option.value_map intent ~f:Css_gen.color ~default:Css_gen.empty
;;

let style_impl
  ?(font = Font_family.Sans_serif)
  ?(style = Font_style.Regular)
  ?(size = Font_size.Regular)
  ?(decoration = Text_decoration.None)
  ?align
  ?intent
  ~secondary
  kind
  =
  let ( @> ) = Css_gen.( @> ) in
  let text_align =
    match align with
    | None -> Css_gen.empty
    | Some align -> Css_gen.text_align align
  in
  font_family font
  @> font_size kind size
  @> line_height kind size
  @> font_weight style
  @> font_style style
  @> text_decoration decoration
  @> color ~secondary ~intent
  @> text_align
;;

let heading' ?(attrs = []) ?font ?style ?size ?decoration ?align ?intent children =
  let style =
    style_impl ?font ?style ?size ?decoration ?align ?intent ~secondary:false `Heading
  in
  let attrs = Vdom.Attr.style style :: attrs in
  match size with
  | Some Large -> Vdom.Node.h1 ~attrs children
  | None | Some Regular -> Vdom.Node.h2 ~attrs children
  | Some Small -> Vdom.Node.h3 ~attrs children
;;

let heading ?attrs ?font ?style ?size ?decoration ?align ?intent text =
  heading' ?attrs ?font ?style ?size ?decoration ?align ?intent [ Vdom.Node.text text ]
;;

let span'
  ?(attrs = [])
  ?font
  ?style
  ?size
  ?decoration
  ?align
  ?intent
  ?(secondary = false)
  children
  =
  let style = style_impl ?font ?style ?size ?decoration ?align ?intent ~secondary `Span in
  let attrs = Vdom.Attr.style style :: attrs in
  Vdom.Node.span ~attrs children
;;

let span ?attrs ?font ?style ?size ?decoration ?align ?intent ?secondary text =
  span'
    ?attrs
    ?font
    ?style
    ?size
    ?decoration
    ?align
    ?intent
    ?secondary
    [ Vdom.Node.text text ]
;;

let link'
  ?(attrs = [])
  ?font
  ?style
  ?size
  ?(decoration = Text_decoration.Underline)
  ?align
  ?(intent = Skyline_theme_v1.accent)
  ?target
  ~href
  children
  =
  let style =
    style_impl ?font ?style ?size ~decoration ?align ~intent ~secondary:false `Span
  in
  let attrs =
    Vdom.Attr.style style
    :: (match target with
        | Some `Self -> Vdom.Attr.target "_self"
        | Some `Blank -> Vdom.Attr.target "_blank"
        | None -> Vdom.Attr.empty)
    :: Vdom.Attr.href href
    :: attrs
  in
  Vdom.Node.a ~attrs children
;;

let link ?attrs ?font ?style ?size ?decoration ?align ?intent ?target ~href text =
  link'
    ?attrs
    ?font
    ?style
    ?size
    ?decoration
    ?align
    ?intent
    ?target
    ~href
    [ Vdom.Node.text text ]
;;

let link_with_effect'
  ?(attrs = [])
  ?font
  ?style
  ?size
  ?(decoration = Text_decoration.Underline)
  ?align
  ?(intent = Skyline_theme_v1.accent)
  ~on_click
  children
  =
  let style =
    style_impl ?font ?style ?size ~decoration ?align ~intent ~secondary:false `Span
  in
  let attrs = Vdom.Attr.style style :: Vdom.Attr.on_click (fun _ -> on_click) :: attrs in
  Vdom.Node.a ~attrs children
;;

let link_with_effect ?attrs ?font ?style ?size ?decoration ?align ?intent ~on_click text =
  link_with_effect'
    ?attrs
    ?font
    ?style
    ?size
    ?decoration
    ?align
    ?intent
    ~on_click
    [ Vdom.Node.text text ]
;;
