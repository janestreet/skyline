open! Core
open! Bonsai_web

(** A styled hover tooltip. Attach the returned [attr] to an anchor; on hover, a tooltip
    with your [content] is shown in the browser top layer and positioned relative to that
    anchor. Tooltips are vdom-only (no Bonsai state).

    This component provides positioning controls (position/alignment/offset), visibility
    behaviors (anchor-only hover, anchor-or-content hover, always, never), and style
    options (intent or custom color, optional arrow). It's commonly used for short inline
    help on hover and for explaining icons or truncated text without taking layout space.

    {b Layout behavior}

    This is an overlay element that sizes to its contents and renders in the browser top
    layer. Tooltips are viewport-constrained.

    {b Example}

    {[
      let tooltip = Skyline.Tooltip.text_attr "Floating information" in
      {%html|
        <Skyline.Chip.view %{tooltip}>
          Hover over me
        </>
      |}
    ]} *)

module Position : sig
  (** Determines the position of the tooltip relative to the anchor element. [Auto]
      chooses the placement with the most available space, while the other options prefer
      to place the popover at the given position (falling back to a different position if
      the popover would otherwise overflow the page). *)
  type t = Bonsai_web_toplayer.Position.t =
    | Auto
    | Top
    | Bottom
    | Left
    | Right
  [@@deriving sexp, equal, compare, enumerate]
end

module Offset : sig
  type t = Bonsai_web_toplayer.Offset.t =
    { main_axis : float
    ; cross_axis : float
    }
  [@@deriving sexp, equal, compare]
end

module Alignment : sig
  (** Determines how the popover is aligned relative to the anchor element. *)
  type t = Bonsai_web_toplayer.Alignment.t =
    | Center
    | Start
    | End
  [@@deriving sexp_of]
end

module Color : sig
  type t =
    [ `Success
    | `Danger
    | `Warning
    ]
    constraint t = [< Skyline_intent.t ]
  [@@deriving sexp_of, equal, enumerate, to_string]
end

(** [attr] returns an attribute that you attach to the tooltip's anchor element.

    When the returned attr is present on a node, a Skyline-styled tooltip containing
    [content] will be positioned relative to that node. The tooltip is implemented on top
    of [Bonsai_web_toplayer.tooltip].

    Arguments and defaults:
    - [?test_selector] A selector used by tests to find the tooltip. Applied to the
      tooltip's root; not to the anchor.

    - [?attrs] Additional attributes applied to the tooltip element (e.g., extra classes,
      inline styles, data-* attrs). These do not modify the anchor.

    - [?color] Visual intent of the tooltip surface. Accepts a [Color.t]. (default None).
      The default value is a neutral surface color.

    - [?position] Preferred side of the anchor where the tooltip should appear. [Auto]
      chooses the side with the most available space; [Top], [Bottom], [Left], [Right]
      prefer that side and will fall back when necessary. Default: [Position.Auto].

    - [?offset] Pixel offset between the anchor and the tooltip. [main_axis] moves the
      tooltip away from the anchor along the placement direction; [cross_axis] shifts it
      perpendicular to that direction. Default: [{ main_axis = 4.; cross_axis = 0. }].

    - [?alignment] How the tooltip aligns with the anchor along the cross axis. Default:
      [Alignment.Center].

    - [?behavior] Controls when the tooltip is visible:
      - [`Interactive] — visible when the anchor is hovered and remains visible while
        hovering the tooltip content
      - [`Non_interactive] — visible only while the anchor itself is hovered. This is the
        conventional tooltip behavior.
      - [`Always_show] — tooltip is shown regardless of hover (useful for demos/tests).
      - [`Always_closed] — disables the tooltip (same as not attaching the attr). Default:
        [`Non_interactive].

    - [?arrow] Controls whether the tooltip has a callout arrow that points to the anchor.
      - [`None] — no arrow; the tooltip appears as a floating surface.
      - [`Default] — show a standard arrow (some call it a "caret"). It is automatically
        positioned on the edge facing the anchor and rotated appropriately. Default:
        [`Default].

    Content:
    - [content] The tooltip body as a single [Vdom.Node.t]. Try to keep your content
      short, ideally a single line.

    Notes:
    - Internally, a small show delay (~250ms) and a hide grace period (~120ms) may be
      applied to reduce flicker on quick cursor passes. Values are chosen for sensible UX
      and may change over time.
    - Tooltips are rendered in the browser top layer and are not DOM-children of the
      anchor. Use global styles or tokens for styling.
    - If you need a fully custom arrow, use [Bonsai_web_toplayer.tooltip ~arrow] directly
      with [Bonsai_web_toplayer.arrow_helper], or reach out to Skyline devs for help.

    Returns: a [Vdom.Attr.t] to attach to the anchor node. *)
val attr
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?color:Color.t
  -> ?position:Position.t
  -> ?offset:Offset.t
  -> ?alignment:Alignment.t
  -> ?behavior:[ `Interactive | `Non_interactive | `Always_show | `Always_closed ]
  -> ?arrow:[ `None | `Default ]
  -> Vdom.Node.t
  -> Vdom.Attr.t

(** [text_attr] is a convenience for text-only tooltips. It is equivalent to [attr] but
    takes [string] content directly (internally rendered as a text node).

    For the meaning, defaults, and interaction of most parameters (test_selector, attrs,
    color, position, offset, alignment, behavior, arrow), see the documentation on [attr]. *)
val text_attr
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?color:Color.t
  -> ?position:Position.t
  -> ?offset:Offset.t
  -> ?alignment:Alignment.t
  -> ?behavior:[ `Interactive | `Non_interactive | `Always_show | `Always_closed ]
  -> ?arrow:[ `None | `Default ]
  -> string
  -> Vdom.Attr.t

module For_docs : sig
  val ml_filepath : string
end
