open! Core
open! Bonsai_web

(** Helpers for [display: flex] containers, similar to [View.hbox] and [View.vbox], but
    using the terminology from CSS.

    Also see the
    {{:https://css-tricks.com/snippets/css/a-guide-to-flexbox/} flex-box guide}. *)

module Wrap : sig
  (** Possible values for the flex-box [wrap] property. *)
  type t =
    | Nowrap
    | Wrap
    | Wrap_reverse
  [@@deriving sexp_of, compare, equal]
end

module Justify : sig
  (** Possible values for the flex-box [justify-content] property. *)
  type t =
    | Flex_start
    | Flex_end
    | Center
    | Space_between
    | Space_around
    | Space_evenly
  [@@deriving sexp_of, compare, equal]
end

module Align : sig
  (** Possible values for the flex-box [align-items] property. *)
  type t =
    | Flex_start
    | Flex_end
    | Center
    | Stretch
    | Baseline
  [@@deriving sexp_of, compare, equal]
end

(** A flex-box container with [flex-direction: row] (or [row-reverse]), laying out items
    left-to-right (or right-to-left).

    Also see the
    {{:https://css-tricks.com/snippets/css/a-guide-to-flexbox/} flex-box guide}. *)
val row
  :  ?attrs:Vdom.Attr.t list
  -> ?reverse:bool
  -> ?wrap:Wrap.t
  -> ?justify:Justify.t
  -> ?align:Align.t
  -> ?gap:Css_gen.Length.t
  -> ?padding:Css_gen.Length.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** A flex-box container with [flex-direction: column] (or [column-reverse]), laying out
    items top-to-bottom (or bottom-to-top).

    Also see the
    {{:https://css-tricks.com/snippets/css/a-guide-to-flexbox/} flex-box guide}. *)
val column
  :  ?attrs:Vdom.Attr.t list
  -> ?reverse:bool
  -> ?wrap:Wrap.t
  -> ?justify:Justify.t
  -> ?align:Align.t
  -> ?gap:Css_gen.Length.t
  -> ?padding:Css_gen.Length.t
  -> Vdom.Node.t list
  -> Vdom.Node.t
