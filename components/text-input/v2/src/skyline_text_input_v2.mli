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

(** [Composite] provides a composable text input that lets you place arbitrary elements
    alongside the input, all visually appearing as one unified input control.

    Like [content], [Composite.content] produces a [Skyline_field_v2.Content.t] and
    inherits [size], [intent], and [disabled] from the enclosing field.

    {b Layout behavior}

    Renders an inline element that expands to fill the available width of its container.

    {b Example}

    {[
      let value, set_value = Bonsai.state "" graph in
      let%arr value and set_value in
      {%html|
        <Skyline_field_v2.view>
          <Skyline_text_input_v2.Composite.content>
            <Skyline_text_input_v2.Composite.icon ~icon:%{Lucide.search} />
            <Skyline_text_input_v2.Composite.input
              ~state:%{(value, set_value)}
              ~placeholder:%{"Search..."}
            />
          </>
        </>
      |}
    ]} *)
module Composite : sig
  module Content : sig
    type t

    module Expert : sig
      (** Build an arbitrary composite content element. The vdom returned by this element
          is injected directly into the main [Composite] flex container.

          This API is different from [custom]

          In addition to the availability of [~size], [~intent] and [~disabled], this API
          is different from [custom] because it doesn't have any workarounds for label
          forwarding. It should probably be avoided because it requires you to think about
          the internal CSS of [Composite]. *)
      val make
        :  (size:Skyline_size.t
            -> intent:Skyline_field_v2.Intent.t
            -> disabled:bool
            -> Vdom.Node.t)
        -> t
    end
  end

  (** Wrapper that provides the input styling to a list of composite contents. *)
  val content
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> Content.t list
    -> Skyline_field_v2.Content.t

  (** The base text input. Stretches to fill remaining space.

      Parameters:
      - [placeholder] - optionally render placeholder text.
      - [state] - the value/setter pair controlling the input's state. *)
  val input
    :  ?test_selector:Test_selector.t
    -> ?key:string
    -> ?attrs:Vdom.Attr.t list
    -> ?placeholder:string
    -> state:string * (string -> unit Effect.t)
    -> unit
    -> Content.t

  (** An icon, matching the input's size and intent.

      - [?color] - override the default icon color. [Tokens.Colors.Text.default] (or
        [Tokens.Colors.Text.secondary] when disabled). *)
  val icon
    :  ?attrs:Vdom.Attr.t list
    -> ?color:(disabled:bool -> Css_gen.Color.t)
    -> icon:Bonsai_web_icon.t
    -> unit
    -> Content.t

  (** [custom] allows arbitrary content to be rendered inside the input.

      Note: [custom] does *not* inherit [~disabled] [~intent] or [~size] from the parent
      field. If you need your content to respond to those, use [Content.make] instead.

      There are HTML gotchas associated with putting interactive content inside of
      [custom], mostly due to the root Field being a [<label>] with no associated ID. The
      browser performs "label forwarding" for form controls (inputs, buttons) by default.
      We've done our best to counter this using
      [Skyline_field_v2.Content.Expert.exclude_from_label_forwarding], but that only works
      for DOM events and not purely visual selectors like [:hover]. *)
  val custom
    :  ?test_selector:Test_selector.t
    -> ?key:string
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Content.t
end

module Numeric : sig
  (** State for a numeric input. Manages the raw text and handles parsing. *)
  module State : sig
    type 'a t

    val value : 'a t -> 'a option

    (** Creates the state, optionally synced with external state.

        Parameters:
        - [state] - optionally provide external parsed state to mirror. If omitted, state
          is managed entirely internally.
        - positional module is the stringable numeric type, e.g. [Int] or [Float]. *)
    val create
      :  (module Stringable.S with type t = 'a)
      -> ?state:'a option Bonsai.t * ('a option -> unit Effect.t) Bonsai.t
      -> local_ Bonsai.graph
      -> 'a t Bonsai.t
  end

  (** Renders a controlled numeric input, inheriting its visual state from the parent
      [Skyline_field_v2.view].

      The input filters keypresses to only allow numeric characters and displays an error
      if the value in [State] fails to parse.

      Parameters:
      - [placeholder] - optionally render placeholder text.
      - [state] - the [State.t] representing the input's state. *)
  val content
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> ?placeholder:string
    -> state:_ State.t
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
