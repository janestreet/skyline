open! Core
open! Bonsai_web

(** Display some data as a simple table. A table layout can be helpful to present a set of
    tabular data or to provide a quick overview. *)

module Layout : sig
  (** Which layout to use for the table. [Auto] is the default layout and causes the table
      to fit its contents. [Fixed width] allow you to specify a fixed width. *)
  type t =
    | Auto
    | Fixed of Css_gen.Length.t
  [@@deriving sexp_of, equal]
end

module Alignment : sig
  (** Alignment for the heading and cells in a given column. *)
  type t =
    | Left
    | Right
    | Center
  [@@deriving sexp_of, equal]
end

module Col : sig
  (** Configure a column in the table. Each column has a heading, and a specific format
      that can convert a value into some data that's displayed in the cell. *)
  type 'a t

  (** A list of columns in a table. *)
  type 'a t_list =
    | [] : unit t_list
    | ( :: ) : 'hd t * 'tl t_list -> ('hd * 'tl) t_list

  type 'a heading_args := ?tooltip:string -> ?icon:Codicons.t -> ?align:Alignment.t -> 'a

  type 'a cell_args :=
    ?font:Skyline_text_v1.Font_family.t
    -> ?style:Skyline_text_v1.Font_style.t
    -> ?decoration:Skyline_text_v1.Text_decoration.t
    -> 'a

  type 'a text_cell := (string -> 'a t) cell_args heading_args

  (** A column that can display text values in the table.

      The column heading can be configured with an optional [?tooltip] and [?icon]. The
      text presentation in the column is also configurable. *)
  val string : string text_cell

  (** A column that can display integer values in the table.

      The column heading can be configured with an optional [?tooltip] and [?icon]. The
      text presentation in the column is also configurable. *)
  val int : int text_cell

  (** A column that can display floating point values in the table.

      The column heading can be configured with an optional [?tooltip] and [?icon]. The
      text presentation in the column is also configurable. *)
  val float : float text_cell

  (** A column that can display boolean values in the table.

      The column heading can be configured with an optional [?tooltip] and [?icon]. The
      text presentation in the column is also configurable. *)
  val bool : bool text_cell

  (** A column that can display sexp values in the table.

      The column heading can be configured with an optional [?tooltip] and [?icon]. The
      text presentation in the column is also configurable. *)
  val sexp : Sexp.t text_cell

  (** A column that displays an arbitrary DOM node for the cell contents.

      [vdom heading] is equivalent to [create ~heading (fun dom -> dom)]. *)
  val vdom : (string -> Vdom.Node.t t) heading_args

  (** Create a column format with custom cell content.

      The column heading can be configured with an optional [?tooltip] and [?icon].

      [?align] can be used to determine the alignment of the heading. Note that the custom
      cell content will not be aligned automatically. *)
  val create : (heading:string -> ('a -> Vdom.Node.t) -> 'a t) heading_args

  (** Converts a column that can format ['a] cells into a column that can format ['b]
      cells. *)
  val lift : 'a t -> f:('b -> 'a) -> 'b t

  (** Create a column group that formats a list of cells based on a single data value.

      This can for example be used to dynamically create columns based on user
      configuration. *)
  val group : 'a t list -> 'a t
end

module Row : sig
  (** A row of data that can be displayed in a table. *)
  type 'cols t =
    | [] : unit t
    | ( :: ) : 'hd * 'tl t -> ('hd * 'tl) t
end

(** Renders a table with the given columns and rows. Tables are a good way to present
    tabular data (like you might find in a SQL schema).

    If you just want to display a list of items, consider using [Skyline.Flex.column]
    instead, unless you want your list to visually look like a table. *)
val component
  :  ?layout:Layout.t
  -> ?border:bool
  -> ?padding:Css_gen.Length.t
  -> 'cols Col.t_list
  -> 'cols Row.t list
  -> Vdom.Node.t
