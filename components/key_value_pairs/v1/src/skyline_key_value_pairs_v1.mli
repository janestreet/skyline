[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** [Key_value_pairs] is a component for showing keys and values.

    {b Layout behavior}

    Key/value pairs render as a block-level container that fills the width of its parent.
    In [Two_columns] layout, a grid with an elastic value column is used; in [One_column],
    pairs are stacked vertically.

    {b Example}

    {[
      Skyline_key_value_pairs_v1.view
        [ Skyline_key_value_pairs_v1.key "Key 1", %{%html|Value 1|}
        ; Skyline_key_value_pairs_v1.key "Key 2", %{%html|Value 2|}
        ; Skyline_key_value_pairs_v1.key "Key 3", %{%html|Value 3|}
        ]
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
  type t = Vdom.Node.t * Vdom.Node.t
end

(** [key] is a helper for creating a "key" in a "key-value-pair" that is some text with an
    (optional) icon. *)
val key : ?icon:Bonsai_web_icon.t -> string -> Vdom.Node.t

(** [view] is a tiny helper that will arrange your components on a grid depending on how
    you want to accomodate things.

    - [layout] defaults to [Layout.Two_columns].
    - [gap] is the gap that will exist in between the pairs. *)
val view
  :  ?attrs:Vdom.Attr.t list
  -> ?layout:Layout.t
  -> ?gap:Skyline_size.t
  -> Pair.t list
  -> Vdom.Node.t

module For_docs : sig
  val ml_filepath : string
end
