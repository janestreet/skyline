open! Core
open! Bonsai_web

(** Banners communicate status and inline messages with optional actions.

    A [Banner] is a container view for composing multiple subviews:
    - [Header] should always be used within a Banner, it supports a title, optional icon
      and arbitrary children (commonly a list of button controls)
    - [Section] can be used for secondary, more verbose information, usually a paragraph
      of text. Its intended use is to be shown/hidden based on a "collapse" affordance in
      the header.

    Non-banner child components in the [Header] and [Section] will need to be explicitly
    sized to look right. For Button, use the following mapping:
    - If using a [`Xs] banner, use an [`Xs] Button
    - If using a [`Sm] banner, use a [`Sm] Button
    - If using a [`Md] or larger banner, use a [`Md] Button

    {b Layout behavior}

    Banners render as block-level elements and, by default, fill the width of their
    container. Place them at the top of a page/section.

    {b Example}

    {[
      {%html|
        <Skyline.Banner.view>
          <Skyline.Banner.Header.text>
            <Skyline.Banner.Header.icon ~icon:%{Lucide.info} />
            A capybara has been sighted!
            <Skyline.Banner.Header.spacer />
            <Skyline.Button.view ~on_click:%{Effect.Ignore} ~variant:%{Ghost}>
              Dismiss
            </>
          </>
        </>
      |}
    ]} *)

module Content : sig
  type t
end

(** A banner container.

    Parameters:
    - [?test_selector] attaches an attribute to the container for testing
    - [?attrs] extra attributes applied to the banner container
    - [?size] controls padding, text, and icon size. Other [Banner.*] elements inherit
      this size. (default [`Md])
    - [?intent] sets icon, background, and text colors. Other [Banner.*] elements inherit
      this. (default [`Primary])
    - [?loading] renders a loading indicator on the bottom edge if true. (default none)

    Returns a single [Node.t] banner. *)
val view
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?size:Skyline_size.t
  -> ?intent:Skyline_intent.t
  -> ?loading:[ `Indeterminate ]
  -> Content.t list
  -> Vdom.Node.t

module Header : sig
  (** Renders a header, inheriting coloring and padding based on the containing
      [Banner.view].

      Parameters:
      - [?test_selector] attaches an attribute for testing
      - [?attrs] extra attributes
      - children are rendered in a flex row. In userland, compose your own layout, e.g. a
        left cluster dwith an optional icon and title, and a right cluster with action
        buttons. *)
  val view
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Content.t

  (** [Header.text] creates a banner header row with appropriate spacing and text size.

      Internally, [Header.text] combines [Header.view] with a typography element.

      - Inherits colors from the surrounding [Banner.view] intent
      - Applies gap and icon sizing that scale with the banner [~size]
      - Maps [~size] to a nice-looking [Skyline_text_v2.Size]

      Parameters:
      - [?test_selector] attaches an attribute for testing
      - [?attrs] additional attributes forwarded to [view]

      Children: the textual content, passed through to [Skyline_text_v2.view]. *)
  val text
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list (*_ -> ?size:Skyline_size.t *)
    -> Vdom.Node.t list
    -> Content.t

  (** Renders a [Bonsai_web_icon] with appropriate sizing for the inherited font-size.
      Colored based on intent.

      This is meant to be used within a [text] element.

      Parameters:
      - [?test_selector] attaches an attribute for testing
      - [?attrs] additional attributes forwarded to [view]
      - [icon] icon rendered at a size that matches the banner and tinted with the banner
        intent *)
  val icon
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> icon:Bonsai_web_icon.t
    -> unit
    -> Vdom.Node.t

  (** A flex spacer to be used between text content and action buttons. *)
  val spacer : unit -> Vdom.Node.t
end

module Section : sig
  (** Renders a section, inheriting padding based on the size of the containing
      [Banner.view].

      Parameters:
      - [?test_selector] attaches an attribute for testing
      - [?attrs] extra attributes
      - children are rendered within. *)
  val content
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Content.t

  (** [Section.text] creates a banner section with appropriate padding and text size.

      Internally, [Section.text] combines [Section.content] with a typography element.

      - Inherits colors from the surrounding [Banner.view] intent
      - Maps [~size] to a nice-looking [Skyline_text_v2.Size]

      Parameters:
      - [?test_selector] attaches an attribute for testing
      - [?attrs] additional attributes forwarded to [view]

      Children: the textual content, passed through to [Skyline_text_v2.view]. *)
  val text
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Content.t
end

module For_docs : sig
  val ml_filepath : string
end
