[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** Placeholder provides a standard way to communicate that a section of the page has no
    content, is in an error state, or is otherwise empty. It includes a message for the
    user and optionally a list of actions that the user may wish to take.

    {b Layout behavior}

    The placeholder grows to fill its parent container and centers its content both
    horizontally and vertically.

    {b Example}

    {[
      Skyline_placeholder_v2.view
        ~title:"No results"
        ~message:(Vdom.Node.text "Try a different query")
        [ Skyline_button_v2.view ~on_click [ "Refresh" ] ]
    ]} *)

(** [view] creates the placeholder element.
    - [?test_selector] - attaches a test attribute to the container
    - [?attrs] - additional attributes to apply to the container
    - [?size] - determines the size of the placeholder
    - [?icon] - an optional icon displayed above the title
    - [~title] - heading title text
    - [~message] - message content displayed below the title
    - children are rendered vertically. Should be used for buttons, links, or other
      relevant call-to-action elements. *)
val view
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> ?size:Skyline_size.t
  -> ?icon:Bonsai_web_icon.t
  -> title:string
  -> message:Vdom.Node.t
  -> Vdom.Node.t list
  -> Vdom.Node.t

module For_docs : sig
  val ml_filepath : string
end
