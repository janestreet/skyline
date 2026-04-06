open! Core
open! Bonsai_web

module Action : sig
  type t

  (** A generic action that triggers the given effect on click. *)
  val single
    :  ?return_focus_to_input:bool
    -> ?intent:Skyline_theme_v1.Color.t
    -> ?tooltip:string
    -> on_click:unit Effect.t
    -> Codicons.t
    -> t

  (** An action that opens a submenu on click. *)
  val submenu
    :  ?return_focus_to_input:bool
    -> ?intent:Skyline_theme_v1.Color.t
    -> ?tooltip:string
    -> ?icon:Codicons.t
    -> unit Skyline_context_menu_v1.t
    -> t

  (** A clear-input button, which is only visible when the input is non-empty. It's
      possible to implement this using a [simple] action, but we provide this here as a
      convenience. *)
  val clear : t
end

module Input_type : sig
  (** The type of the text input. *)
  type t =
    | Text
    | Password
  [@@deriving sexp_of, equal, compare]
end

type t = string Skyline_input_v1.t

(** [component ~placeholder] renders a text input.

    - [placeholder] defines the text that is rendered when there are no contents.

    - [disabled] can be set to disable the input.

    - [actions] can be set to attach optional inline icon actions to the right-hand-side
      of the input element. (E.g. an [x] to clear the input, a button that opens a
      pop-over menu with additional options, etc...)

    - [autofocus] focuses the input element when set (this can be used to e.g. focus an
      input on page load)

    - [type_] is the type of the input (e.g. "text", "password", etc.)

    - [attrs] are any additional attributes to apply to the input element. *)
val component
  :  ?attrs:Vdom.Attr.t list Bonsai.t
  -> ?type_:Input_type.t Bonsai.t
  -> ?test_selector:Test_selector.t
  -> ?state:string Bonsai.t * (string -> unit Effect.t) Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?actions:Action.t list Bonsai.t
  -> ?autofocus:bool Bonsai.t
  -> placeholder:string Bonsai.t
  -> local_ Bonsai.graph
  -> t Bonsai.t

(** The text input element that can be renderd in the UI. *)
val view : t -> Vdom.Node.t

(** Current value in the input box. *)
val value : t -> string

(** Update the text input to the given value. *)
val update : t -> string -> unit Effect.t

module Expert : sig
  val style : Vdom.Attr.t
end
