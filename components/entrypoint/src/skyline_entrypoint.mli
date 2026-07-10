open! Core
open! Bonsai_web

(** Install Skyline at the top level of this app.

    Note that installing Skyline sets page level globals so this should only be done once
    at the top of your app.

    - [?global_css] sets up a global css style. Defaults to [`Skyline_base_styles] that
      can be found in [lib/skyline/private/theme/base_styles.ml]
    - [?toast_position] defines where the [Skyline.Toast] component should show toasts.
      Defaults to [`Top_left]
    - [?theme] lets you switch between light and dark mainline themes. Defaults to [Light]
    - [?accent] is deprecated as it only affects [Skyline] V1 components.
    - Positional argument is your app's computation *)
val install
  :  ?global_css:[ `Skyline_css_reset | `Skyline_base_styles | `None ] Bonsai.t
  -> ?toast_position:[ `Bottom_left | `Bottom_right | `Top_left | `Top_right ] Bonsai.t
  -> ?theme:Skyline_theme_v1.Style.t Bonsai.t
  -> ?accent:Skyline_theme_v1.Accent.t Bonsai.t
  -> (local_ Bonsai.graph -> Vdom.Node.t Bonsai.t)
  -> (local_ Bonsai.graph -> Vdom.Node.t Bonsai.t)

(** Provides the theme that best matches the user's browser settings. *)
val infer_theme_from_system : local_ Bonsai.graph -> Skyline_theme_v1.Style.t Bonsai.t

(** The currently installed Skyline theme. *)
val theme : local_ Bonsai.graph -> Skyline_theme_v1.Style.t Bonsai.t

(** The currently installed Skyline accent color. *)
val accent : local_ Bonsai.graph -> Skyline_theme_v1.Accent.t Bonsai.t
