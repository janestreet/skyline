open! Core
open! Bonsai_web

(** A small spinner that can e.g. be used to replace an [Icon_button] in place while
    waiting for something to complete. *)
val spinner : ?icon:Codicons.t -> unit -> Vdom.Node.t

(** A horizontal bar that has a loading indicator running from left-to-right. *)
val runner : unit -> Vdom.Node.t
