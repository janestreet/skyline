open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
open Gen_js_api

module Language = struct
  type t = Bonsai_web_codemirror_read_only.Language.t =
    | Plaintext
    | OCaml
    | Diff
    | Html
    | Css
    | Python
    | Common_lisp
    | Sexp
    | Scheme
    | Sql
    | Javascript
    | Markdown
    | Php
    | Rust
    | Xml
    | FSharp
  [@@deriving equal, sexp_of]

  let of_filename filename =
    let is_suffix suffix = String.is_suffix filename ~suffix in
    if is_suffix ".md" || is_suffix ".mdx"
    then Markdown
    else if is_suffix ".py"
            || is_suffix ".pyi"
            || is_suffix ".bzl"
            || is_suffix "BUCK"
            || is_suffix "BUILD"
    then Python
    else if is_suffix ".sexp" || is_suffix "jbuild" || is_suffix "dune"
    then Sexp
    else if is_suffix ".el"
    then Common_lisp
    else if is_suffix ".scm" || is_suffix ".ss"
    then Scheme
    else if is_suffix ".sql"
    then Sql
    else if is_suffix ".html"
    then Html
    else if is_suffix ".css"
    then Css
    else if is_suffix ".js" || is_suffix ".ts" || is_suffix ".jsx" || is_suffix ".tsx"
    then Javascript
    else if is_suffix ".php"
    then Php
    else if is_suffix ".rs"
    then Rust
    else if is_suffix ".xml"
    then Xml
    else if is_suffix ".fs"
    then FSharp
    else if is_suffix ".ml"
            || is_suffix ".mli"
            || is_suffix ".mlt"
            || is_suffix ".ud"
            || is_suffix ".udv"
            || is_suffix ".udl"
    then OCaml
    else if is_suffix ".patch"
    then Diff
    else Plaintext
  ;;
end

module Diff = struct
  module Context = struct
    type t =
      | Full
      | Lines of int
    [@@deriving equal, sexp_of]
  end

  module Whitespace = struct
    type t =
      | Keep
      | Ignore
    [@@deriving equal, sexp_of]
  end

  type t =
    | Added
    | Deleted
    | Changed of
        { original : string
        ; context : Context.t
        ; side_by_side : bool
        ; whitespace : Whitespace.t
        }
  [@@deriving equal, sexp_of]
end

