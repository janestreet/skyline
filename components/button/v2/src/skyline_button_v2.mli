[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** Buttons are interactive UI elements that trigger actions when clicked. This module
    provides a button component with multiple visual variants, states, and customization
    options.

    The button component supports:
    - Multiple visual variants (filled, ghost, outlined, link, soft)
    - Intent-based coloring (primary, secondary, danger, success, warning)
    - Various sizes (xs, sm, md, lg)
    - Loading and disabled states
    - Optional tooltips
    - Confirmation prompts (in the stateful [component] version)
    - Automatic rendering as HTML links (<a>) when passed [Effect.open_url]

    {b Layout behavior}

    Buttons render as inline elements (inline-flex) and size to their contents by default.

    {b Example}
    {[
      %{%html|<Skyline_button_v2.view ~on_click:%{Effect.Ignore}> Click me </>|}
    ]} *)

(** Visual style variants for buttons. Each variant provides a different visual treatment
    while maintaining consistent interaction patterns.

    - [Filled]: Solid background color with high visual emphasis
    - [Ghost]: No background, only shows background on hover
    - [Outlined]: Transparent background with a colored border
    - [Link]: Minimal styling, appears as a text link
    - [Soft]: Subtle background color with lower visual emphasis *)
module Variant : sig
  type t =
    | Filled
    | Ghost
    | Outlined
    | Link
    | Soft
  [@@deriving enumerate, to_string]
end

(** Loading state for buttons. Used by the [component] function to control when the button
    shows a loading indicator. *)
module Loading : sig
  type t =
    | Yes
    | No
    | While_effect_in_progress
  [@@deriving enumerate, to_string]
end

(** Renders an icon inside a {!view} which inherits the button's size and styling. Icons
    can be placed alongside other elements or used on their own for icon-only buttons.

    {b Example:}
    {[
      {%html|
        <Skyline_button_v2.view ~on_click:%{add_item}>
          <Skyline_button_v2.Icon.view ~icon:%{Lucide.plus} />
          Add Item
        </>
      |}
    ]} *)
module Icon : sig
  val view : ?attrs:Vdom.Attr.t list -> icon:Bonsai_web_icon.t -> unit -> Vdom.Node.t
end

(** [view] creates a stateless button component. Use this when you don't need state
    management features like confirmation prompts or automatic loading state tracking.

    - [test_selector] Optional test selector for unit tests
    - [attrs] Additional Vdom attributes to apply to the button
    - [size] Button size, defaults to [`Md]. Options: [`Xs], [`Sm], [`Md], [`Lg]
    - [slim] Whether to reduce horizontal padding for a narrower button (default false).
      When [false], min-width is set to the height which may cause a square appearance.
      When [true], the padding is reduced and the min-width restriction is lifted for a
      tighter fit. Most useful for icon-only buttons.
    - [variant] Visual style variant, defaults to [Filled]
    - [rounded] Whether to use fully rounded corners (pill shape)
    - [disabled] Whether the button is disabled, defaults to [false]
    - [loading] Whether the button shows a loading indicator, defaults to [false]. When
      [true], the button is also disabled.
    - [intent] Color intent for semantic meaning, defaults to [`Secondary]
    - [tooltip] Text to show on hover
    - [tooltip_position] Position of the tooltip relative to the button
    - [show_external_link_icon] Whether to show an external link icon when opening links
      in new tabs. Defaults to [true]
    - [on_click] Action to perform when clicked. When passed {!Effect.open_url}, the
      button renders as an HTML [<a/>] tag

    {b Example:}
    {[
      view
        ~size:`Sm
        ~variant:Ghost
        ~intent:`Danger
        ~tooltip:"Delete this item"
        ~on_click:delete_effect
        [ Icon.svg Codicons.Trash; Node.text "Delete" ]
    ]} *)
val view
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?size:Skyline_size.t
  -> ?slim:bool
  -> ?variant:Variant.t
  -> ?rounded:bool
  -> ?disabled:bool
  -> ?loading:bool
  -> ?intent:Skyline_intent.t
  -> ?tooltip:string
  -> ?tooltip_position:Skyline_tooltip_v2.Position.t
  -> ?show_external_link_icon:bool
  -> Vdom.Node.t list
  -> on_click:unit Effect.t
  -> Vdom.Node.t

