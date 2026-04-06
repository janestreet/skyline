open! Core
open! Bonsai_web

(** Return [true] if the provided media query string matches.

    See
    https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_media_queries/Using_media_queries *)
val matches : string -> local_ Bonsai.graph -> bool Bonsai.t
