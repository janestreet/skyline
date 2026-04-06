open! Core
open! Bonsai_web

(** A Skyline-styled anchored popover. Popovers are stateful components that can be opened
    and closed.

    This component provides positioning controls ([position] and [alignment]), focus
    management on open ([focus_on_show]), autoclose behavior on outside click/right-click
    ([close_on_click_outside]) and on Escape (always enabled), and sizing options ([width]
    via [Content]/[Fixed]/[Max]). Two APIs are available: [component] wraps content in a
    Skyline card surface, while [component'] leaves content unwrapped so it can appear to
    "float".

    Common use cases include contextual menus, dropdowns, pickers, small inline forms, and
    detail popovers that should not disturb surrounding layout.

    {b Layout behavior}

    This is an overlay element that sizes to its contents and renders in the browser top
    layer.

    {b Example}

    {[
      Skyline_popover_v2.component
        (fun ~hide:_ (Bonsai.local_ _graph) ->
            Bonsai.return
              %{%html|
                <div style="text-align: center">
                  <h1>Hello world!</h1>
                  <p>Some interactive content here.</p>
                </div>
              |})
        graph
    ]} *)

module Position : sig
  (** Determines the position of the popover relative to the anchor element. [Auto]
      chooses the placement with the most avialable space, while the other options prefer
      to place the popover at the given position (falling back to a different position if
      the popover would otherwise overflow the page). *)
  type t = Bonsai_web_toplayer.Position.t =
    | Auto
    | Top
    | Bottom
    | Left
    | Right
  [@@deriving sexp, equal, compare, enumerate, to_string]
end

module Alignment : sig
  (** Determines how the popover is aligned relative to the anchor element. *)
  type t = Bonsai_web_toplayer.Alignment.t =
    | Center
    | Start
    | End
  [@@deriving sexp_of, equal, to_string]
end

module Match_anchor_side : sig
  (** Determines how the popover is sized relative to the anchor element. *)
  type t = Bonsai_web_toplayer.Match_anchor_side.t =
    | Grow_to_match
    | Match_exactly
    | Shrink_to_match
  [@@deriving sexp_of]
end

(** [t] is the runtime handle for a popover returned by [component] or [component'].

    - [anchor] An attribute to attach to the popover's anchor element. When attached, the
      popover content (rendered in the browser top layer) is positioned relative to that
      element and outside-click handling is enabled according to the component's
      configuration.
    - [is_open] Whether the popover is currently shown. This reflects the state supplied
      via [?state] or the internally managed state.
    - [set_is_open] Effect to open/close the popover. Typical usage is to call
      [set_is_open true] from the anchor's on-click handler, and [set_is_open false] from
      a dismiss control in the content or in response to outside clicks. *)
type t = private
  { anchor : Vdom.Attr.t
  ; is_open : bool
  ; set_is_open : bool -> unit Effect.t
  }

(** A Skyline-styled popover that wraps your [contents] in a [Skyline_card_v2.view].
    Attach the returned [t.anchor] to your anchor element; when [t.is_open] is [true], the
    content is shown in the browser top layer and positioned relative to that anchor.

    Content:
    - [contents] A function that produces the popover body. It receives [~hide], an effect
      you can call to close the popover (equivalent to [set_is_open false]), and [graph].
      The content is rendered in the browser top layer and is not a DOM-child of the
      anchor.

    State:
    - [?state] Supply external state [(is_open, set_is_open)] if you want to control
      visibility from the outside. If omitted, an internal state is created with initial
      value [false] (closed): [Bonsai.state false].

    Arguments and defaults:
    - [?position] Preferred side of the anchor where the popover should appear. [Auto]
      chooses the side with the most available space; [Top], [Bottom], [Left], [Right]
      prefer that side and will fall back when necessary. Default: [Position.Auto].

    - [?alignment] How the popover aligns with the anchor along the cross axis. Default:
      [Alignment.Center].

    - [?focus_on_show] Whether focus should move into the popover when it opens. Default:
      [true].

    - [?match_anchor_side_length] How to size the popover relative to the anchor. Default:
      [None].

    - [?close_on_click_outside] Close the popover when the user clicks (or right-clicks)
      outside the popover. Default: [true]. The Escape key always closes the popover.

    Returns: a [t Bonsai.t] containing [anchor], [is_open], and [set_is_open].

    Notes:
    - Popovers are rendered in the browser top layer. They are not DOM-children of the
      anchor; use design tokens or global styles for styling the content.
    - The returned [anchor] attribute does not itself toggle visibility. Open/close the
      popover by driving [is_open]/[set_is_open], or use [~hide] from within [contents]. *)
val component
  :  ?position:Position.t Bonsai.t
  -> ?alignment:Alignment.t Bonsai.t
  -> ?match_anchor_side_length:Match_anchor_side.t Bonsai.t
  -> ?focus_on_show:bool Bonsai.t
  -> ?close_on_click_outside:bool Bonsai.t
  -> ?state:bool Bonsai.t * (bool -> unit Effect.t) Bonsai.t
  -> (hide:unit Effect.t Bonsai.t -> Bonsai.graph @ local -> Vdom.Node.t Bonsai.t)
  -> Bonsai.graph @ local
  -> t Bonsai.t

(** Like [component], but does not wrap [contents] in a card. This lets you render content
    with no surface (so it appears to "float"). For the meaning, defaults, and interaction
    of all parameters (position, alignment, focus_on_show, close_on_click_outside, width,
    state, contents), see the documentation on [component]. *)
val component'
  :  ?position:Position.t Bonsai.t
  -> ?alignment:Alignment.t Bonsai.t
  -> ?match_anchor_side_length:Match_anchor_side.t Bonsai.t
  -> ?focus_on_show:bool Bonsai.t
  -> ?close_on_click_outside:bool Bonsai.t
  -> ?state:bool Bonsai.t * (bool -> unit Effect.t) Bonsai.t
  -> (hide:unit Effect.t Bonsai.t -> Bonsai.graph @ local -> Vdom.Node.t Bonsai.t)
  -> Bonsai.graph @ local
  -> t Bonsai.t

module For_docs : sig
  val ml_filepath : string
end