(** [component] creates a stateful button with enhanced features. Use this when you need:
    - Confirmation prompts before executing actions
    - Automatic loading state management

    The stateful component tracks loading state internally and can show a confirmation
    prompt before executing potentially destructive actions.

    - [test_selector] Test selector for automated testing
    - [confirm] When [true], shows "Confirm" and requires a second click
    - [disabled] Whether the button is disabled, defaults to [false]
    - [loading] Loading state control, defaults to [No]. Use [While_effect_in_progress] to
      automatically track the [on_click] effect. When loading is active, the button is
      also disabled.
    - [attrs] Additional Vdom attributes
    - [size] Button size, defaults to [`Md]
    - [slim] Whether to reduce horizontal padding for a narrower button. Most useful for
      icon-only or single-character buttons (e.g., a chevron dropdown trigger). Defaults
      to [false]
    - [variant] Visual style variant, defaults to [Filled]
    - [rounded] Whether to use fully rounded corners
    - [intent] Color intent, defaults to [`Secondary]
    - [tooltip] Hover tooltip text
    - [tooltip_position] Tooltip position
    - [show_external_link_icon] Whether to show an external link icon when opening links
      in new tabs. Defaults to [true]
    - [on_click] Action to perform when clicked. When passed {!Effect.open_url}, renders
      as an HTML [<a/>] tag

    {b Example with confirmation:}
    {[
      let delete_button graph =
        component
          ~confirm:(Bonsai.return true)
          ~intent:(Bonsai.return `Danger)
          ~on_click:(Bonsai.return delete_all_effect)
          (Bonsai.return [ Node.text "Delete All" ])
          graph
      ;;
    ]}

    {b Example with automatic loading state:}
    {[
      let save_button graph =
        component
          ~loading:(Bonsai.return While_effect_in_progress)
          ~on_click:save_to_server_effect
          (Bonsai.return [ Node.text "Save" ])
          graph
      ;;
    ]} *)
val component
  :  ?test_selector:Test_selector.t Bonsai.t
  -> ?confirm:bool Bonsai.t
  -> ?disabled:bool Bonsai.t
  -> ?loading:Loading.t Bonsai.t
  -> ?attrs:Vdom.Attr.t list Bonsai.t
  -> ?size:Skyline_size.t Bonsai.t
  -> ?slim:bool Bonsai.t
  -> ?variant:Variant.t Bonsai.t
  -> ?rounded:bool Bonsai.t
  -> ?intent:Skyline_intent.t Bonsai.t
  -> ?tooltip:string Bonsai.t
  -> ?tooltip_position:Skyline_tooltip_v2.Position.t Bonsai.t
  -> ?show_external_link_icon:bool Bonsai.t
  -> Vdom.Node.t list Bonsai.t
  -> on_click:unit Effect.t Bonsai.t
  -> Bonsai.graph @ local
  -> Vdom.Node.t Bonsai.t

(** [group_style] provides CSS styling for visually grouping buttons together.

    When buttons are direct children of an element with [group_style], their border radii
    are automatically adjusted so that outer corners are rounded and inner corners are
    square, creating a seamless button group appearance. Buttons also share borders so
    that no doubled borders appear between adjacent buttons.

    This is purely CSS styling. It does not provide:
    - Keyboard navigation between grouped buttons
    - ARIA roles or other semantic grouping
    - Validation that children are actually buttons

    The consumer is responsible for layout (e.g., [display: inline-flex]) and any
    accessibility attributes needed for their use case.

    {b Example: Split button pattern}
    {[
      {%html|
        <div %{Skyline_button_v2.group_style} style="display: inline-flex">
          <Skyline_button_v2.view ~on_click:%{primary_action}>
            Save
          </>
          <Skyline_button_v2.view ~slim:true ~on_click:%{open_menu}>
            <Skyline_button_v2.Icon.view ~icon:%{Lucide.chevron_down} />
          </>
        </div>
      |}
    ]} *)
val group_style : Vdom.Attr.t

module For_docs : sig
  val ml_filepath : string
end