module Extension_state = struct
  type t =
    { highlight : Skyline_codemirror_highlight_lines_v1.t list
    ; diff :
        [ `Added
        | `Deleted
        | `Inline of int option * Diff.Whitespace.t * string
        | `Left_side of int option * Diff.Whitespace.t * string
        | `Right_side of int option * Diff.Whitespace.t * string
        ]
          option
    }
  [@@deriving equal, sexp_of]
end

let half_width_editor = Ojs.obj [| "&", Ojs.obj [| "width", Ojs.string_to_js "50%" |] |]

let compute_extension' ?report_error { Extension_state.highlight; diff } =
  let highlight = List.map highlight ~f:Skyline_codemirror_highlight_lines_v1.extension in
  let keep_ws = function
    | Diff.Whitespace.Keep -> true
    | Ignore -> false
  in
  let diff_decorations =
    match diff with
    | None -> []
    | Some `Added -> [ force Skyline_codemirror_diff_v1.all_added ]
    | Some `Deleted -> [ force Skyline_codemirror_diff_v1.all_deleted ]
    | Some (`Inline (context, whitespace, original)) ->
      [ Skyline_codemirror_diff_v1.changes
          ~context
          ~keep_ws:(keep_ws whitespace)
          ~original
      ]
    | Some (`Left_side (context, whitespace, other_side)) ->
      [ Codemirror.View.Editor_view.theme ~spec:half_width_editor ()
      ; Skyline_codemirror_diff_v1.side_by_side
          ?report_error
          `Left
          ~context
          ~keep_ws:(keep_ws whitespace)
          ~other_side
      ]
    | Some (`Right_side (context, whitespace, other_side)) ->
      [ Codemirror.View.Editor_view.theme ~spec:half_width_editor ()
      ; Skyline_codemirror_diff_v1.side_by_side
          ?report_error
          `Right
          ~context
          ~keep_ws:(keep_ws whitespace)
          ~other_side
      ]
  in
  List.concat [ highlight; diff_decorations ]
;;

let compute_extension ?custom_extension ?report_error state =
  let%arr state = Bonsai.cutoff state ~equal:Extension_state.equal
  and report_error = Bonsai.transpose_opt report_error
  and custom_extension = Bonsai.transpose_opt custom_extension in
  let base_extensions = compute_extension' ?report_error state in
  let all_extensions = base_extensions @ Option.to_list custom_extension in
  Codemirror.State.Extension.of_list all_extensions
;;

let component'
  ?report_extension_error
  ?(language = Bonsai.return Language.Plaintext)
  ?(line_numbers = Bonsai.return true)
  ?(line_wrapping = Bonsai.return false)
  ?on_line_number_click
  ?(highlight = Bonsai.return [])
  ?scroll_to
  ?diff
  ?(print_full_document = Bonsai.return false)
  ?custom_extension
  document
  (local_ graph)
  =
  let theme =
    match%arr Skyline_entrypoint.theme graph with
    | Dark | Vscode { is_dark = true } ->
      Bonsai_web_codemirror_read_only.Theme.Vscode_dark
    | Light | Vscode { is_dark = false } -> Vscode_light
  in
  match%sub Bonsai.transpose_opt diff with
  | Some (Diff.Changed { side_by_side = true; original; context; whitespace }) ->
    let context =
      let%arr context in
      match context with
      | Full -> None
      | Lines lines -> Some lines
    in
    let%arr left_extension =
      compute_extension
        ?custom_extension
        ?report_error:report_extension_error
        (let%arr highlight and context and document and whitespace in
         { Extension_state.highlight
         ; diff = Some (`Left_side (context, whitespace, document))
         })
    and right_extension =
      compute_extension
        ?custom_extension
        ?report_error:report_extension_error
        (let%arr highlight and context and original and whitespace in
         { Extension_state.highlight
         ; diff = Some (`Right_side (context, whitespace, original))
         })
    and theme
    and language
    and line_numbers
    and on_line_number_click = Bonsai.transpose_opt on_line_number_click
    and scroll_to = Bonsai.transpose_opt scroll_to
    and original
    and document
    and print_full_document in
    (* Note: We skip [line_wrapping] for the side-by-side diff since it might cause lines
       to be miss-aligned between the two panels. *)
    let left_codemirror =
      Bonsai_web_codemirror_read_only.make
        ~extension:left_extension
        ~print_full_document
        ~line_numbers
        ?on_line_number_click
        ?scroll_to
        ~language
        ~theme
        original
    and right_codemirror =
      Bonsai_web_codemirror_read_only.make
        ~extension:right_extension
        ~print_full_document
        ~line_numbers
        ?on_line_number_click
        ?scroll_to
        ~language
        ~theme
        document
    in
    Skyline_flex_v1.row
      ~align:Stretch
      ~justify:Flex_start
      [ left_codemirror; right_codemirror ]
  | inline_diff ->
    let%arr extension =
      compute_extension
        ?custom_extension
        ?report_error:report_extension_error
        (let%arr highlight and inline_diff in
         let diff =
           match%map.Option inline_diff with
           | Diff.Added -> `Added
           | Deleted -> `Deleted
           | Changed { original; context; whitespace; _ } ->
             let context =
               match context with
               | Full -> None
               | Lines lines -> Some lines
             in
             `Inline (context, whitespace, original)
         in
         { Extension_state.highlight; diff })
    and theme
    and line_numbers
    and line_wrapping
    and on_line_number_click = Bonsai.transpose_opt on_line_number_click
    and scroll_to = Bonsai.transpose_opt scroll_to
    and language
    and document
    and print_full_document in
    Bonsai_web_codemirror_read_only.make
      ~extension
      ~line_numbers
      ~line_wrapping
      ?on_line_number_click
      ?scroll_to
      ~language
      ~theme
      ~print_full_document
      document
;;

let component
  ?language
  ?line_numbers
  ?line_wrapping
  ?on_line_number_click
  ?highlight
  ?scroll_to
  ?diff
  ?print_full_document
  ?custom_extension
  document
  (local_ graph)
  =
  component'
    ?language
    ?line_numbers
    ?line_wrapping
    ?on_line_number_click
    ?highlight
    ?scroll_to
    ?diff
    ?print_full_document
    ?custom_extension
    document
    graph
;;

let component_or_error
  ?language
  ?line_numbers
  ?line_wrapping
  ?on_line_number_click
  ?highlight
  ?scroll_to
  ?diff
  ?print_full_document
  ?custom_extension
  document
  (local_ graph)
  =
  let error, set_error = Bonsai.state (Ok ()) graph in
  let%arr error
  and set_error
  and view =
    component'
      ~report_extension_error:set_error
      ?language
      ?line_numbers
      ?line_wrapping
      ?on_line_number_click
      ?highlight
      ?scroll_to
      ?diff
      ?print_full_document
      ?custom_extension
      document
      graph
  in
  match error with
  | Ok () -> Ok view
  | Error e -> Error (~clear_error:(set_error (Ok ())), e)
;;
