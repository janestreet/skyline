open! Core
open! Bonsai_web

(** Buttons are one the primary UI elements used for user actions. Each button is labeled
    and performs a primary action when clicked.

    There are [regular], [compact] and [icon] buttons, as well as buttons that are styled
    as [link]s. The button components are avialable either as stateful variants which
    support rich interactions like loading states or as stateless components that only
    support basic options.

    All buttons can also function as HTML links ([<a/>] tags) when passed
    [Effect.open_url] for their [on_click] action. *)

(** The default button component that can be used in most situations. This button is
    labeled with an optional icon and support for intent colors and a secondary style.

    It also supports loading states, a confirm dialog, and a dropdown to disclose a menu
    with secondary actions. *)
val regular
  :  ?test_selector:Test_selector.t Bonsai.t
  -> ?confirm:bool Bonsai.t
  -> ?loading:[ `Yes | `No | `While_on_click_in_flight ] Bonsai.t
  -> ?dropdown:unit Skyline_context_menu_v1.t Bonsai.t
  -> ?autofocus:bool Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?secondary:bool Bonsai.t
  -> ?intent:Skyline_theme_v1.Color.t Bonsai.t
  -> ?tooltip:string Bonsai.t
  -> ?icon:Codicons.t Bonsai.t
  -> on_click:unit Effect.t Bonsai.t
  -> string Bonsai.t
  -> Bonsai.graph @ local
  -> Vdom.Node.t Bonsai.t

(** A stateless version of the [regular] button component. This can be useful if having
    separate Bonsai state for the button is too heavy weight or if stateful features like
    a loading state or dropdown are not required. *)
val regular'
  :  ?test_selector:Test_selector.t
  -> ?autofocus:bool
  -> ?disabled:bool
  -> ?secondary:bool
  -> ?intent:Skyline_theme_v1.Color.t
  -> ?tooltip:string
  -> ?icon:Codicons.t
  -> on_click:unit Effect.t
  -> string
  -> Vdom.Node.t

(** A more compact button component that has the same visual height as [icon] buttons.
    This button is labeled with an additional icon and support for intent colors and
    secondary style.

    It also supports loading states, a confirm dialog, and a dropdown to disclose a menu
    with secondary actions.

    This button is a good choice in UIs which require more density or for secondary
    actions where a [regular] button feels to heavy weight. *)
val compact
  :  ?test_selector:Test_selector.t Bonsai.t
  -> ?confirm:bool Bonsai.t
  -> ?loading:[ `Yes | `No | `While_on_click_in_flight ] Bonsai.t
  -> ?dropdown:unit Skyline_context_menu_v1.t Bonsai.t
  -> ?autofocus:bool Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?secondary:bool Bonsai.t
  -> ?intent:Skyline_theme_v1.Color.t Bonsai.t
  -> ?tooltip:string Bonsai.t
  -> ?icon:Codicons.t Bonsai.t
  -> on_click:unit Effect.t Bonsai.t
  -> string Bonsai.t
  -> Bonsai.graph @ local
  -> Vdom.Node.t Bonsai.t

(** A stateless version of the [compact] button component. This can be useful if having
    separate Bonsai state for the button is too heavy weight or if stateful features like
    a loading state or dropdown are not required. *)
val compact'
  :  ?test_selector:Test_selector.t
  -> ?autofocus:bool
  -> ?disabled:bool
  -> ?secondary:bool
  -> ?intent:Skyline_theme_v1.Color.t
  -> ?tooltip:string
  -> ?icon:Codicons.t
  -> on_click:unit Effect.t
  -> string
  -> Vdom.Node.t

(** A button component for secondary or contextual actions. This button shows an icon with
    optional tooltip and support for intent colors.

    It also supports loading states, a confirm dialog, and a dropdown to disclose a menu
    with secondary actions.

    This button is a good choice for secondary or contextual actions or when there is
    limited space. *)
val icon
  :  ?test_selector:Test_selector.t Bonsai.t
  -> ?loading:[ `Yes | `No | `While_on_click_in_flight ] Bonsai.t
  -> ?dropdown:unit Skyline_context_menu_v1.t Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?intent:Skyline_theme_v1.Color.t Bonsai.t
  -> ?tooltip:string Bonsai.t
  -> on_click:unit Effect.t Bonsai.t
  -> Codicons.t Bonsai.t
  -> Bonsai.graph @ local
  -> Vdom.Node.t Bonsai.t

(** A stateless version of the [icon'] button component. This can be useful if having
    separate Bonsai state for the button is too heavy weight or if stateful features like
    a loading state or dropdown are not required. *)
val icon'
  :  ?test_selector:Test_selector.t
  -> ?disabled:bool
  -> ?intent:Skyline_theme_v1.Color.t
  -> ?tooltip:string
  -> on_click:unit Effect.t
  -> Codicons.t
  -> Vdom.Node.t

(** A button styled as a link. This should be used for simple actions like revealing more
    information or for actions that perform link like navigation.

    When passed [Effect.open_url] as the [on_click] action the button is rendered as a
    HTML [<a/>] tag. *)
val link
  :  ?test_selector:Test_selector.t
  -> ?disabled:bool
  -> ?intent:Skyline_theme_v1.Color.t
  -> ?font:Skyline_text_v1.Font_family.t
  -> ?size:Skyline_text_v1.Font_size.t
  -> ?style:Skyline_text_v1.Font_style.t
  -> ?icon:Codicons.t
  -> on_click:unit Effect.t
  -> string
  -> Vdom.Node.t

(** [with_error] is a simple way to handle errors that can occur in the buttons [on_click]
    action. It is visually the same as the [regular] button.

    While this makes error handling easy for the developer, a dedicated error UI e.g.
    using {!val:Error_handler.component} usually improves the user experience. *)
val with_error
  :  ?test_selector:Test_selector.t Bonsai.t
  -> ?confirm:bool Bonsai.t
  -> ?loading:[ `Yes | `No | `While_on_click_in_flight ] Bonsai.t
  -> ?dropdown:unit Or_error.t Skyline_context_menu_v1.t Bonsai.t
  -> ?on_dropdown_open:unit Effect.t Bonsai.t
  -> ?autofocus:bool Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?secondary:bool Bonsai.t
  -> ?intent:Skyline_theme_v1.Color.t Bonsai.t
  -> ?tooltip:string Bonsai.t
  -> ?icon:Codicons.t Bonsai.t
  -> on_click:unit Or_error.t Effect.t Bonsai.t
  -> string Bonsai.t
  -> Bonsai.graph @ local
  -> Vdom.Node.t Bonsai.t

(** [with_error_compact] is the same as [with_error] (including all the caveats!) but uses
    the compact button layout instead *)
val with_error_compact
  :  ?test_selector:Test_selector.t Bonsai.t
  -> ?confirm:bool Bonsai.t
  -> ?loading:[ `Yes | `No | `While_on_click_in_flight ] Bonsai.t
  -> ?dropdown:unit Or_error.t Skyline_context_menu_v1.t Bonsai.t
  -> ?on_dropdown_open:unit Effect.t Bonsai.t
  -> ?autofocus:bool Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?secondary:bool Bonsai.t
  -> ?intent:Skyline_theme_v1.Color.t Bonsai.t
  -> ?tooltip:string Bonsai.t
  -> ?icon:Codicons.t Bonsai.t
  -> on_click:unit Or_error.t Effect.t Bonsai.t
  -> string Bonsai.t
  -> Bonsai.graph @ local
  -> Vdom.Node.t Bonsai.t
