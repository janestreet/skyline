open! Core
open! Bonsai_web

(** A menu displays a list of actions in a popover. It can be attached to any element and
    triggered via click or right-click.

    {b Example}

    {[
      let menu = Skyline_menu_v2.controller graph in
      let options =
        let%arr action_1 and action_2 in
        {%html|
          <Skyline_menu_v2.Options.create>
            <Skyline_menu_v2.Options.item ~key:%{"action-1"} ~on_click:%{action_1}>
              Action 1
            </>
            <Skyline_menu_v2.Options.item ~key:%{"action-2"} ~on_click:%{action_2}>
              Action 2
            </>
          </>
        |}
      in
      let%arr menu and options in
      {%html|
        <div %{Skyline_menu_v2.on_contextmenu menu ~options:(Effect.return options)}>
          Right click on me!
        </div>
      |}
    ]} *)

(** Menu options express a collection of actions. See {!Options} for how to build the list
    of menu items. *)
module Options = Skyline_menu_v2_options

module Position : sig
  (** Determines the position of the popover relative to the anchor element. [Auto]
      chooses the placement with the most avialable space, while the other options prefer
      to place the popover at the given position (falling back to a different position if
      the popover would otherwise overflow the page). *)
  type t = Bonsai_web_toplayer.Position.t =
    | Auto
    | Top
    | Bottom
    | Left
    | Right
  [@@deriving sexp, equal, compare, enumerate, to_string]
end

module Alignment : sig
  (** Determines how the popover is aligned relative to the anchor element. *)
  type t = Bonsai_web_toplayer.Alignment.t =
    | Center
    | Start
    | End
  [@@deriving sexp_of, equal, to_string]
end

module Open_at : sig
  (** Determines where the menu popover is positioned when triggered.

      - [Cursor] positions the menu at the cursor location (default for both [on_click]
        and [on_contextmenu])
      - [Anchor] positions the menu relative to the anchor element *)
  type t =
    | Anchor
    | Cursor
end

module State : sig
  (** Determines the menu's current state.
      - [Closed] menu is not shown
      - [Opened_at_position] menu is open at the given anchor position *)
  type t =
    | Closed
    | Opened_at_position of (Options.t * Bonsai_web_toplayer.Anchor.t)
end

(** [t] holds the menu's state and a setter to control it.

    - [state] is the current state of the menu (open or closed)
    - [set_state] allows you to programmatically open or close the menu *)
type t = private
  { state : State.t
  ; set_state : State.t -> unit Effect.t
  }

(** Creates a menu [t] that can be attached to elements via [on_click] or
    [on_contextmenu].

    - [?size] controls the size of the menu items (defaults to [`Md])
    - [?position] sets the popover position relative to the anchor (defaults to [Auto])
    - [?alignment] sets the popover alignment relative to the anchor (defaults to [Start])
    - [?state] allows controlling the menu state externally *)
val controller
  :  ?size:Skyline_size.t Bonsai.t
  -> ?position:Position.t Bonsai.t
  -> ?alignment:Alignment.t Bonsai.t
  -> ?state:State.t Bonsai.t * (State.t -> unit Effect.t) Bonsai.t
  -> Bonsai.graph @ local
  -> t Bonsai.t

(** Creates an [attr] that binds an [on_click] event to open the menu.

    - [?open_at] controls where the menu appears: [Cursor] positions it at the cursor
      location, [Anchor] positions it relative to the anchor element (default is [Cursor]) *)
val on_click : ?open_at:Open_at.t -> t -> options:Options.t Effect.t -> Vdom.Attr.t

(** Creates an [attr] that binds an [on_contextmenu] (right-click) event to open the menu.

    - [?open_at] controls where the menu appears: [Cursor] positions it at the cursor
      location, [Anchor] positions it relative to the anchor element (default is [Cursor]) *)
val on_contextmenu : ?open_at:Open_at.t -> t -> options:Options.t Effect.t -> Vdom.Attr.t

module For_docs : sig
  val ml_filepath : string
end
