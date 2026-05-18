[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** A select input component that renders a button trigger and a dropdown list of items.
    Selecting an item replaces the button's placeholder text with the rendered value of
    the selected item.

    The dropdown supports both mouse and keyboard interaction:
    - Click on an item to select it
    - Use arrow keys to navigate focused items, Enter to select the focused item
    - Escape to close the dropdown
    - Focused and hovered items are rendered with distinct visual styles

    Users seeking to emulate the native HTML <select> behavior should use the top-level
    non-optional component in this library, since native <select> also doesn't support
    de-selection.

    {b Layout behavior}

    This component renders as an inline element that expands to fill the available width
    of its container.

    {b Example}

    {[
      let selected, set_selected = Bonsai.state "Apple" graph in
      let options =
        {%html|
          <Skyline_picker_v2.Select_input.Options.create>
            <Skyline_picker_v2.Select_input.Options.item ~value:%{"Apple"}>Apple</>
            <Skyline_picker_v2.Select_input.Options.item ~value:%{"Banana"}>Banana</>
            <Skyline_picker_v2.Select_input.Options.item ~value:%{"Cherry"}>Cherry</>
          </>
        |}
      in
      let controller =
        Skyline_picker_v2.Select_input.Controller.component
          (module String)
          ~state:(selected, set_selected)
          ~options:(Bonsai.return options)
          graph
      in
      let%arr controller in
      {%html|
        <Skyline_field_v2.view>
          <Skyline_picker_v2.Select_input.content
            ~render_anchor_content:%{fun fruit -> Vdom.Node.text fruit}
            ~controller
          />
        </>
      |}
    ]} *)

module Controller : sig
  type 'a t

  (** [component] creates a [Controller] component that can be passed to [content].
      - [~state] - the currently selected item and a setter
      - [~options] the select's [Options] *)
  val component
    :  (module Comparable.S_plain with type t = 'a)
    -> state:'a Bonsai.t * ('a -> unit Effect.t) Bonsai.t
    -> options:'a Select_options.t Bonsai.t
    -> Bonsai.graph @ local
    -> 'a t Bonsai.t
end

(** [content] creates a [Skyline_field_v2.Content.t] for use inside a
    [Skyline_field_v2.view].

    Use [attr] to create the select popover behavior, then pass the resulting attr here.
    - [?test_selector] - test selector for the trigger button (default [None])
    - [?attrs] - additional attributes on the trigger button (default [])
    - [~render_anchor_content] - the content to show inside the anchor button for the
      currently selected value
    - [~controller] - the [Controller] for handling the select's state *)
val content
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> render_anchor_content:('a -> Vdom.Node.t)
  -> controller:'a Controller.t
  -> unit
  -> Skyline_field_v2.Content.t

(** [Optional] provides utilities for making a [Select] where the state is a ['a option].
    This is a convenience API over just adding a [None] option. *)
module Optional : sig
  module Controller : sig
    type 'a t

    (** [component] creates a [Controller] component that can be passed to [content]. If
        you would like to support user de-selection, make sure to include [None] in the
        [options] list.
        - [~state] - the currently selected item and a setter
        - [~options] the select's [Options] *)
    val component
      :  (module Comparable.S_plain with type t = 'a)
      -> state:'a option Bonsai.t * ('a option -> unit Effect.t) Bonsai.t
      -> options:'a option Select_options.t Bonsai.t
      -> Bonsai.graph @ local
      -> 'a t Bonsai.t
  end

  (** [content] creates a [Skyline_field_v2.Content.t] for use inside a
      [Skyline_field_v2.view], where the selection is optional (i.e. the controller's
      selected value is ['a option]). When nothing is selected, the trigger button
      displays [~placeholder] text.

      The select inherits [size], [intent], and [disabled] from the parent field.
      - [?test_selector] - test selector for the trigger button (default [None])
      - [?attrs] - additional attributes on the trigger button (default [])
      - [~placeholder] - text shown on the trigger button when no item is selected
      - [~render_anchor_content] - the content to show inside the anchor button for the
        currently selected value
      - [~controller] - the [Controller] for handling the select's state *)
  val content
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> placeholder:string
    -> render_anchor_content:('a -> Vdom.Node.t)
    -> controller:'a Controller.t
    -> unit
    -> Skyline_field_v2.Content.t
end

module For_docs : sig
  val ml_filepath : string
end
