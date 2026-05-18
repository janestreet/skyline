open! Core
open! Bonsai_web

module Code_block_style = struct
  type t =
    | Block
    | Inline
end

let container_with_rounded_corners contents =
  Skyline_flex_v1.column
    ~attrs:
      [ Vdom.Attr.style
          Css_gen.(
            box_sizing `Border_box
            @> uniform_padding (`Px 0)
            @> uniform_margin (`Px 0)
            @> border_radius (`Px 4)
            @> border ~color:Skyline_theme_v1.border ~width:(`Px 1) ~style:`Solid ()
            @> overflow `Hidden)
      ]
    contents
;;

let render_code_block ~language ~style document =
  let language =
    let open Bonsai_web_codemirror_read_only.Language in
    match language with
    | "ocaml" -> OCaml
    | "diff" -> Diff
    | "html" -> Html
    | "css" -> Css
    | "python" | "py" -> Python
    | "lisp" -> Common_lisp
    | "sexp" | "jbuild" -> Sexp
    | "scheme" -> Scheme
    | "sql" -> Sql
    | "javascript" | "js" -> Javascript
    | "markdown" | "md" -> Markdown
    | "php" -> Php
    | "rust" | "rs" -> Rust
    | "xml" -> Xml
    | "fsharp" -> FSharp
    | _ -> Plaintext
  in
  let extension =
    let open Gen_js_api in
    match (style : Code_block_style.t) with
    | Block -> Codemirror.State.Extension.of_list []
    | Inline ->
      Codemirror.State.Extension.of_list
        [ Codemirror.View.Editor_view.line_wrapping
        ; Codemirror.View.Editor_view.theme
            ~spec:
              (Ojs.obj
                 [| "&", Ojs.obj [| "backgroundColor", Ojs.string_to_js "inherit" |]
                  ; ".cm-line", Ojs.obj [| "padding", Ojs.string_to_js "0" |]
                 |])
            ()
        ]
  in
  let codemirror =
    Bonsai_web_codemirror_read_only.make
      ~extension
      ~theme:Vscode_default
      ~language
      document
  in
  match style with
  | Block -> container_with_rounded_corners [ codemirror ]
  | Inline -> codemirror
;;

let buffer = Buffer.create 1024

let read_buffer () =
  let result = Buffer.contents buffer in
  Buffer.clear buffer;
  result
;;

let rec render_inline (inline : Omd.attributes Omd.inline) =
  match inline with
  | Concat (_, xs) ->
    let rec combine_text acc xs =
      match xs with
      | [] -> List.rev (Omd.Text ([], read_buffer ()) :: acc)
      | hd :: tl ->
        let acc =
          match hd with
          | Omd.Text (_, text) ->
            Buffer.add_string buffer text;
            acc
          | Soft_break _ ->
            Buffer.add_char buffer ' ';
            acc
          | _ -> hd :: Text ([], read_buffer ()) :: acc
        in
        combine_text acc tl
    in
    Vdom.Node.span (List.map (combine_text [] xs) ~f:render_inline)
  | Text (_, text) -> Vdom.Node.text text
  | Emph (_, x) -> Skyline_text_v1.span' ~style:Italic [ render_inline x ]
  | Strong (_, x) -> Skyline_text_v1.span' ~style:Bold [ render_inline x ]
  | Code (_, code) ->
    Skyline_text_v1.span
      ~font:Monospace
      ~attrs:
        [ Vdom.Attr.style
            Css_gen.(
              box_sizing `Border_box
              @> padding ~top:(`Px 0) ~right:(`Px 2) ~bottom:(`Px 0) ~left:(`Px 2) ()
              @> uniform_margin (`Px 0)
              @> border_radius (`Px 4)
              @> background_color Skyline_theme_v1.border)
        ]
      code
  | Hard_break _ -> Vdom.Node.br ()
  | Soft_break _ -> Vdom.Node.text " "
  | Link (_, { label; destination; title }) ->
    Skyline_text_v1.link'
      ~href:destination
      ~attrs:
        [ Option.value_map title ~f:Skyline_tooltip_v1.text ~default:Vdom.Attr.empty ]
      [ render_inline label ]
  | Image (_, { label = _; destination; title }) ->
    container_with_rounded_corners
      [ Vdom.Node.img
          ~attrs:
            [ Option.value_map title ~f:Skyline_tooltip_v1.text ~default:Vdom.Attr.empty
            ; Option.value_map title ~f:Vdom.Attr.alt ~default:Vdom.Attr.empty
            ; Vdom.Attr.style (Css_gen.max_width (`Percent Percent.one_hundred_percent))
            ; Vdom.Attr.src destination
            ]
          ()
      ]
  | Html (_, html_text) ->
    Skyline_text_v1.span
      ~font:Monospace
      ~attrs:
        [ Vdom.Attr.style
            Css_gen.(
              box_sizing `Border_box
              @> uniform_padding (`Px 0)
              @> uniform_margin (`Px 0)
              @> white_space `Pre_wrap)
        ]
      html_text
;;

let rec render_block ~code_block_style (block : Omd.attributes Omd.block) =
  match block with
  | Paragraph (_, inline) ->
    Vdom.Node.p
      ~attrs:
        [ Vdom.Attr.style
            Css_gen.(
              box_sizing `Border_box
              @> uniform_padding (`Px 0)
              @> margin ~top:(`Px 4) ~right:(`Px 0) ~bottom:(`Px 4) ~left:(`Px 0) ())
        ]
      [ Skyline_text_v1.span' [ render_inline inline ] ]
  | List (_, list_type, list_spacing, items) ->
    let spacing_attr =
      let style this_margin =
        Vdom.Attr.style
          Css_gen.(
            box_sizing `Border_box
            @> uniform_padding (`Px 0)
            @> margin
                 ~top:this_margin
                 ~right:(`Px 0)
                 ~bottom:this_margin
                 ~left:(`Px 24)
                 ()
            @> create ~field:"list-style-position" ~value:"outside"
            @> create ~field:"word-wrap" ~value:"break-word")
      in
      match list_spacing with
      | Tight -> style (`Px 0)
      | Loose -> style (`Px 4)
    in
    let container =
      match list_type with
      | Ordered (start, type_) ->
        Vdom.Node.ol
          ~attrs:
            [ spacing_attr
            ; Vdom.Attr.start start
            ; Vdom.Attr.type_ (Char.to_string type_)
            ]
      | Bullet type_ ->
        Vdom.Node.ul ~attrs:[ spacing_attr; Vdom.Attr.type_ (Char.to_string type_) ]
    in
    let rendered_items =
      List.map items ~f:(fun item_blocks ->
        Vdom.Node.li (List.map item_blocks ~f:(render_block ~code_block_style)))
    in
    container rendered_items
  | Blockquote (_, blocks) ->
    Vdom.Node.blockquote
      ~attrs:
        [ Vdom.Attr.style
            Css_gen.(
              box_sizing `Border_box
              @> padding ~top:(`Px 0) ~right:(`Px 0) ~bottom:(`Px 0) ~left:(`Px 4) ()
              @> margin ~top:(`Px 12) ~right:(`Px 0) ~bottom:(`Px 12) ~left:(`Px 0) ()
              @> border_left
                   ~width:(`Px 2)
                   ~style:`Solid
                   ~color:Skyline_theme_v1.border
                   ())
        ]
      (List.map blocks ~f:(render_block ~code_block_style))
  | Code_block (_, language, code) ->
    render_code_block ~language ~style:code_block_style code
  | Thematic_break _ ->
    Vdom.Node.div
      ~attrs:
        [ Vdom.Attr.style
            Css_gen.(
              box_sizing `Border_box
              @> uniform_padding (`Px 0)
              @> margin ~top:(`Px 4) ~right:(`Px 0) ~bottom:(`Px 4) ~left:(`Px 0) ())
        ]
      [ Skyline_divider_v1.horizontal () ]
  | Heading (_, level, x) ->
    let heading =
      match level with
      | 1 -> Skyline_text_v1.heading' ~size:Large
      | 2 -> Skyline_text_v1.heading' ~size:Regular
      | 3 | 4 | 5 | 6 | _ -> Skyline_text_v1.heading' ~size:Small
    in
    heading [ render_inline x ]
  | Definition_list (_, definitions) ->
    Vdom.Node.dl
      (List.concat_map definitions ~f:(fun { term; defs } ->
         let dt = Vdom.Node.dt [ render_inline term ] in
         let dds = List.map defs ~f:(fun def -> Vdom.Node.dd [ render_inline def ]) in
         dt :: dds))
  | Table (_, header_row, data_rows) ->
    let alignment_style alignment =
      match alignment with
      | Omd.Left -> Css_gen.text_align `Left
      | Right -> Css_gen.text_align `Right
      | Centre -> Css_gen.text_align `Center
      | Default -> Css_gen.empty
    in
    let render_row data_row =
      let data_and_headers = List.zip data_row header_row in
      match data_and_headers with
      | Ok data_and_headers ->
        Vdom.Node.tr
          (List.map data_and_headers ~f:(fun (data, (_header, alignment)) ->
             Vdom.Node.td
               ~attrs:[ Vdom.Attr.style (alignment_style alignment) ]
               [ render_inline data ]))
      | Unequal_lengths ->
        Vdom.Node.tr
          (List.map data_row ~f:(fun data -> Vdom.Node.td [ render_inline data ]))
    in
    Vdom.Node.table
      [ Vdom.Node.thead
          (List.map header_row ~f:(fun (header, alignment) ->
             Vdom.Node.th
               ~attrs:[ Vdom.Attr.style (alignment_style alignment) ]
               [ render_inline header ]))
      ; Vdom.Node.tbody (List.map data_rows ~f:(fun data_row -> render_row data_row))
      ]
  | Html_block (_, html_text) ->
    render_code_block ~language:"html" ~style:Inline html_text
;;

let component ?(code_block_style = Code_block_style.Block) markdown =
  try
    let doc = Omd.of_string markdown in
    let rendered_blocks = List.map doc ~f:(render_block ~code_block_style) in
    Vdom.Node.div
      ~attrs:
        [ Vdom.Attr.style
            Css_gen.(
              box_sizing `Border_box
              @> uniform_padding (`Px 0)
              @> uniform_margin (`Px 0)
              @> create ~field:"word-wrap" ~value:"break-word")
        ]
      rendered_blocks
  with
  | exn ->
    Skyline_placeholder_v1.error
      (Error.create_s [%message "Markdown parsing failed" ~_:(exn : exn)])
;;
