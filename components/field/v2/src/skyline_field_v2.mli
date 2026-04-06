[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** A composable form field container that arranges a visual label, an input control (e.g.
    text or textarea), and optional help text with consistent spacing. The field
    propagates shared [size], [intent], and [disabled] to its children so they render with
    a consistent look and feel.

    This entire component is a <label>, so clicks anywhere inside it will trigger any
    contained <input>, because the label is "implicitly associated" with the input:
    https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/label#associating_a_label_with_a_form_control

    {b Layout behavior}

    Renders a flex container laid out in a column with a small vertical gap between
    children. The field expands to the full width of its container.

    {b Disabled states}

    When [~disabled:true] is passed to [view], all child content receives
    [disabled = true] via the [Content.t] callback. Built-in field children that render
    inputs (e.g., text inputs, checkboxes) will use this to render non‑interactable
    controls and appropriate disabled styling. Custom content that implements [Content.t]
    can adjust its appearance based on this flag.

    {b Example}

    {[
      let value, set_value = Bonsai.state "" graph in
      let%arr value and set_value in
      {%html|
        <Skyline_field_v2.view
          ~label:(<Skyline_field_v2.Label.content> Name </>)
          ~footer:(<Skyline_field_v2.Footer.content>
            Enter your full name.
          </>)
        >
          <Skyline_text_input_v2.view ~state:%{(value, set_value)} />
        </>
      |}
    ]}

    You can use [~label_position] to control how the label is positioned with respect to
    the input:

    {[
      let value, set_value = Bonsai.state false graph in
      let%arr value and set_value in
      {%html|
        <Skyline_field_v2.view
          ~label:(<Skyline_field_v2.Label.content> Maintain risk parameters </>)
          ~label_position:%{Right}
          ~footer:(<Skyline_field_v2.Footer.content>
            Apply spline reticulation factors
          </>)
        >
          <Skyline_checkbox_v2.content ~state:%{(value, set_value)} />
        </>
      |}
    ]} *)

module Intent : sig
  type t =
    [ `Primary
    | `Success
    | `Danger
    | `Warning
    ]
  [@@deriving to_string]
end

module Label_position : sig
  type t =
    | Top
    | Left
    | Right
  [@@deriving to_string]
end

module Content : sig
  type t

  val make : (size:Skyline_size.t -> intent:Intent.t -> disabled:bool -> Vdom.Node.t) -> t
end

module Label : sig
  type t

  (** Util for rendering custom label content. *)
  val make : (size:Skyline_size.t -> intent:Intent.t -> disabled:bool -> Vdom.Node.t) -> t

  (** Renders an input label, inheriting sizing from the parent view. *)
  val content
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> t
end

module Footer : sig
  type t

  (** Util for rendering custom footer content. *)
  val make : (size:Skyline_size.t -> intent:Intent.t -> disabled:bool -> Vdom.Node.t) -> t

  (** Renders footer/help text, inheriting sizing and intent from the parent view. *)
  val content
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> t
end

(** [view] creates a field container that composes label, input, and help text.

    Parameters:
    - [?label_position] - position of the label relative to input (default [Top]). With
      [Left] and [Right] your field label and content will use a 2-column layout, whereas
      with [Top] it will use a 2-row layout.
    - [?size] - controls font size and padding (default [Md])
    - [?intent] - visual style variant (default [`Primary])
    - [?disabled] - flag to disable inputs (default [false])
    - [?label] - label for this field
    - [?footer] - footer / help text for this field
    - The positional argument is a list of [Content.t]-compatible subcomponents, for
      instance [Skyline_text_input_v2.content]

    Returns a [<label>] wrapping the composed content. *)
val view
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?label_position:Label_position.t
  -> ?size:Skyline_size.t
  -> ?intent:Intent.t
  -> ?disabled:bool
  -> ?label:Label.t
  -> ?footer:Footer.t
  -> Content.t list
  -> Vdom.Node.t

module Grid : sig
  (** [field] creates a field for use within a [Grid.view]. The field will use CSS subgrid
      to align its label and content with sibling fields.

      Parameters:
      - [?label_position] - position of the label relative to input (default [Left]). Note
        that [Left] and [Right] will lay out content along a single row, and [Top] will
        lay out content on 2 rows.
      - [?size] - controls font size and padding (default [Md])
      - [?intent] - visual style variant (default [`Primary])
      - [?disabled] - flag to disable inputs (default [false])
      - [?label] - label for this field
      - [?footer] - footer / help text for this field
      - The positional argument is a list of [Content.t]-compatible subcomponents, for
        instance [Skyline_text_input_v2.content] *)
  val field
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> ?label_position:Label_position.t
    -> ?size:Skyline_size.t
    -> ?intent:Intent.t
    -> ?disabled:bool
    -> ?label:Label.t
    -> ?footer:Footer.t
    -> Content.t list
    -> Vdom.Node.t

  (** [view] creates a field grid container that arranges multiple fields with consistent
      spacing and alignment.

      Parameters:
      - The positional argument is a list of [Vdom.Node.t] created via [Grid.field]

      Returns a [<fieldset>] laid out via CSS Grid wrapping the composed content. *)
  val view
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Vdom.Node.t
end

module For_docs : sig
  val ml_filepath : string
end
