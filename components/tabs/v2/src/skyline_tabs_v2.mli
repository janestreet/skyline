open! Core
open! Bonsai_web

(** Tabs provide navigation between different content sections with an underlined active
    indicator below the selected tab.

    Tabs support disabled and active states.

    {b Layout behavior}

    Tabs render as a block-level container that fills the width of its parent. Tab labels
    are laid out horizontally within that container.

    {b Example}

    {[
      let module Tab = struct
        type t =
          | Inbox
          | Outbox
          | Draft
        [@@deriving enumerate, equal, string]
      end
      in
      let label = function
        | Tab.Inbox -> {%html|Inbox|}
        | Outbox -> {%html|Outbox|}
        | Draft -> {%html|Draft|}
      in
      Tabs.component
        ~equal:[%equal: Tab.t]
        ~items:(Bonsai.return (Nonempty_list.of_list_exn Tab.all))
        ~label:(Bonsai.return label)
        graph
    ]} *)

(** Represents the tabs component view and state:

    - [value] is the currently selected tab
    - [set_value] programatically swaps the opened tab
    - [view] is the tab selector widget *)
type 'a t = private
  { value : 'a
  ; set_value : 'a -> unit Effect.t
  ; view : Vdom.Node.t
  }

(** [view] creates a stateless tabs component.

    Parameters:
    - Positional arg is a list of options (tabs) that are selectable
    - [equal] - is the equality function for the tab type
    - [state] - is the currently selected tab and tab setter effect
    - [label] - maps the tab type to a Vdom node
    - [?test_selectors] - for testing hooks
    - [?attrs] - additional attrs for the container
    - [?item_attrs] - additional attrs for each tab
    - [?size] - controls tab dimensions (default [`Md])
    - [?is_disabled] - can disable the view so it is non-interactable

    Returns a styled div element containing the tab buttons with an underlined active
    indicator. [component] is easier to use most of the time. *)
val view
  :  ?test_selectors:'a Test_selector.Keyed.t
  -> ?attrs:Vdom.Attr.t list
  -> ?item_attrs:('a -> Vdom.Attr.t list)
  -> ?size:Skyline_size.t
  -> ?is_disabled:('a -> bool)
  -> 'a Nonempty_list.t
  -> equal:('a -> 'a -> bool)
  -> state:'a * ('a -> unit Effect.t)
  -> label:('a -> Vdom.Node.t)
  -> Vdom.Node.t

(** [component] creates a stateful tabs component with state management.

    Same parameters as [view], but accepting Bonsai values for reactivity. Args
    differences:
    - The positional arg is now the bonsai graph
    - [items] - the view's positional arg is now a named arg
    - [?state] - external state management is optional, if not passed, the component is
      will create its own state with [Bonsai_kernel_selection_state.One_of_many].

    Use [view] for expert use-cases where you need to carefully manage bonsai state. *)
val component
  :  ?test_selectors:'a Test_selector.Keyed.t
  -> ?attrs:Vdom.Attr.t list Bonsai.t
  -> ?item_attrs:('a -> Vdom.Attr.t list) Bonsai.t
  -> ?size:Skyline_size.t Bonsai.t
  -> ?state:'a Bonsai.t * ('a -> unit Effect.t) Bonsai.t
  -> ?is_disabled:('a -> bool) Bonsai.t
  -> equal:('a -> 'a -> bool)
  -> items:'a Nonempty_list.t Bonsai.t
  -> label:('a -> Vdom.Node.t) Bonsai.t
  -> local_ Bonsai.graph
  -> 'a t Bonsai.t

module For_docs : sig
  val ml_filepath : string
end
