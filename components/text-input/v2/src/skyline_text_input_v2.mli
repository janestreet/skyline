[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** A stateless single-line text control designed to be used inside
    {!Skyline_field_v2.view}. It supports placeholders and a disabled state, and inherits
    [size], [intent], and [disabled] from the enclosing field to control padding,
    typography, focus styling, and interactivity.

    {b Layout behavior}

    Renders an [<input type="text">] that expands to fill the available width of its
    container. Exact padding and font size vary with [size] (Xs, Sm, Md, Lg).

    {b Example}

    {[
      let value, set_value = Bonsai.state "" graph in
      let%arr value and set_value in
      {%html|
        <Skyline_field_v2.view>
          <Skyline_text_input_v2.content ~state:%{(value, set_value)} />
        </>
      |}
    ]} *)

(** Renders a controlled text (string) input, inheriting its visual state from the parent
    [Skyline_field_v2.view].

    Parameters:
    - [placeholder] - optionally render placeholder text.
    - [state] - the value/setter pair controlling the input's state. *)
val content
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?placeholder:string
  -> state:string * (string -> unit Effect.t)
  -> unit
  -> Skyline_field_v2.Content.t

module Numeric : sig
  (** Renders a controlled numeric input, inheriting its visual state from the parent
      [Skyline_field_v2.view]. Pass any module satisfying [Stringable.S] (e.g. [Int63],
      [Decimal], [Int]) to control the parsed type.

      The input prevents invalid values from being typed, either because they're malformed
      or too large/small to represent in the given type.

      Parameters:
      - [stringable] - the module used to parse and display values.
      - [placeholder] - optionally render placeholder text.
      - [state] - the value/setter pair controlling the input's state. *)
  val content
    :  stringable:(module Stringable.S with type t = 'a)
    -> ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> ?placeholder:string
    -> state:'a option * ('a option -> unit Effect.t)
    -> unit
    -> Skyline_field_v2.Content.t

  (** [Decimal] formats [Float] without the trailing dot. *)
  module Decimal : Stringable.S with type t = float

  (** [Price] represents a value with exactly two decimal places. *)
  module Price : sig
    type t [@@deriving sexp_of, string]

    val of_float_rounded : float -> t option
    val to_float : t -> float
  end
end

module For_docs : sig
  val ml_filepath : string
end

module For_testing : sig
  module Input_value_hook = Input_value_hook
end
