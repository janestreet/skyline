open! Core
open! Bonsai_web

module Element : sig
  type t

  (* [Scroll_into_view_options] enables customization of the scroll behavior and
     alignments. See MDN for details:
     https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView#sect1
  *)
  module Scroll_into_view_options : sig
    module Behavior : sig
      type t =
        | Smooth
        | Instant
        | Auto
    end

    module Alignment : sig
      type t =
        | Start
        | Center
        | End
        | Nearest
    end

    type t =
      { behavior : Behavior.t
      ; block : Alignment.t
      ; inline : Alignment.t
      }
  end

  val get_by_selector : string -> t option
  val scroll_into_view : ?options:Scroll_into_view_options.t -> t -> unit Effect.t

  (** [focus t] returns an effect that calls [.focus()] on the element.

      Unlike [scroll_into_view], this does _not_ short-circuit in [Node_jsdom_test]: focus
      is observable under jsdom (via [document.activeElement]) and we rely on that for
      keyboard-navigation tests. *)
  val focus : t -> unit Effect.t
end

module Event : sig
  val get_target_bounding_box
    :  Js_of_ocaml.Dom_html.event Js_of_ocaml.Js.t
    -> relative_to:[> `Document | `Viewport ]
       * top:float
       * left:float
       * bottom:float
       * right:float
end
