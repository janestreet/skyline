open! Core
open! Bonsai_web

(** A multi-select input field allows picking items from a provided list of options. The
    items are selected from a type-ahead input and selected items are rendered in-line in
    the input field.

    The component provides good defaults for completing text items, but the score function
    as well as suggestion rendering can be fully customized. *)

type 'a t = 'a list Skyline_input_v1.t

(** A multi-select input with a text-box for searching / selecting items. By default,
    items are displayed in the UI using their [to_string] value. *)
val component
  :  ?test_selector:Test_selector.t
  -> ?state:'a list Bonsai.t * ('a list -> unit Effect.t) Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?autofocus:bool Bonsai.t
  -> ?score:(string Bonsai.t -> ('a -> int) Bonsai.t)
  -> ?max_visible_suggestions:int Bonsai.t
  -> ?suggestion:('a -> Vdom.Node.t) Bonsai.t
  -> ?selection:('a -> Vdom.Node.t) Bonsai.t
  -> ?no_matching_suggestions:Vdom.Node.t Bonsai.t
  -> to_string:('a -> string) Bonsai.t
  -> placeholder:string Bonsai.t
  -> 'a list Bonsai.t
  -> Bonsai.graph @ local
  -> 'a t Bonsai.t

(** The text input element that can be renderd in the UI. *)
val view : _ t -> Vdom.Node.t

(** Current selected items in the input box. *)
val value : 'a t -> 'a list

(** Update the currently selected items to the given value. *)
val update : 'a t -> 'a list -> unit Effect.t
