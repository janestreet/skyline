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
            ~render_anchor_content:%{Render_selection (fun fruit ->
                Vdom.Node.text (Fruit.to_string fruit))}
            ~controller
          />
        </>
      |}
    ]} *)

(** How to render the select anchor button.

    - [Render_selection] can only be used with [Selection_mode.Single_ux]; the wrapped
      function is called with the selected ['a] item.
    - [Render_multi_selection] can only be used with [Selection_mode.Multi_ux]; the
      wrapped function is called with the full list of selected items.

    These constraints are enforced by the types. *)
type ('a, 'selection) render_anchor_content =
  | Render_selection : ('a -> Vdom.Node.t) -> ('a, 'a option) render_anchor_content
  | Render_multi_selection :
      ('a list -> Vdom.Node.t)
      -> ('a, 'a list) render_anchor_content

(** [content] creates a [Skyline_field_v2.Content.t] for use inside a
    [Skyline_field_v2.view]. The select inherits [size], [intent], and [disabled] from the
    parent field. Rendering adapts to the controller's selection mode.

    - [?test_selector] - test selector for the anchor button
    - [?attrs] - additional attributes on the anchor button
    - [~placeholder] - text shown on the button when nothing is selected
    - [?render_anchor_content] - rendering for the anchor button. Use [Render_selection]
      with [Single_ux] controllers or [Render_multi_selection] with [Multi_ux]
      controllers. When omitted, the string representation from [to_string] is used.
    - [~controller] - the typeahead controller, see [Typeahead_controller.component]. *)
val content
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?render_anchor_content:('a, 'selection) render_anchor_content
  -> placeholder:string
  -> controller:('a, 'selection) Typeahead_controller.t
  -> unit
  -> Skyline_field_v2.Content.t

module For_docs : sig
  val ml_filepath : string
end
