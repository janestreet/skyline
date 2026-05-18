open! Core
open! Bonsai_web

module Container : sig
  val view : ?attrs:Vdom.Attr.t list -> Vdom.Node.t list -> Vdom.Node.t
end

module Item : sig
  val view
    :  ?attrs:Vdom.Attr.t list
    -> size:Skyline_size.t
    -> is_active:bool
    -> is_disabled:bool
    -> Vdom.Node.t list
    -> Vdom.Node.t
end
