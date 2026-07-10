open! Core
open! Bonsai_web

(** A combobox component that combines a committed buttonlike search input with an
    editable uncommitted search input and a dropdown list of filterable suggestions. When
    committed, the input is readonly and renders the selected label (or placeholder when
    nothing is selected). Activating that input transitions into the uncommitted editable
    state; selecting an item from the picker transitions back to the committed state.

    Items are declared by the caller via a {!Typeahead_controller.Data_source.t} (e.g.
    {!Typeahead_controller.Data_source.create_from_list}). The combobox handles fuzzy
    filtering, scoring, and rendering (including match highlighting). The
    {!Typeahead_controller} owns query, selection, committed/uncommitted mode, and
    open/close state.

    The combobox renders as a {!Skyline_field_v2.Content.t}, so it inherits [size],
    [intent], and [disabled] from the enclosing field. It is driven by a
    {!Typeahead_controller} created via {!Typeahead_controller.component}.

    When used with a [Selection_mode.Multi_ux] controller, selected items are rendered as
    dismissable chips to the left of the text input. Pressing Backspace in an empty input
    removes the rightmost chip.

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
          <Skyline.Typeahead.Combobox_input.content
            ~placeholder:%{"Search fruits..."}
            ~controller
          />
        </>
      |}
    ]} *)

(** How to render the selection area of a combobox.

    - [Render_multi] can only be used with [Selection_mode.Multi_ux]; [render] is called
      with the full list of selected items and its output replaces the default dismissable
      chips.
    - [on_backspace] fires when the user presses Backspace with an empty input. It
      replaces the built-in "remove the rightmost chip" behavior, which can be surprising
      when selected items aren't rendered as individual chips. The effect only fires on an
      empty input — typing and deleting text works as normal.

    This constraint is enforced by the types. *)
type ('a, 'selection) render_selection =
  | Render_multi :
      { on_backspace : unit Effect.t
      ; render : 'a list -> Vdom.Node.t
      }
      -> ('a, 'a list) render_selection

(** [content] creates a [Skyline_field_v2.Content.t] for use inside a
    [Skyline_field_v2.view]. The combobox inherits [size], [intent], and [disabled] from
    the parent field.

    Rendering adapts to the controller's selection mode. [Multi_ux] controllers render
    selected items as dismissable chips by default, or use [?render_selection] to replace
    them with custom content.

    - [?test_selector] - test selector for the combobox container
    - [?attrs] - additional attributes on the combobox container
    - [?input_attrs] - additional attributes on the inner [<input>] element (e.g. for
      [Attr.on_focus])
    - [~placeholder] - placeholder text for the text input
    - [?render_selection] - custom rendering for the selection area. Use [Render_multi]
      with [Multi_ux] controllers to replace the default dismissable chips with a
      caller-provided node (e.g. an "N selected" summary).
    - [?tab_selects_current_item] - when [true], pressing [Tab] while the popover is open
      has the same behavior as [Enter], except that the popover always closes (even for
      [Multi_ux]), Shift+Tab never commits, and when there is nothing to commit Tab falls
      through to normal focus navigation rather than being swallowed. The next Tab moves
      focus as usual. Default [false].
    - [~controller] - the typeahead controller, see [Typeahead_controller.component]. *)
val content
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?input_attrs:Vdom.Attr.t list
  -> ?render_selection:('a, 'selection) render_selection
  -> ?tab_selects_current_item:bool
  -> placeholder:string
  -> controller:('a, 'selection) Typeahead_controller.t
  -> unit
  -> Skyline_field_v2.Content.t

module For_testing : sig
  (** The [data-] attribute name used to tag each [Multi_ux] chip dismiss button with its
      owning controller's path id. Exposed so tests can scope DOM queries to a specific
      combobox instance. *)
  val chip_owner_data_attr : string

  (** The [data-] attribute name used to tag each [Multi_ux] chip dismiss button with its
      0-based index in the selection list. Exposed so tests can target a specific chip. *)
  val chip_index_data_attr : string
end

module For_docs : sig
  val ml_filepath : string
end
