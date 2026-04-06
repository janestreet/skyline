open! Core
open! Bonsai_web

(** Skyline Text v2 provides typography primitives for UI copy and headings.

    It exposes:
    - Body text via [view]
    - Monospace body text via [monospace]
    - Semantic heading elements via [h1]-[h6]
    - Inline code snippets via [inline_code]

    Common use-cases:
    - Rendering labels, helper copy, and inline text
    - Code-like or fixed-width values (use [monospace])
    - Section headings and page titles (use [h1]-[h6])

    {b Layout behavior}

    - The main [view]/[monospace] APIs render inline elements (<span>) that size to their
      contents. Use these inline with other text or controls.
    - The [h1]–[h6] APIs render block-level heading elements that fill the width of their
      container.

    {b Example}

    {[
      {%html|
        <>
          <Skyline_text_v1.h1> This is some content... </>
          <Skyline_text_v1.view ~size:%{`Md}>The quick brown fox jumps over the lazy dog</>
          <Skyline_text_v1.monospace ~size:%{`Inherit}>let foo = bar</>
        </>
      |}
    ]} *)

module Size : sig
  (** Discrete font-size scale for body text. The default size is [`Inherit].

      - [`Inherit] Do not specify font-size or line-height; inherit from parent. The
        default.
      - [`Two_xs] 10px/12px line-height
      - [`Xs] 12px/16px line-height
      - [`Sm] 14px/20px line-height
      - [`Md] 16px/24px line-height
      - [`Lg] 18px/28px line-height
      - [`Xl] 20px/28px line-height
      - [`Two_xl] 24px/32px line-height
      - [`Three_xl] 30px/36px line-height
      - [`Four_xl] 36px/40px line-height
      - [`Five_xl] 48px/48px line-height *)
  type t =
    [ `Inherit
    | `Two_xs
    | `Xs
    | `Sm
    | `Md
    | `Lg
    | `Xl
    | `Two_xl
    | `Three_xl
    | `Four_xl
    | `Five_xl
    ]
  [@@deriving enumerate, to_string, sexp, equal]
end

module Weight : sig
  (** Discrete font-weight scale for body text. The default weight is [`Inherit].

      - [`Inherit] Do not specify font-weight; inherit from parent. The default.
      - [`Light] 300 weight
      - [`Normal] 400 weight
      - [`Medium] 500 weight
      - [`Semibold] 600 weight
      - [`Bold] 700 weight *)
  type t =
    [ `Inherit
    | `Light
    | `Normal
    | `Medium
    | `Semibold
    | `Bold
    ]
  [@@deriving enumerate, to_string, sexp, equal]
end

module Color : sig
  type t =
    [ `Inherit
    | `Default
    | Skyline_intent.t
    | Css_gen.Color.t
    ]
end

module Layout : sig
  (** Defines how to display this text modifier in the layout.

      We only advise you either one of those 2 options:
      - [`Inline] (default) will present the text modifier as an inline element
      - [`Contents] will not make this element participate in the layout by applying the
        [display: contents] CSS rule, making this element virtually inexistent for the
        layout. You should only use [`Contents] if you plan to wrap other
        elements. **WARNING** Passing directly text nodes to a [`Contents] wrapper will
        not set the line-height properly. *)
  type t =
    [ `Inline
    | `Contents
    ]
end

(** [view] renders body text. It inherits whatever the current font-family is.

    - [?size] typography size on the [Size] scale (default [`Inherit])
    - [?weight] typography weight on the [Weight] scale (default [`Inherit])
    - [?color] text color (default [`Inherit])
    - [?attrs] additional attrs to apply to the underlying span (default [])
    - [?test_selector] test hook (default [None])
    - Positional argument is content nodes to render inside the element, usually just text

    Returns a [<span>] node. *)
val view
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?size:Size.t
  -> ?weight:Weight.t
  -> ?color:Color.t
  -> ?layout:Layout.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** [monospace] renders body text with a monospace font family.

    Use [monospace] when you just want the monospace font. Use [inline_code] when you want
    text to visually look like a code snippet (includes background color, padding, and
    border-radius).

    Parameters are the same as [view]. *)
val monospace
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?size:Size.t
  -> ?weight:Weight.t
  -> ?color:Color.t
  -> ?layout:Layout.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** [link] renders inline text as a link (<a> tag).

    It mirrors the [view] API and additionally supports semantic coloring via [~intent]
    and arbitrary click actions via [~on_click], similar to {!Skyline_button_v2.view} when
    used with the [Link] variant.

    - [?attrs] additional attrs to apply to the underlying anchor (default [])
    - [?test_selector] test hook (default [None])
    - [?size] typography size on the [Size] scale (default [`Inherit])
    - [?weight] typography weight on the [Weight] scale (default [`Inherit])
    - [?color] color for semantic meaning (default [`Primary])
    - [?show_external_link_icon] when [true], shows an external-link icon for
      [Effect.Open_url] targets that open in a new tab/window (default [true])
    - [on_click] action to perform when clicked. When passed {!Effect.open_url}, the
      element renders as an HTML [<a href=... target=...>] link
    - [children] content nodes to render inside the element

    Returns an [<a>] node. *)
val link
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?size:Size.t
  -> ?weight:Weight.t
  -> ?color:Color.t
  -> ?show_external_link_icon:bool
  -> Vdom.Node.t list
  -> on_click:unit Effect.t
  -> Vdom.Node.t

(** [h1] renders a level‑1 heading styled according to Skyline typography.

    - [?attrs] additional attrs (default [])
    - [?test_selector] test hook (default [None])
    - [?color] text color (default [`Default])
    - Positional argument is heading content

    Returns an [<h1>] node. *)
val h1
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?color:Color.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** [h2] renders a level‑2 heading. Returns an [<h2>] node. *)
val h2
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?color:Color.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** [h3] renders a level‑3 heading. Returns an [<h3>] node. *)
val h3
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?color:Color.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** [h4] renders a level‑4 heading. Returns an [<h4>] node. *)
val h4
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?color:Color.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** [h5] renders a level‑5 heading. Returns an [<h5>] node. *)
val h5
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?color:Color.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** [h6] renders a level‑6 heading. Returns an [<h6>] node. *)
val h6
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?color:Color.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

(** [inline_code] renders an inline code element with typography styling.

    Use [inline_code] when you want text to visually look like a code snippet — it
    includes a background color, padding, and border-radius in addition to the monospace
    font. Use [monospace] when you just want the monospace font without additional
    styling.

    - [?test_selector] test hook (default [None])
    - [?attrs] additional attrs (default [])
    - [?size] typography size on the [Size] scale (default [`Inherit])
    - [?weight] typography weight on the [Weight] scale (default [`Inherit])
    - [?color] text color (default [`Inherit])
    - Positional argument is code content

    Returns a [<code>] node. *)
val inline_code
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?size:Size.t
  -> ?weight:Weight.t
  -> ?color:Color.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

module For_docs : sig
  val ml_filepath : string
end
