open! Core
open! Bonsai_web

(** Context menus show a list of actions a user might take in an overlay view, typically
    anchored at the cursor or to a dropdown-button element.

    They are both keyboard and mouse-controllable an are constructed from a list of menu
    items. Menu items themselves might also contain additional items e.g. in a submenu. *)

module Item : sig
  (** An item which can appear in a context menu. *)
  type 'a t [@@deriving sexp_of]

  (** Create a menu item that triggers the provided effect when selected. *)
  val single
    :  ?key:string
    -> ?disabled:bool
    -> ?icon:Codicons.t
    -> ?intent:Skyline_theme_v1.Color.t
    -> ?detail:string
    -> on_click:'a Effect.t
    -> string
    -> 'a t

  (** Group a list of menu items into a section. If the section is empty it does not
      render. *)
  val section : ?title:string -> 'a t list -> 'a t

  (** Group a list of menu items into a submenu. Empty submenus are always shown as
      disabled. *)
  val submenu
    :  ?key:string
    -> ?disabled:bool
    -> ?icon:Codicons.t
    -> ?intent:Skyline_theme_v1.Color.t
    -> title:string
    -> 'a t list
    -> 'a t

  module Expert : sig
    (** Map all [on_click] actions included in this menu item and any children it
        contains. *)
    val map_actions : 'a t -> f:('a Effect.t -> 'b Effect.t) -> 'b t
  end
end

(** A context menu is a list of items. *)
type 'a t = 'a Item.t list [@@deriving sexp_of]

(** Attach a context menu to a [Vdom.Node.t]. By default the menu opens on right-click and
    is positioned at the cursor position at the time the menu was opened. *)
val component
  :  ?position_at_cursor:bool Bonsai.t
  -> ?on_contextmenu:bool Bonsai.t
  -> ?on_click:bool Bonsai.t
  -> unit t Bonsai.t
  -> local_ Bonsai.graph
  -> Vdom.Attr.t Bonsai.t

(** A lower level component that provides a menu which is attached to another dom element
    like a [Popover], it behaves the same as
    [component ~position_at_cursor:(return false)], except that the caller is responsible
    for triggering the menu using the returned effect.

    You usually want to use [component] instead. *)
val manual_popover
  :  ?position:Skyline_popover_v1.Position.t Bonsai.t
  -> ?alignment:Skyline_popover_v1.Alignment.t Bonsai.t
  -> unit t Bonsai.t
  -> local_ Bonsai.graph
  -> Vdom.Attr.t Bonsai.t * unit Effect.t Bonsai.t

(** A lower level component which provides a menu that is displayed at the position
    provided when triggering the effect. This behaves like e.g. the [on_click] attr
    returned from [component] except that the caller is responsible for triggering the
    menu using the returned effect.

    You usually want to use [component] instead. *)
val manual_position
  :  unit t Bonsai.t
  -> local_ Bonsai.graph
  -> (top:float -> left:float -> unit Effect.t) Bonsai.t
