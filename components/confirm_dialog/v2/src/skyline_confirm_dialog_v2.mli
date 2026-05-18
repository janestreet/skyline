open! Core
open! Bonsai_web

(** This module provides a pre-made confirm dialog.

    This is an Effect-based alternative to the following browser api:
    {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/confirm} window.confirm} *)

(** A confirm dialog effect component that gives back an effect that resolves a boolean
    when the modal is closed: either by selecting the confirm button (true) or dismissing
    the modal (false)

    The outer-call only requires passing a bonsai graph.

    The inner call takes multiple useful arguments:
    - [?test_selector], [?confirm_test_selector], [?cancel_test_selector] allows selecting
      parts of the dialog in tests
    - [?confirm_label] lets you customize the label shown on the button used to confirm
    - [?confirm_intent] lets you change the color of this button
    - [?cancel_label] lets you customize the label shown on the button used to cancel
    - [?cancel_intent] lets you change the color of this button
    - [title] is the name of the modal as seen in the header
    - Finally the positional arg is the contents of the modal.

    Example usage:
    {[
      let%arr confirm = Skyline_confirm_dialog_v2.effect graph in
      (* Later, in an event handler: *)
      match%bind.Effect confirm {%html|Delete this item?|} ~title:"Confirm" with
      | true -> delete_item ()
      | false -> Effect.Ignore
    ]} *)
val effect
  :  Bonsai.graph @ local
  -> (?test_selector:Test_selector.t
      -> ?confirm_test_selector:Test_selector.t
      -> ?cancel_test_selector:Test_selector.t
      -> ?confirm_label:string
      -> ?confirm_intent:Skyline_intent.t
      -> ?cancel_label:string
      -> ?cancel_intent:Skyline_intent.t
      -> Vdom.Node.t
      -> title:string
      -> bool Effect.t)
       Bonsai.t

module For_screenshot_testing : sig
  val view
    :  ?test_selector:Test_selector.t
    -> ?confirm_test_selector:Test_selector.t
    -> ?cancel_test_selector:Test_selector.t
    -> ?confirm_label:string
    -> ?confirm_intent:Skyline_intent.t
    -> ?cancel_label:string
    -> ?cancel_intent:Skyline_intent.t
    -> Vdom.Node.t
    -> title:string
    -> close:unit Effect.t
    -> confirm:unit Effect.t
    -> Vdom.Node.t
end

module For_docs : sig
  val ml_filepath : string
end

module Deprecated : sig
  module Actions : sig
    val view
      :  ?action_attr:Vdom.Attr.t
      -> ?action_label:string
      -> ?close_label:string
      -> ?close_selector:Test_selector.t
      -> ?confirm_selector:Test_selector.t
      -> close:unit Effect.t
      -> [ `Available of unit Effect.t
         | `Unavailable of string option
         | `Unauthorized of string
         | `Disconnected
         ]
      -> Skyline_dialog_v2.Content.t
    [@@deprecated
      "[since 2025-10] Use [Skyline_modal_v2.Footer.view] and [Skyline_button_v2] instead"]
  end
end
