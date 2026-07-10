open! Core
open! Bonsai_web

(** A typeahead-powered select input that renders a button anchor and a popover with a
    search input and filterable results list.

    Like {!Typeahead_combobox_input}, this component is driven by a
    {!Typeahead_controller}. The difference is that the anchor is a button (not a text
    input), and the search input lives inside the popover.

    Supports all [Typeahead_controller.Selection_mode] variants. For [Single_ux], the
    button shows the selected value. For [Effect_only], the button always shows the
    placeholder. For [Multi_ux], the button shows the item when one is selected or "N
    selected" with a tooltip when two or more are selected.

    {b Example}

    {[
      let controller =
        Skyline.Typeahead.Controller.component
          ~selection_mode:Single_ux
          ~to_string:Fruit.to_string
          ~data:
            (Skyline.Typeahead.Controller.Data_source.create_from_list
               ~to_search_string:Fruit.to_string
               (Bonsai.return [ Apple; Banana; Cherry; Date; Fig ]))
          graph
      in
      let%arr controller in
      {%html|
        <Skyline_field_v2.view>
          <Skyline.Typeahead.Select_input.content
            ~placeholder:%{"Pick a fruit..."}
            ~render_selection:%{Render (fun fruit ->
                Vdom.Node.text (Fruit.to_string fruit))}
            ~controller
          />
        </>
      |}
    ]} *)

(** How to render the select anchor button.

    - [Render] can only be used with [Selection_mode.Single_ux]; the wrapped function is
      called with the selected ['a] item.
    - [Render_multi] can only be used with [Selection_mode.Multi_ux]; the wrapped function
      is called with the full list of selected items.

    These constraints are enforced by the types. *)
type ('a, 'selection) render_selection =
  | Render : ('a -> Vdom.Node.t) -> ('a, 'a option) render_selection
  | Render_multi : ('a list -> Vdom.Node.t) -> ('a, 'a list) render_selection

(** [content] creates a [Skyline_field_v2.Content.t] for use inside a
    [Skyline_field_v2.view]. The select inherits [size], [intent], and [disabled] from the
    parent field. Rendering adapts to the controller's selection mode.

    - [?test_selector] - test selector for the anchor button
    - [?attrs] - additional attributes on the anchor button
    - [~placeholder] - text shown on the button when nothing is selected
    - [?render_selection] - rendering for the anchor button. Use [Render] with [Single_ux]
      controllers or [Render_multi] with [Multi_ux] controllers. When omitted, the string
      representation from [to_string] is used.
    - [~controller] - the typeahead controller, see [Typeahead_controller.component]. *)
val content
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?render_selection:('a, 'selection) render_selection
  -> placeholder:string
  -> controller:('a, 'selection) Typeahead_controller.t
  -> unit
  -> Skyline_field_v2.Content.t

(** Interaction attributes for a custom select anchor driven by an [Effect_only]
    controller. Can be used in combination with [Elements.anchor] or any other vdom
    element. Note that this attr depends on [on_click] events firing to open the popover. *)
val attr : ('a, unit) Typeahead_controller.t -> Vdom.Attr.t

module Elements : sig
  (** Renders only the button-like select anchor shell. Use to build a custom select which
      is visually similar to [content]. *)
  val anchor
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Skyline_field_v2.Content.t
end

module For_docs : sig
  val ml_filepath : string
end
