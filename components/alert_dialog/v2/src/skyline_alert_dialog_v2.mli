[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** This module provides pre-made alerts.

    It is an Effect-based alternative to the following browser api:
    {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/alert} window.alert}

    {2 Layout behavior}

    This is an overlay element that sizes to its contents and renders in the browser top
    layer. It is presented via a [Modal] and is viewport-constrained. *)

(** An alert dialog effect component displays an alert in a modal dialog. It returns an
    effect that resolves when the modal is closed.

    The bonsai-level-call only requires passing a bonsai graph.

    The in-[let%arr] call takes multiple arguments:
    - [?test_selector], [?button_test_selector] allows selecting parts of the dialog in
      tests
    - [?button_label] lets you customize the label shown on the button used to dismiss the
      alert
    - [?button_intent] lets you change the color of this button
    - [title] is the name of the modal as seen in the header
    - Finally the positional arg is the contents of the modal.

    Example usage:
    {[
      let%arr show_alert = Skyline_alert_dialog_v2.effect graph in
      (* Later, in an event handler: *)
      show_alert {%html|Something went wrong!|} ~title:"Error"
    ]} *)
val effect
  :  Bonsai.graph @ local
  -> (?test_selector:Test_selector.t
      -> ?button_test_selector:Test_selector.t
      -> ?button_label:string
      -> ?button_intent:Skyline_intent.t
      -> Vdom.Node.t
      -> title:string
      -> unit Effect.t)
       Bonsai.t

module For_screenshot_testing : sig
  val view
    :  ?test_selector:Test_selector.t
    -> ?button_test_selector:Test_selector.t
    -> ?button_label:string
    -> ?button_intent:Skyline_intent.t
    -> Vdom.Node.t
    -> title:string
    -> close:unit Effect.t
    -> Vdom.Node.t
end

module For_docs : sig
  val ml_filepath : string
end
