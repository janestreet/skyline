open! Core
open! Bonsai_web

(** A popover that renders a filterable listbox of suggestions, positioned below its
    anchor. Used internally by [Typeahead_combobox_input].

    Autoclose behavior: clicking outside the popover or the anchor element closes the
    dropdown. Clicking on the anchor (e.g. the text input) does not close it, so the user
    can continue typing while the dropdown is open. *)
val component
  :  is_open:bool Bonsai.t
  -> close:unit Effect.t Bonsai.t
  -> content:(local_ Bonsai.graph -> Vdom.Node.t Bonsai.t)
  -> local_ Bonsai.graph
  -> Vdom.Attr.t Bonsai.t
