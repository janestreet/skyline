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

module Loading : sig
  (** State used to show a loading indicator while [on_click] effects are in progress.

      Note: if a single [Loading_state] is passed to multiple buttons, they will all
      display a loading state as long as one of them has an effect in progress. *)
  module Loading_state : sig
    type t

    val component : Bonsai.graph @ local -> t Bonsai.t
  end

  type t =
    | Yes
    | No
    | While_effect_in_progress of Loading_state.t
    (** [While_effect_in_progress state] wraps [on_click] so the button shows a loading
        indicator while the click effect is in progress. *)

  (** Helper to produce a [While_effect_in_progress] with the initialized state. *)
  val while_effect_in_progress : Bonsai.graph @ local -> t Bonsai.t
end

(** HTML [type] attribute for the underlying [<button/>] element.

    - [Button] for ordinary non-submit buttons, especially buttons inside forms whose
      click action should not submit the form.
    - [Submit] when the button should submit an enclosing [<form/>]. *)
module Type_attr : sig
  type t =
    | Button
    | Submit
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

(** [view] creates a button component.

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
    - [loading] Whether the button shows a loading indicator, defaults to [No]. When in a
      loading state the button is also disabled. See [Loading] for more details.
    - [intent] Color intent for semantic meaning, defaults to [`Secondary]
    - [tooltip] Text to show on hover
    - [tooltip_position] Position of the tooltip relative to the button
    - [show_external_link_icon] Whether to show an external link icon when opening links
      in new tabs. Defaults to [true]
    - [type_attr] HTML [type] attribute for the underlying [<button/>] element. Use
      [Submit] for form-submit buttons and [Button] for non-submit buttons. Defaults to
      [Button]. If [attrs] contains [Vdom.Attr.type_], the default is not applied. If both
      [type_attr] and [Vdom.Attr.type_] are provided explicitly, [attrs] takes precedence
      and [Vdom.Attr] emits a duplicate-attribute warning.
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
  -> ?loading:Loading.t
  -> ?intent:Skyline_intent.t
  -> ?tooltip:string
  -> ?tooltip_position:Skyline_tooltip_v2.Position.t
  -> ?show_external_link_icon:bool
  -> ?type_attr:Type_attr.t
  -> Vdom.Node.t list
  -> on_click:unit Effect.t
  -> Vdom.Node.t

(** Copy creates buttons used for copying text. *)
module Copy : sig
  module State : sig
    type t

    (** Create the state to copy the provided text. *)
    val component : text:string Bonsai.t -> Bonsai.graph @ local -> t Bonsai.t
  end

  (** [view] creates the copy button component.

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
      - [on_copied_tooltip] Tooltip to show when the copy has completed.
      - [on_copied_tooltip_position] Position of the tooltip relative to the button
      - [type_attr] HTML [type] attribute for the underlying [<button/>] element. Use
        [Submit] for form-submit buttons and [Button] for non-submit buttons. Defaults to
        [Button]. If [attrs] contains [Vdom.Attr.type_], the default is not applied. If
        both [type_attr] and [Vdom.Attr.type_] are provided explicitly, [attrs] takes
        precedence and [Vdom.Attr] emits a duplicate-attribute warning.
      - [state] the [State.t] containing the text to copy *)
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
    -> ?on_copied_tooltip:string
    -> ?on_copied_tooltip_position:Skyline_tooltip_v2.Position.t
    -> ?type_attr:Type_attr.t
    -> Vdom.Node.t list
    -> state:State.t
    -> Vdom.Node.t
end

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

module For_testing : sig
  val has_one_child_classname : string
end

module For_docs : sig
  val ml_filepath : string
end
