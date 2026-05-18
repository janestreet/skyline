open! Core
open! Bonsai_web

(** [Key_value_pairs] is a component for showing keys and values.

    {b Layout behavior}

    Key/value pairs render as a block-level container that fills the width of its parent.
    In [Two_columns] layout, a grid with an elastic value column is used; in [One_column],
    pairs are stacked vertically.

    {b Example}

    {[
      {%html|
        <Skyline_key_value_pairs_v1.view>
          <Skyline_key_value_pairs_v1.Pair.text key="Key 1">Value 1</>
          <Skyline_key_value_pairs_v1.Pair.text key="Key 2">Value 2</>
          <Skyline_key_value_pairs_v1.Pair.text key="Key 3">Value 3</>
        </>
      |}
    ]} *)

(** [Layout] whether the key/values are aligned.

    [One_column] looks like:

    {v
    Name:
    Cocoa

    Species:
    Capybara
    v}

    [Two_columns] looks like:

    {v
     Name:     Cocoa
     Species:  Capybara
    v} *)
module Layout : sig
  type t =
    | One_column
    | Two_columns
  [@@deriving enumerate, to_string, sexp_of, equal]
end

(** A [Pair.t] is a (key x value) pair *)
module Pair : sig
  type t

  (** [text] creates key-value-pair, inheriting the [size] from the container.

      - [icon] optionally renders an icon
      - [key] is the text to render, formatted using [size]
      - [children] are the values, formatted using [size] *)
  val text : ?icon:Bonsai_web_icon.t -> key:string -> Vdom.Node.t list -> t

  (** [content] allows custom content in the key and value without any extra styling.

      - [key] is the key to render
      - [children] are the values *)
  val content : key:Vdom.Node.t -> Vdom.Node.t list -> t
end

(** [view] arranges your key-value-pairs in a grid.

    - [size] sets the gap that will exist in between the pairs and the size of content
      created with [Pair.text].
    - [layout] defaults to [Layout.Two_columns]. *)
val view
  :  ?attrs:Vdom.Attr.t list
  -> ?size:Skyline_size.t
  -> ?layout:Layout.t
  -> Pair.t list
  -> Vdom.Node.t

module For_docs : sig
  val ml_filepath : string
end
