open! Core
open! Bonsai_web

(** Chip

    A Chip is designed to highlight new or important information, such as unread messages,
    notifications, or status updates auxiliary to a primary UI element.

    {b Usage}

    - Notifications: Indicate the number of unread messages in a navigation element that
      will take the user to the messages view.
    - Status Indicators: Use chips to show the status of a document, e.g. "draft" or "has
      unsaved changes". Might be in a footer/header.
    - Aggregations: Display a count of items, such as the number of tasks in a to-do list
      next to the list title.

    {b Layout behavior}

    Chips render as inline elements (inline-flex) and size to their contents. Use them
    inline with text or alongside other controls.

    {b Example}

    {[
      <Chip.view ~color:%{`Success}>Thrusters engaged</>
    ]} *)

module Variant : sig
  type t =
    | Filled
    | Soft
    | Outlined
    | Dashed
  [@@deriving enumerate, to_string]
end

module Color : sig
  module Hue : sig
    type t =
      [ `Red
      | `Orange
      | `Amber
      | `Yellow
      | `Lime
      | `Green
      | `Emerald
      | `Teal
      | `Cyan
      | `Sky
      | `Blue
      | `Indigo
      | `Violet
      | `Purple
      | `Fuchsia
      | `Pink
      | `Rose
      | `Zinc
      ]
    [@@deriving enumerate, to_string, equal, compare]
  end

  type t =
    [ Skyline_intent.t
    | Hue.t
    ]
  [@@deriving enumerate, to_string]
end

(** [view] creates a Chip

    - [?test_selector] - for testing hooks (default None)
    - [?size] - controls component dimensions (default `Md)
    - [?attrs] - add arbitrary attributes to the chip (default None)
    - content - the content
    - [?pill] - whether the chip should be pill-like in appearance (default false)
    - [?color] - the [Color] (default `Secondary) *)
val view
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?size:Skyline_size.t
  -> ?variant:Variant.t
  -> ?pill:bool
  -> ?color:Color.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

module For_docs : sig
  val ml_filepath : string
end
