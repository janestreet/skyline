[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** A [Dialog] is a layout view that is usually used within a [Modal] compponent.

    Dialogs are created by composing multiple subviews together:
    - [Section.title] emphasizes its contents and reserves space for the close button.
    - [Section.text] wraps the main content and can scroll when the dialog would otherwise
      overflow.
    - [Section.footer] is a container for action buttons.
    - [Close_button] is a special button that gets placed in the header while being
      ordered last in the DOM.

    {b Layout behavior}

    The [Dialog.view] itself renders as a block element that sizes to its contents. It is
    typically used inside a [Modal], which makes it an overlay element rendered in the
    browser top layer and constrained by the viewport.

    {b Example}
    {[
      {%html|
        <Skyline.Dialog.view>
          <Skyline.Dialog.Section.title>
            Dialog with separators
          </>
          <Skyline.Dialog.Close_button.content ~close:%{Effect.Ignore} />
          <Skyline.Dialog.Section.separator />
          <Skyline.Dialog.Section.text>
            This is the content of a dialog that can be used to display bigger blocks of
            content
          </>
          <Skyline.Dialog.Section.separator />
          <Skyline.Dialog.Section.footer>
            <Skyline.Button.view ~on_click:%{Effect.Ignore}>
              Confirm
            </>
            <Skyline.Button.view ~on_click:%{Effect.Ignore} ~intent:%{`Secondary}>
              Cancel
            </>
          </>
        </>
      |}
    ]} *)

(** Opaque module reflecting content that is valid inside a [view]. *)
module Content : sig
  type t

  (** Similar to [Vdom.Node.fragment] *)
  val fragment : t list -> t
end

(** A dialog view's root.

    Container for the dialog layout. You should only provide subviews from this module as
    children.

    - [?test_selector] allows to select the element in tests.
    - [?size] scales the size of [Dialog.*] view elements.
    - [?attrs] allows to add arbitrary attrs to this element. We do not advise attaching
      style alterations to this element.

    {2 In Modals}

    By default a dialog will show up in the document's flow; it will not appear "over" the
    app in the way most dialogs are designed.

    To get a "modal" dialog, use with the [Modal.component] in [Skyline_modal_v2]. *)
val view
  :  ?test_selector:Bonsai.Test_selector.t
  -> ?size:Skyline_size.t
  -> ?attrs:Vdom.Attr.t list
  -> Content.t list
  -> Vdom.Node.t

module Section : sig
  (** Renders a dialog section with appropriate paddings from the Dialog's [~size].
      Defaults to a standard block layout.

      - [?test_selector] allows selecting the element in tests.
      - [?scrollable] when [true], the section grows and becomes scrollable if needed
        (defaults to [true]).
      - [?full_bleed] removes margins and lets the user fill the whole space (defaults to
        [false]).
      - [?attrs] allows adding arbitrary attributes to this element. *)
  val content
    :  ?test_selector:Bonsai.Test_selector.t
    -> ?scrollable:bool
    -> ?full_bleed:bool
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Content.t

  (** A horizontal separator between sections *)
  val separator : ?attrs:Vdom.Attr.t list -> unit -> Content.t

  (** [Section.title] creates a section styled for a dialog title.

      Internally, [Section.title] combines [Section.content] with typography, and sets
      [role="sectionhead"] on the section element.

      - [?test_selector] allows to select the section in tests.
      - [?scrollable] grows the element to its contents until it's prevented to do it.
        When it is, a scrollbar should show. (defaults to [false])
      - [?full_bleed] removes margins and lets the user fill the whole space
      - [?attrs] allows to add arbitrary attrs to this element. *)
  val title
    :  ?test_selector:Bonsai.Test_selector.t
    -> ?scrollable:bool
    -> ?full_bleed:bool
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Content.t

  (** [Section.text] creates a standard dialog content section with appropriate spacing
      and text size.

      Internally, [Section.text] combines [Section.content] with typography.

      - [?test_selector] allows to select the section in tests.
      - [?scrollable] grows the element to its contents until it's prevented to do it.
        When it is, a scrollbar should show. (defaults to [true])
      - [?full_bleed] removes margins and lets the user fill the whole space
      - [?attrs] allows to add arbitrary attrs to this element. *)
  val text
    :  ?test_selector:Bonsai.Test_selector.t
    -> ?scrollable:bool
    -> ?full_bleed:bool
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Content.t

  (** Renders a [Section.view] that is meant to be used as a footer, it notably defaults
      as a non-scrollable region and becomes a flex row container by default.

      It also sets a [role="navigation"] attribute.

      - [?test_selector] allows to select the section in tests.
      - [?scrollable] grows the element to its contents until it's prevented to do it.
        When it is, a scrollbar should show. (defaults to [false])
      - [?full_bleed] removes margins and lets the user fill the whole space
      - [?attrs] allows to add arbitrary attrs to this element. *)
  val footer
    :  ?test_selector:Bonsai.Test_selector.t
    -> ?scrollable:bool
    -> ?full_bleed:bool
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> Content.t
end

module Close_button : sig
  (** Renders a close <button>, absolutely positioned to the top-right.

      This means that this button can be added at the end of the modal to keep the vdom
      ordering of having the close button at the end.

      - [close] should be passed an effect that closes the dialog. *)
  val content
    :  ?test_selector:Bonsai.Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> unit
    -> close:unit Effect.t
    -> Content.t
end

module For_docs : sig
  val ml_filepath : string
end
