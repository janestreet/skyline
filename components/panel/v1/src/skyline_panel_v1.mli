open! Core
open! Bonsai_web
module Config = Bonsai_web_panel.Config
module Logic = Bonsai_web_panel.Logic
module Ui = Bonsai_web_panel.Ui

(** [Skyline_panel] provides Skyline styles for the [Bonsai_web_panel]. You can use
    [Skyline_panel.style_config] with [Bonsai_web_panel] functions, or just
    [Skyline_panel.component] as shorthand. *)

val style_config : Ui.Style_config.t

val component
  :  logic:'a Logic.t Bonsai.t
  -> content:'a Ui.Content.t
  -> local_ Bonsai.graph
  -> Vdom.Node.t Bonsai.t

(** [columns] renders [views] as evenly-sized, resizable, side-by-side columns.

    If you need control over sizing, titles, or other features, use [component] instead. *)
val columns : Vdom.Node.t list Bonsai.t -> local_ Bonsai.graph -> Vdom.Node.t Bonsai.t

(** [rows] is like [columns], but renders [views] as stacked rows. *)
val rows : Vdom.Node.t list Bonsai.t -> local_ Bonsai.graph -> Vdom.Node.t Bonsai.t
