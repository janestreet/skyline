[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** A stateless checkbox control for toggling a boolean, designed to be used inside
    {!Skyline_field_v2.view}. It supports a disabled state and an [indeterminate] visual
    state, and inherits [size], [intent], and [disabled] from the enclosing field to
    control dimensions and focus styling.

    {b Layout behavior}

    Renders a checkbox that reflects the checked or indeterminate state. Exact size varies
    with [size] (Xs, Sm, Md, Lg). Labels are not included; compose with [~label] and
    [~label_position] on {!Skyline_field_v2.view} to give the input a label.

    {b Example}

    {[
      let value, set_value = Bonsai.state false graph in
      let%arr value and set_value in
      {%html|
        <Skyline_field_v2.view
          ~label:(<Skyline_field_v2.Label.content> Subscribe to updates </>)
          ~label_position:%{Right}
        >
          <Skyline_checkbox_v2.content ~state:%{(value, set_value)} />
        </>
      |}
    ]} *)

(** Renders a controlled checkbox, inheriting [size], [intent], and [disabled] from the
    parent [Skyline_field_v2.view].

    Parameters:
    - [indeterminate] - visually shows a partial/indeterminate mark. This does not change
      the bound boolean [state] value.
    - [state] - the boolean value/setter pair controlling the checkbox. *)
val content
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?indeterminate:bool
  -> state:bool * (bool -> unit Effect.t)
  -> unit
  -> Skyline_field_v2.Content.t

module For_docs : sig
  val ml_filepath : string
end
