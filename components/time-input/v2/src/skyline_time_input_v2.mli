open! Core
open! Bonsai_web

(** A 24-hour time input component for selecting times using separate hours, minutes, and
    optionally seconds fields.

    This component provides keyboard navigation between time parts, validation feedback,
    and a native time picker.

    {b Layout behavior}

    Renders an inline-flex container with monospace font. The component displays separate
    input areas for hours (HH), minutes (MM), and optionally seconds (SS) with a clock
    icon.

    {b Example}

    {[
      let value, set_value = Bonsai.state_opt graph in
      let controller =
        Skyline_time_input_v2.Controller.create ~state:(value, set_value) graph
      in
      let%arr controller in
      {%html|
        <Skyline_field_v2.view
          ~label:(<Skyline_field_v2.Label.content> Start Time </>)
        >
          <Skyline_time_input_v2.content ~controller />
        </>
      |}
    ]} *)

(** The display format of the time input. *)
module Format : sig
  type t =
    | HH_MM (** Hours and minutes only (e.g. 14:30). *)
    | HH_MM_SS (** Hours, minutes, and seconds (e.g. 14:30:45). *)
  [@@deriving sexp_of, equal]
end

(** Manages internal state for the time input: spinbutton state machines for each segment,
    focus handles, and bidirectional sync with the caller's [Time_ns.Ofday.t option].

    Create with [Controller.create] at the Bonsai graph level, then pass the resolved
    value to [content] inside [let%arr]. *)
module Controller : sig
  module State : sig
    type t = Time_ns.Ofday.t option
  end

  type t

  (** The format this controller was created with. *)
  val format : t -> Format.t

  (** The current parsed time value, or [None] if the segments are incomplete or invalid. *)
  val value : t -> State.t

  (** [create] sets up internal state machines for the time segments, focus management,
      and bidirectional sync between the individual segments and the caller's
      [Time_ns.Ofday.t option].

      Parameters:
      - [format] - the display format. Defaults to [HH_MM].
      - [state] - the value/setter pair controlling the input's time. If not provided,
        internal state is created automatically. *)
  val create
    :  ?format:Format.t
    -> ?state:State.t Bonsai.t * (State.t -> unit Effect.t) Bonsai.t
    -> Bonsai.graph @ local
    -> t Bonsai.t
end

(** [content] renders a time input designed for use inside [Skyline_field_v2.view],
    inheriting [size], [intent], and [disabled] from the parent field.

    The number of segments rendered is determined by the [Format.t] stored in the
    controller.

    Parameters:
    - [controller] - the controller created via [Controller.create]. *)
val content
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> controller:Controller.t
  -> unit
  -> Skyline_field_v2.Content.t

module For_testing : sig
  module Segmented_input = Segmented_input
  module Segment_spinbutton = Segmented_input.Segment_spinbutton
end

module For_docs : sig
  val ml_filepath : string
end
