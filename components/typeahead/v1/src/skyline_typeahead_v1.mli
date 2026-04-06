open! Core
open! Bonsai_web

(** A typeahead input field that completes items from a given list of suggestions.

    The component provides good defaults for completing text items, but the score function
    as well as suggestion rendering can be fully customized. *)

module Suggestion_style : sig
  (** How to render the suggestions. [Popover] renders a popover with the suggestions
      while [Inline] shows the suggestion list inline after the input element. *)
  type t =
    | Popover
    | Inline
end

type t = string Skyline_input_v1.t

(** A text-input that auto-completes values from a given list of suggestions. *)
val component
  :  ?attrs:Vdom.Attr.t list Bonsai.t
  -> ?test_selector:Test_selector.t
  -> ?state:string Bonsai.t * (string -> unit Effect.t) Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?autofocus:bool Bonsai.t
  -> ?on_blur:unit Effect.t Bonsai.t
  -> ?on_select:('a -> string Effect.t) Bonsai.t
  -> ?on_tab:('a -> string Effect.t) Bonsai.t
  -> ?score:(string Bonsai.t -> ('a -> int) Bonsai.t)
  -> ?suggestion_style:Suggestion_style.t Bonsai.t
  -> ?max_visible_suggestions:int Bonsai.t
  -> ?suggestion:(string Bonsai.t -> ('a -> Vdom.Node.t) Bonsai.t)
  -> ?no_matching_suggestions:Vdom.Node.t Bonsai.t
  -> to_string:('a -> string) Bonsai.t
  -> placeholder:string Bonsai.t
  -> 'a list Bonsai.t
  -> Bonsai.graph @ local
  -> t Bonsai.t

(** The text input element that can be renderd in the UI. *)
val view : t -> Vdom.Node.t

(** Current value in the input box. *)
val value : t -> string

(** Update the text input to the given value. *)
val update : t -> string -> unit Effect.t
