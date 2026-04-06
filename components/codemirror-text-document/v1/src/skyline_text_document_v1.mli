open! Core
open! Bonsai_web

module Language : sig
  type t = Bonsai_web_ui_codemirror_read_only.Language.t =
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
  [@@deriving sexp_of]

  val of_filename : Filename.t -> t
end

module Diff : sig
  module Context : sig
    type t =
      | Full
      | Lines of int
    [@@deriving sexp_of]
  end

  module Whitespace : sig
    type t =
      | Keep
      | Ignore
    [@@deriving sexp_of]
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
  [@@deriving sexp_of]
end

(** Render a text document. This is typically useful for showing some source code e.g.
    from a config file, or a diff in the iron web UI.

    - [language] can be set to determine the syntax highlighting used when rendering the
      document
    - [line_numbers] enables / disables a gutter showing line numbers
    - [line_wrapping] enables / disables line wrapping
    - [on_line_number_click] handles clicks on the line number gutter
    - [highlight] can be given a set of line ranges that should be high-lighted visually
    - [diff] can configure a base document that then is renders as a diff view
    - [print_full_document] enables the brower's Ctrl+F search functionality to work
      beyond only what's rendered on screen. May impact performance. *)
val component
  :  ?language:Language.t Bonsai.t
  -> ?line_numbers:bool Bonsai.t
  -> ?line_wrapping:bool Bonsai.t
  -> ?on_line_number_click:(int -> unit Effect.t) Bonsai.t
  -> ?highlight:(start:int * stop:int) list Bonsai.t
  -> ?scroll_to:int Bonsai.t
  -> ?diff:Diff.t Bonsai.t
  -> ?print_full_document:bool Bonsai.t
  -> ?custom_extension:Codemirror.State.Extension.t Bonsai.t
  -> string Bonsai.t
  -> local_ Bonsai.graph
  -> Vdom.Node.t Bonsai.t

(** Similar to the above, but with a handler to catch exceptions from the CodeMirror
    extensions and return them as Error.

    Note that [clear_error] will clear the error, but won't currently "reset" the
    CodeMirror component itself. So if the error crashed the CodeMirror widget, it will
    remain crashed. *)
val component_or_error
  :  ?language:Language.t Bonsai.t
  -> ?line_numbers:bool Bonsai.t
  -> ?line_wrapping:bool Bonsai.t
  -> ?on_line_number_click:(int -> unit Effect.t) Bonsai.t
  -> ?highlight:(start:int * stop:int) list Bonsai.t
  -> ?scroll_to:int Bonsai.t
  -> ?diff:Diff.t Bonsai.t
  -> ?print_full_document:bool Bonsai.t
  -> ?custom_extension:Codemirror.State.Extension.t Bonsai.t
  -> string Bonsai.t
  -> local_ Bonsai.graph
  -> (Vdom.Node.t, clear_error:unit Effect.t * Error.t) Result.t Bonsai.t
