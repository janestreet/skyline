[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** A radio group component to manage multiple radio inputs, derived from a set of values. *)

(** Represents the tabs component view and state:

    - [value] is the currently selected radio input
    - [set_value] programatically changes the selected radio input
    - [view] is the radio group widget *)
type 'a t = private
  { value : 'a
  ; set_value : 'a -> unit Effect.t
  ; view : Vdom.Node.t
  }

(** [view] renders a stateless group of radio inputs representing mutually exclusive
    values.

    Parameters:
    - [test_selectors] - Optional keyed test selector for each radio input
    - [attrs] - Additional Vdom attributes to apply to the group container
    - [size] - Controls font size and padding (default [`Md]) for all radio inputs
    - [intent] - Visual style variant (default [`Primary]) for all radio inputs
    - [disabled] - Flag to disable all radio inputs (default [false])
    - [name] - A unique name to distinguish this radio group instance. Radio inputs with
      the same name form a group where the browser handles keyboard navigation.
    - [state] - The currently selected value and setter
    - [equal] - Equality function for values
    - [to_string] - Converts a value to a string label to be shown next to its radio input
    - [values] - List of values to display as radio inputs

    Use [component] for most use-cases where you want automatic state management. *)
val view
  :  ?test_selectors:'a Test_selector.Keyed.t
  -> ?attrs:Vdom.Attr.t list
  -> ?size:Skyline_size.t
  -> ?intent:Skyline_field_v2.Intent.t
  -> ?disabled:bool
  -> name:string
  -> state:'a * ('a -> unit Effect.t)
  -> equal:('a -> 'a -> bool)
  -> to_string:('a -> string)
  -> values:'a list
  -> unit
  -> Vdom.Node.t

(** [view_with_state] is like [view], but also returns the currently selected value via
    the [t] representation. *)
val view_with_state
  :  ?test_selectors:'a Test_selector.Keyed.t
  -> ?attrs:Vdom.Attr.t list
  -> ?size:Skyline_size.t
  -> ?intent:Skyline_field_v2.Intent.t
  -> ?disabled:bool
  -> name:string
  -> state:'a * ('a -> unit Effect.t)
  -> equal:('a -> 'a -> bool)
  -> to_string:('a -> string)
  -> values:'a list
  -> unit
  -> 'a t

(** [component] creates a stateful radio group for more advanced state management.

    Same parameters as [view], but accepting Bonsai values for reactivity. Args
    differences:
    - The positional arg is now the bonsai graph
    - [?state] - External state management is optional, if not passed, the component is
      will create its own state with [Bonsai_kernel_selection_state.One_of_many].
    - A group name is no longer required *)
val component
  :  ?test_selectors:'a Test_selector.Keyed.t
  -> ?attrs:Vdom.Attr.t list Bonsai.t
  -> ?size:Skyline_size.t Bonsai.t
  -> ?intent:Skyline_field_v2.Intent.t Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?state:'a Bonsai.t * ('a -> unit Effect.t) Bonsai.t
  -> equal:('a -> 'a -> bool)
  -> to_string:('a -> string)
  -> values:'a Nonempty_list.t Bonsai.t
  -> local_ Bonsai.graph
  -> 'a t Bonsai.t

module For_docs : sig
  val ml_filepath : string
end

module For_testing : sig
  val ascii_render
    :  selected:'a
    -> values:'a list
    -> to_string:('a -> string)
    -> equal:('a -> 'a -> bool)
    -> string
end
