open! Core
open! Bonsai_web

(** A toast allows shows a notification message on the page. It is similar to dialog in
    that there can only be a single toast notification at any given time. *)

(** Returns an effect that can be used to show a toast notification on the page. The toast
    can be dismissed by the user (and automatically dismisses itself after a [timeout]
    (default: 5 seconds)).

    Note that there is only ever one toast visible at a time, similar to e.g. dialog
    elements like [Dialog.alert]. If a toast is shown while a previous toast is active,
    the previous toast will be dismissed.

    Because they are often dismissed automatically, toasts should generally be reserved
    for ephemeral messages.

    The position of toasts can be configured with the [toast_position] argument of
    [Skyline.Entrypoint.install]. *)
val component
  :  Bonsai.graph @ local
  -> (?timeout:Time_ns.Span.t
      -> ?intent:Skyline_theme_v1.Color.t
      -> ?icon:Codicons.t
      -> ?title:string
      -> string
      -> unit Effect.t)
       Bonsai.t

(** Returns an effect that can be used to show a custom toast notification, specified by
    the [close:unit Effect.t -> Vdom.Node.t] function. The custom toast function has
    access to the [~close] effect, which dismisses the toast *)
val custom_component
  :  Bonsai.graph @ local
  -> (?timeout:Time_ns.Span.t -> (close:unit Effect.t -> Vdom.Node.t) -> unit Effect.t)
       Bonsai.t

(** A simple wrapper around [toast] that displays an error message. *)
val error : Bonsai.graph @ local -> (Error.t -> unit Effect.t) Bonsai.t
