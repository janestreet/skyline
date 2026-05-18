open! Core
open! Bonsai_web

(** Menu options express a collection of actions. They are commonly used in context menus
    and dropdowns.

    Options support keyboard navigation (arrow keys, Enter, Escape) when the menu is
    focused and can contain nested sub-menus that open as popovers.

    {b Layout behavior}

    This component, when rendered in-layout, behaves as a block.

    {b Example}

    {[
      {%html|
        <Skyline_menu_v2.Options.create>
          <Skyline_menu_v2.Options.title> Hello </>
          <Skyline_menu_v2.Options.item ~key:%{"root"} ~on_click:%{Effect.Ignore}>
            Root item
          </>
          <Skyline_menu_v2.Options.separator />
          <Skyline_menu_v2.Options.Sub_menu.create
            ~key:%{"sub menu"}
            ~trigger:(<Skyline_menu_v2.Options.Sub_menu.Trigger.create>
              Sub menu
            </>
          )>
            <Skyline_menu_v2.Options.item ~key:%{"sub item"} ~on_click:%{Effect.Ignore}>
              Sub item
            </>
           </>
         </>
      |}
    ]} *)

type t

(** [Content.t] is an abstract type representing elements that can be placed inside a
    menu's options. You cannot construct [Content.t] values directly; instead, use the
    provided functions:
    - [item] for selectable menu items
    - [separator] for visual separators
    - [title] for non-interactive section labels
    - [Sub_menu.create] for nested sub-menus

    Once created, pass lists of [Content.t] to [create] to build menu options. *)
module Content : sig
  type t
end

(** [item] creates a selectable menu item in the options list.

    - [?test_selector] test selector for this item
    - [?attrs] additional attributes to customize the element (user-provided styling)
    - [?disabled] disables the item (default [false])
    - [?icon] optional icon to display to the left of the item
    - [?suffix] optional node rendered to the right of the item content
    - [key] unique identifier for this item, used in keyboard navigation and test
      selectors
    - [on_click] effect triggered when the item is selected
    - [children] list of nodes that make up the item's content

    Returns a [Content.t] that can be added to the options list. *)
val item
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?disabled:bool
  -> ?icon:Bonsai_web_icon.t
  -> ?suffix:Vdom.Node.t
  -> key:string
  -> on_click:unit Effect.t
  -> Vdom.Node.t list
  -> Content.t

(** [separator] creates a visual separator between menu items.

    - [?attrs] additional attributes to customize the element

    Returns a [Content.t] that can be added to the options list. *)
val separator : ?attrs:Vdom.Attr.t list -> unit -> Content.t

(** [title] creates a non-interactive title section in the options list, typically used to
    label groups of items.

    - [?test_selector] test selector for this title
    - [?attrs] additional attributes to customize the element (user-provided styling)
    - [?icon] optional icon to display with the title
    - [children] list of nodes that make up the title's content

    Returns a [Content.t] that can be added to the options list. *)
val title
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> Vdom.Node.t list
  -> Content.t

module Sub_menu : sig
  module Trigger : sig
    type t

    (** [create] creates a trigger for a sub-menu that triggers its disclosure when
        hovered or selected.

        - [?test_selector] test selector for this trigger
        - [?attrs] additional attributes to customize the element (user-provided styling)
        - [?icon] optional icon to display with the trigger (a chevron icon is
          automatically added to indicate the sub-menu)
        - [?suffix] optional node rendered to the right of the trigger content
        - [children] list of nodes that make up the trigger's content

        Returns a [Trigger.t] for use in a sub-menu. *)
    val create
      :  ?test_selector:Test_selector.t
      -> ?attrs:Vdom.Attr.t list
      -> ?icon:Bonsai_web_icon.t
      -> ?suffix:Vdom.Node.t
      -> Vdom.Node.t list
      -> t
  end

  (** [create] creates a sub-menu that displays a popover options list when hovered or
      selected.

      - [children] must be a single [t] (the nested options list). The [children] type
        enforces this structure.
      - [key] unique identifier for this sub-menu, adds a path step in the root Keyed test
        selector

      Returns a [Content.t] that can be added to the options list. *)
  val create
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> Content.t list
    -> key:string
    -> trigger:Trigger.t
    -> Content.t
end

(** [create] creates a menu options configuration that opens sub-menus into popovers.

    - [?test_selector] test selector for the options container
    - [?attrs] additional attributes for the options container (user-provided styling)
    - [contents] list of [Content.t] items to display in the options list

    Returns a [t] representing the options configuration. Pass this to
    [Skyline_menu_v2.controller] to render it with state management and keyboard
    navigation. *)
val create
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> Content.t list
  -> t

module Expert : sig
  (** [component] is a low-level building block for creating stateful menu options
      components. Most users should prefer higher-level components like [Skyline_menu_v2]
      or [Skyline_select] which handle common patterns automatically.

      Provides keyboard navigation:
      - Arrow keys to navigate between items
      - Enter to select an item
      - Escape to close (triggers the [close] effect)
      - Left/Right to navigate in/out of sub-menus

      - [?test_selector] test selector for the options container
      - [?items_test_selectors] keyed test selectors for hierarchical item selection in
        tests
      - [?size] controls font sizing and spacing for all items (default [`Md])
      - [?focus_on_activate] controls whether the options list should be focused on
        activate (default [false])
      - [options] the options [t] to render
      - [close] effect to close the menu (triggered by Escape key or item selection)

      Returns a [Vdom.Node.t] representing the rendered menu options component. *)
  val component
    :  ?test_selector:Test_selector.t Bonsai.t
    -> ?items_test_selectors:string Nonempty_list.t Test_selector.Keyed.t Bonsai.t
    -> ?size:Skyline_size.t Bonsai.t
    -> ?focus_on_activate:bool Bonsai.t
    -> t Bonsai.t
    -> close:unit Effect.t Bonsai.t
    -> Bonsai.graph @ local
    -> Vdom.Node.t Bonsai.t
end

(** [Styles] provides reusable CSS attributes for menu options styling. *)
module Styles : sig
  (** [container] provides the base container styling for menu options. *)
  val container : Vdom.Attr.t
end

(** [For_docs] provides metadata for documentation generation. *)
module For_docs : sig
  (** [ml_filepath] is the path to this module's implementation file. *)
  val ml_filepath : string
end
