(** Creates a reference to DOM elements by key.

    Under the hood we it uses a Virtual_dom hook to register/unregister the underlying
    [Dom_html.element Js.t] in a [Map].

    Invariant: each [key] must be used for at most one element at a time. If multiple
    elements are rendered with the same [key], the tracker will only remember one of them
    (last writer wins), and [destroy] of either element may remove the entry. It won't
    crash, but it may create bugs.

    This is quite similar to Bonsai_web_low_level_vdom.Dom_ref, but with the extra ability
    to retrieve items via key. *)

open! Core
open! Bonsai_web
open! Js_of_ocaml

type 'key t

(** [attr t ~key] attaches a [key] to an element. *)
val attr : 'key t -> key:'key -> Vdom.Attr.t

(** [get t ~key] returns the current DOM element for [key], if any. *)
val get : 'key t -> key:'key -> Dom_html.element Js.t option Effect.t

(** [focus t ~key] focuses the element currently tracked under [key]. Noop if not found. *)
val focus : 'key t -> key:'key -> unit Effect.t

(** [create comparator graph] constructs a new tracker. *)
val create : ('key, 'cmp) Comparator.Module.t -> local_ Bonsai.graph -> 'key t Bonsai.t
