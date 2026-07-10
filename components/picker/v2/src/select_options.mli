open! Core
open! Bonsai_web

(** Select options express a list of selectable items. They support both mouse and
    keyboard navigation (Up/Down arrow keys, Enter to select, Escape to close).

    It is intended to be used via [Skyline_picker_v2.Select_input], refer to it for
    examples.

    {b Layout behavior}

    This component, when rendered in-layout, behaves as a block. *)
type 'a t

module Item : sig
  type 'a t
end

(** [item] creates a selectable option.

    - [?attrs] - additional attributes on the item
    - [?disabled] - whether the item is disabled (default [false])
    - [?icon] - optional icon to display alongside the item
    - [~value] - the value this option represents
    - positional [Vdom.Node.t list] - the rendered content of the item *)
val item
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?disabled:bool
  -> ?icon:Bonsai_web_icon.t
  -> value:'a
  -> Vdom.Node.t list
  -> 'a Item.t

(** [create] combines a list of items into a select options configuration.
    - [?attrs] - additional attributes for the dropdown container
    - [?size] - controls font sizing and spacing (default [`Md]) *)
val create : ?attrs:Vdom.Attr.t list -> ?size:Skyline_size.t -> 'a Item.t list -> 'a t

(** [enabled_values t] returns the values of all non-disabled items, in order. *)
val enabled_values : 'a t -> 'a list

(** [all_values t] returns the values of all items, in order. *)
val all_values : 'a t -> 'a list

(** [view] renders the dropdown menu as a raw list, without any interaction. Prefer using
    [Skyline_picker_v2.Select_input] which wires up interaction appropriately.

    - [~is_focused] - returns true if the value should be highlighted as selected.
    - [~item_attr] - attached attrs (e.g. an on_click) to each item *)
val view
  :  ?attrs:Vdom.Attr.t list
  -> is_focused:('a -> bool)
  -> item_attr:(disabled:bool -> 'a -> Vdom.Attr.t)
  -> 'a t
  -> Vdom.Node.t
