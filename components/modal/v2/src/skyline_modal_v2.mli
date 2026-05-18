open! Core
open! Bonsai_web

(** A [Modal] wraps content in a container that provides exclusive focus and interaction.
    It displays content in the top layer above all other content and makes the rest of the
    page inert. For example, content behind a Modal becomes non-scrollable while the Modal
    is open.

    Common use-cases:
    - Dialogs boxes (confirmation, alerts, etc.)
    - Command Palettes
    - Quick switchers
    - Enlarged media preview
    - Overlay panels

    {2 Layout behavior}

    This is an overlay element that sizes to its contents and renders in the browser top
    layer. The modal container is viewport-constrained (by default it applies sensible
    max-width/max-height and centers itself).

    {2 Choosing between [component] and [effect]}

    This module provides two ways to create modals:

    - {b [component]} - For standalone modals. Use when:
      - The modal doesn't need to return data as part of an effect chain.
      - You just need to display information or allow standalone interactions.
      - Managing open/close state directly is sufficient.

    - {b [effect]} - For modals as part of an effect chain. Use when:
      - You'd like to use the Modal as part of a series of effects
      - You're implementing confirmation dialogs *)

(** [component] creates a standalone modal. See
    {{!section:"Choosing between component and effect"} choosing guide} for when to use
    this.

    - [?close_on_click_outside] determines if the modal closes when the user clicks
      outside of it and is [false] by default.
    - [?close_on_esc] determines if the modal closes when the user hits the esc key and is
      [true] by default.
    - [?attrs] lets you customize the modal container itself.
    - [?state] programatically control the open state.

    {2 Example}
    {[
      let open_ =
        Skyline.Modal.component
          (fun ~close:_ (_graph @ local) ->
            Bonsai.return
              {%html|
               <Skyline.Dialog.view>
                 <Skyline.Dialog.Body.view>
                   Hello
                 </>
               </>
             |})
          graph
      in
      Bonsai.Edge.lifecycle ~on_activate:open_ graph
    ]}

    You may also create a Modal with "controlled" open_state:
    {[
      let is_open, set_is_open = Bonsai.state false graph in
      let (_ : Skyline.Modal.Controls.t Bonsai.t) =
        Skyline.Modal.component
          ~state:(is_open, set_is_open)
          (fun ~close:_ (_graph @ local) -> Bonsai.return {%html|...|})
          graph
      in
      ()
    ]} *)
val component
  :  ?close_on_click_outside:bool Bonsai.t
  -> ?close_on_esc:bool Bonsai.t
  -> ?attrs:Vdom.Attr.t list Bonsai.t
  -> ?state:bool Bonsai.t * (bool -> unit Effect.t) Bonsai.t
  -> (close:unit Effect.t Bonsai.t -> Bonsai.graph @ local -> Vdom.Node.t Bonsai.t)
  -> Bonsai.graph @ local
  -> unit Effect.t Bonsai.t

(** [effect] creates a modal that returns a value via an Effect. See
    {{!section:"Choosing between component and effect"} choosing guide} for when to use
    this.

    Binding on the effect will open the modal, and closing it will resolve the effect.
    {[
      let get_user_input =
        Skyline.Modal.effect
          (fun initial_value ~close:_ ~resolve (graph @ local) ->
            let input_value, set_input_value = Bonsai.state initial_value graph in
            let on_submit =
              let%arr resolve and input_value in
              resolve input_value
            in
            let%arr input_value and set_input_value and on_submit in
            {%html|...|})
          graph
      in
      let%arr get_user_input in
      let%bind.Effect initial = Effect.return "default text" in
      let%bind.Effect user_input = get_user_input initial in
      Effect.print_s [%message (user_input : string option)]
    ]} *)
val effect
  :  ?close_on_click_outside:bool Bonsai.t
  -> ?close_on_esc:bool Bonsai.t
  -> ?attrs:Vdom.Attr.t list Bonsai.t
  -> ('input Bonsai.t
      -> close:unit Effect.t Bonsai.t
      -> resolve:('res -> unit Effect.t) Bonsai.t
      -> Bonsai.graph @ local
      -> Vdom.Node.t Bonsai.t)
  -> Bonsai.graph @ local
  -> ('input -> 'res option Effect.t) Bonsai.t

module Deprecated : sig
  val always_open
    :  ?close_on_click_outside:bool Bonsai.t
    -> ?close_on_esc:bool Bonsai.t
    -> ?attrs:Vdom.Attr.t list Bonsai.t
    -> (Bonsai.graph @ local -> Vdom.Node.t Bonsai.t)
    -> close:unit Effect.t Bonsai.t
    -> Bonsai.graph @ local
    -> unit
  [@@deprecated "[since 2025-10] Use [Skyline_modal_v2.component] instead"]
end

module For_docs : sig
  val ml_filepath : string
end
