open! Core
open! Bonsai_web

(** A date input component for selecting dates using separate year, month, and day fields.

    This component provides keyboard navigation between date parts, validation feedback,
    and a calendar picker.

    {b Layout behavior}

    Renders an inline-flex container with monospace font. The component displays separate
    input areas for year (YYYY), month (MM), and day (DD) with a calendar icon.

    {b Example}

    {[
      let value, set_value = Bonsai.state_opt graph in
      let date_state =
        Skyline_date_input_v2.State.create ~state:(value, set_value) graph
      in
      let%arr date_state in
      {%html|
        <Skyline_field_v2.view
          ~label:(<Skyline_field_v2.Label.content> Start Date </>)
        >
          <Skyline_date_input_v2.content ~state:%{date_state} />
        </>
      |}
    ]} *)

(** Internal date-part state needed by the date input. Create with [State.create] at the
    Bonsai graph level, then pass the resolved value to [content] inside [let%arr]. *)
module State : sig
  type t

  (** [create] sets up internal state machines for the year, month, and day parts, focus
      management, and bidirectional sync between the individual parts and the caller's
      [Date.t option].

      Parameters:
      - [state] - the value/setter pair controlling the input's date. If not provided,
        internal state is created automatically. *)
  val create
    :  ?state:Date.t option Bonsai.t * (Date.t option -> unit Effect.t) Bonsai.t
    -> Bonsai.graph @ local
    -> t Bonsai.t
end

(** [content] renders a date input designed for use inside [Skyline_field_v2.view],
    inheriting [size], [intent], and [disabled] from the parent field.

    Parameters:
    - [state] - the date input state created via [State.create]. *)
val content
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> state:State.t
  -> unit
  -> Skyline_field_v2.Content.t

module For_docs : sig
  val ml_filepath : string
end
