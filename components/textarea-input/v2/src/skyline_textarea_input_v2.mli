open! Core
open! Bonsai_web

(** A stateless multi‑line textarea control designed to be used inside
    {!Skyline_field_v2.view}. It supports placeholders and a disabled state, lets callers
    control the number of visible rows, and is non‑resizable by default unless
    [~resizable:true] is provided. It inherits [size], [intent], and [disabled] from the
    enclosing field.

    {b Layout behavior}

    Renders a [<textarea>] that expands to fill the available width of its container. The
    control shows [rows] lines by default (2), and disables browser resize handles unless
    [~resizable:true] is passed.

    {b Example}

    {[
      let notes, set_notes = Bonsai.state "" graph in
      let%arr notes and set_notes in
      {%html|
        <Skyline_field_v2.view>
          <Skyline_textarea_input_v2.content ~rows:%{4} ~state:%{(notes, set_notes)} />
        </>
      |}
    ]} *)

(** Renders a controlled textarea (string) input, inheriting its visual state from the
    parent [Skyline_field_v2.view].

    Parameters:
    - [placeholder] - optionally render placeholder text.
    - [rows] - number of visible text lines for the control (default [2]).
    - [resizable] - whether the textarea is user-resizable (default [false]).
    - [state] - the value/setter pair controlling the input's state. *)
val content
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?placeholder:string
  -> ?rows:int
  -> ?resizable:bool
  -> state:string * (string -> unit Effect.t)
  -> unit
  -> Skyline_field_v2.Content.t

module For_docs : sig
  val ml_filepath : string
end
