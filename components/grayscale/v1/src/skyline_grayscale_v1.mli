open! Core
open! Bonsai_web

(** An attribute that can be attached to a container to fade out the contained view to
    gray-scale.

    [disable] will prevent user interactions with the contained view and when [fade] is
    set it will animate the view into the faded state.

    This can be useful e.g. for disabling / visually indicating that some view is stale
    e.g. because connection to the server was lost. *)
val attr : ?disable:bool -> ?fade:Time_ns.Span.t -> percent:int -> unit -> Vdom.Attr.t

(** A shorthand for [Vdom.Node.div ~attrs:[ attr ... ] [ ... ]]. *)
val container
  :  ?disable:bool
  -> ?fade:Time_ns.Span.t
  -> percent:int
  -> Vdom.Node.t
  -> Vdom.Node.t
