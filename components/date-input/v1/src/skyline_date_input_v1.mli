open! Core
open! Bonsai_web

type 'a t = 'a option Skyline_input_v1.t

(** [date graph] renders a date input element.

    Note that [min] and [max] are enforced only on user input, not when explicitly setting
    the state / when state is provided to the component. *)
val date
  :  ?test_selector:Test_selector.t Bonsai.t
  -> ?state:Date.t option Bonsai.t * (Date.t option -> unit Effect.t) Bonsai.t
  -> ?min:Date.t Bonsai.t
  -> ?max:Date.t Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?autofocus:bool Bonsai.t
  -> local_ Bonsai.graph
  -> Date.t t Bonsai.t

(** [time graph] renders a time input element.

    Note that [min] and [max] are enforced only on user input, not when explicitly setting
    the state / when state is provided to the component. *)
val time
  :  ?test_selector:Test_selector.t Bonsai.t
  -> ?state:
       Time_ns.Ofday.t option Bonsai.t
       * (Time_ns.Ofday.t option -> unit Effect.t) Bonsai.t
  -> ?min:Time_ns.Ofday.t Bonsai.t
  -> ?max:Time_ns.Ofday.t Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?autofocus:bool Bonsai.t
  -> local_ Bonsai.graph
  -> Time_ns.Ofday.t t Bonsai.t

(** [date_time graph] renders an input element that allows selecting a specific point in
    time. Typically this is rendered in the users local timezone.

    Note that [min] and [max] are enforced only on user input, not when explicitly setting
    the state / when state is provided to the component. *)
val date_time
  :  ?test_selector:Test_selector.t Bonsai.t
  -> ?state:Time_ns.t option Bonsai.t * (Time_ns.t option -> unit Effect.t) Bonsai.t
  -> ?min:Time_ns.t Bonsai.t
  -> ?max:Time_ns.t Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?autofocus:bool Bonsai.t
  -> local_ Bonsai.graph
  -> Time_ns.t t Bonsai.t

(** The text input element that can be renderd in the UI. *)
val view : _ t -> Vdom.Node.t

(** Current value in the input box. *)
val value : 'a t -> 'a option

(** Update the text input to the given value.

    Note that when given [min] and [max] these are enforced only on user input. They are
    not checked when setting the state explicitly. *)
val update : 'a t -> 'a option -> unit Effect.t
