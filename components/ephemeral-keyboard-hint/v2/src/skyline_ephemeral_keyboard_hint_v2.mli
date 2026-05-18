[@@@alert
  skyline_beta
    {|
This component is currently in a beta phase. Its styling may change in breaking ways.
If you're interested in using this component please reach out to Skyline devs.
We appreciate your enthusiasm. Thanks.
|}]

open! Core
open! Bonsai_web

(** An ephemeral keyboard shortcut hint badge that can be attached to any element via an
    attr.

    The badge displays a human-readable keystroke label (e.g., "Ctrl+K") positioned
    relative to the anchor element. By default, the badge is hidden and only appears when
    the user holds a modifier key (Ctrl, Alt, or Shift) within a
    [Bonsai_web_keyboard_shortcut] listener boundary.

    This component is designed to work with [Bonsai_web_keyboard_shortcut]'s hint
    mechanism: when a modifier key is pressed, the listener boundary sets a data attribute
    on its DOM element, and the badge's CSS reacts to that attribute to toggle visibility.

    The badge is rendered as a CSS [::after] pseudo-element on the anchor, so no extra DOM
    nodes are injected.

    {b Layout behavior}

    This is an overlay element. The attr sets [position: relative] on the anchor and
    renders the badge as an absolutely-positioned pseudo-element. The badge does not
    affect the anchor's layout.

    {b Example}

    {[
      let hint_attr, register =
        Skyline_ephemeral_keyboard_hint_v2.attr (Keystroke.create' ~ctrl:() KeyK)
      in
      register ~effect:(Bonsai.return my_effect) graph;
      {%html|
        <Skyline_button_v2.view %{hint_attr} ~on_click:%{my_effect}>
          Do something
        </>
      |}
    ]} *)

module Position : sig
  (** Determines where the keyboard hint badge is placed relative to the anchor element.

      - [Bottom]: Centered on the anchor's bottom edge
      - [Top]: Centered on the anchor's top edge
      - [Left]: Centered on the anchor's left edge
      - [Right]: Centered on the anchor's right edge *)
  type t =
    | Bottom
    | Top
    | Left
    | Right
  [@@deriving sexp_of, enumerate]
end

(** [attr] returns an attribute to attach to an anchor element and a [register] function
    that registers the keyboard shortcut with the nearest [Bonsai_web_keyboard_shortcut]
    listener boundary. The keystroke is specified once and used for both the badge label
    and the shortcut registration.

    The badge is hidden by default and becomes visible when a modifier key is held within
    a [Bonsai_web_keyboard_shortcut] listener boundary.

    {b Example}
    {[
      let hint_attr, register =
        Skyline_ephemeral_keyboard_hint_v2.attr (Keystroke.create' ~ctrl:() KeyS)
      in
      register ~effect:(Bonsai.return save_effect) graph;
      {%html|
        <Skyline_button_v2.view %{hint_attr} ~on_click:%{save_effect}>
          Save
        </>
      |}
    ]}

    - [?position] Where to place the badge relative to the anchor (default: [Bottom]).
    - [keystroke] The keystroke to display and register. *)
val attr
  :  ?position:Position.t
  -> Vdom_keyboard.Keystroke.t
  -> Vdom.Attr.t
     * (?prevent_default:bool Bonsai.t
        -> effect:unit Effect.t Bonsai.t
        -> Bonsai.graph @ local
        -> unit)

(** [attr'] is like [attr], but only returns the visual hint attribute without a
    [register] function. Use this when you want to manage shortcut registration
    separately.

    - [?position] Where to place the badge relative to the anchor (default: [Bottom]).
    - [keystroke] The keystroke to display in the badge. *)
val attr' : ?position:Position.t -> Vdom_keyboard.Keystroke.t -> Vdom.Attr.t

module For_docs : sig
  val ml_filepath : string
end
