[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** An individual radio button control for selecting between mutually exclusive values. *)

(** [content] creates a `Content.t` that can inherit sizing / intent from
    [Skyline_field_v2.content].

    Parameters:
    - [group] - the name of the group the radio input belongs to. Radio inputs with the
      same group name form a radio group where only one can be selected
    - [state] - a pair containing a boolean value (whether or not the radio input is
      checked), and an effect that runs upon selecting the radio input *)
val content
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> group:string
  -> state:bool * unit Effect.t
  -> unit
  -> Skyline_field_v2.Content.t

module For_docs : sig
  val ml_filepath : string
end
