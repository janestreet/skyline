open! Core
open! Bonsai_web

(** Accordion

    An Accordion is a collapsible [Card]. It's primarily used to give users the option to
    either show or hide content that may not be currently relevant.

    {b Usage}

    - Use [Header.content] for the always-visible summary row users click to toggle
    - Use [Section.content] or [Section.text] for the collapsible content
    - Use [Group_name] and [~group] to make a set where only one item is open at a time
    - Prefer concise headers; keep long content in [Section]

    {b Layout behavior}

    Accordions render as block-level elements that fill the width of their container. The
    header and section expand horizontally to the container's width.

    {b Example}

    {[
      {%html|
        <Accordion.view>
          <Accordion.Header.text>Filters</>
          <Accordion.Section.text>
            … form controls …
          </>
        </>
      |}
    ]} *)

module Header : sig
  type t

  (** [Header.content] creates the accordion header. The header is always visible, and
      clicking on it will expand/collapse the content. *)
  val content
    :  ?test_selector:Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> t

  (** Renders a [Header.content] with a typography wrapper around the contents for base
      text
      - [?test_selector] allows to select the section in tests.
      - [?contents_test_selector] allows to select the sized contents in tests.
      - [?attrs] allows to add arbitrary attrs to this element.
      - [?contents_attrs] allows to add arbitrary attrs to the contents container element. *)
  val text
    :  ?test_selector:Bonsai.Test_selector.t
    -> ?contents_test_selector:Bonsai.Test_selector.t
    -> ?attrs:Vdom.Attr.t list
    -> ?contents_attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> t
end

module Section : sig
  type t

  (** [Section.content] creates the accordion content. The content is visible only in the
      open state.

      - [?full_bleed] controls whether paddings should be added to the section (defaults
        to false) *)
  val content
    :  ?test_selector:Test_selector.t
    -> ?full_bleed:bool
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> t

  (** Renders a [Section.content] with a typography wrapper around the contents for base
      text

      - [?test_selector] allows to select the section in tests.
      - [?attrs] allows to add arbitrary attrs to this element.
      - [?contents_attrs] allows to add arbitrary attrs to the contents container element. *)
  val text
    :  ?test_selector:Bonsai.Test_selector.t
    -> ?full_bleed:bool
    -> ?attrs:Vdom.Attr.t list
    -> Vdom.Node.t list
    -> t
end

(** Identifier for managing grouped accordions. This allows accordion groups to support
    single-selection outside of Bonsai in an automatic way. See [content] for more
    details. *)
module Group_name : sig
  type t

  val create : unit -> t
end

(** [view] creates the accordion component.

    {[
      {%html|
        <Accordion.view>
          <Accordion.Header.text>Header</>
          <Accordion.Section.text>Content</>
        </>
      |}
    ]}

    Parameters:
    - [?default_open] - set whether the accordion is open by default. Changing the initial
      value will reset the accordion's internal state.
    - [?on_toggle] - provide an effect invoked when the accordion state has changed.
    - [?group] - rendering multiple accordions with the same [group_id] will ensure that
    - [?size] Controls the accordion's typography sizing (defaults to [`Md]) *)
val view
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?default_open:bool
  -> ?on_toggle:(open_:bool -> unit Effect.t)
  -> ?group:Group_name.t
  -> ?size:Skyline_size.t
  -> header:Header.t
  -> Section.t list
  -> Vdom.Node.t

module Controlled : sig
  (** [view] creates an accordion with a managed open/close state. Use it when you want to
      programatically control the state (e.g. via Bonsai).

      Parameters:
      - [state] - the value/setter pair controlling whether the accordion is open. *)
  val view
    :  ?test_selector:Test_selector.t
    -> ?size:Skyline_size.t
    -> ?attrs:Vdom.Attr.t list
    -> header:Header.t
    -> Section.t list
    -> state:bool * (bool -> unit Effect.t)
    -> Vdom.Node.t

  (** [make_grouped_state] is a helper to create a state where only one accordion out of
      multiple can be open at a time, keyed by an identifier ['id]. This behavior is
      sometimes called "mutual exclusion", "mutex", "single-select" or "1-of-n".

      {[
        let mutex_state = Accordion.Controlled.make_grouped_state ~equal:Int.equal graph in
        let state_for_accordion1 = mutex_state (Bonsai.return 1)) in
        let state_for_accordion2 = mutex_state (Bonsai.return 2)) in
      ]} *)
  val make_grouped_state
    :  ?initial_open:'id
    -> equal:('id -> 'id -> bool)
    -> Bonsai.graph @ local
    -> ('id Bonsai.t -> bool Bonsai.t * (bool -> unit Effect.t) Bonsai.t)
end

module For_docs : sig
  val ml_filepath : string
end
