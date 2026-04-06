open! Core
open! Bonsai_web

module Layout : sig
  (** Layout for the tree view. The items can either be rendered as a foldable tree with
      indentation or as a flat list showing the full path for every item. *)
  type t =
    | Tree
    | List
  [@@deriving sexp_of]
end

module Decoration : sig
  (** Decoration style for the tree path segment of the given node. A [Primary] path
      segment renders in the forground color, [Secondary] renders in a more muted color.

      If given an [Intent] the path renders with the given intent color (e.g. red for
      [Error] or green for [Success]). Use [Inherit] to style parents with the intent
      color of their children. *)
  type t =
    | Primary
    | Foreground of Skyline_theme_v1.Color.t
    | Background of Skyline_theme_v1.Color.t
    | Secondary
    | Inherit
  [@@deriving sexp_of]
end

module Path : sig
  (** The path of a given element. Paths are forward-slash separated strings. *)
  type t = string Nonempty_list.t [@@deriving sexp_of, compare]

  include Comparable.S with type t := t
  include Stringable.S with type t := t

  module Segment : sig
    (** A handle to a path segment that can be rendered into the tree view. *)
    type t

    (** Return the path elements that form this segment. *)
    val path_elements : t -> string Nonempty_list.t

    (** Render this segment e.g. into the tree view.

        If you are rendering additional content like icons on the right of the path
        segment, you should pass [~should_handle_indentation:false]. Don't worry if you're
        unsure about passing this argument -- if it's required it will be very obvious
        when visually inspecting your UI. *)
    val component : ?should_handle_indentation:bool -> t -> Vdom.Node.t
  end
end

(** A tree view that renders a map of items keyed by [/] separated paths.

    {3 Options to configure the tree views behaviour}

    - The default [layout] renders the items arranged as a tree, which children indented
      under their parents. There is also an alternative list layout.

    - If [search] is provided, items in the tree are filtered by their path and only items
      matching the provided search term are rendered.

    - By default, items are sorted based on their path. Custom [compare] and
      [compare_path] arguments can be used to override the sort behaviour. Branches with
      items are sorted according to [compare], and if a branch does not have an associated
      item (or if [compare] is not provided) the branch is sorted according to
      [compare_path].

    By default, [compare_path] is [Path.compare].

    - [on_click] and [on_contextmenu] handlers can also be provided to trigger actions
      when the tree items are interacted with by the user. If no [on_click] action is
      provided, or [on_click] resolves to [None], the default action collapses child
      elements in the tree when a parent is clicked.

    {3 Options to configure the tree view visually}

    - [merge_empty_paths] controls if the tree view combines consecutive parents which
      only have one child into a single row.

    - If [highlight] is provided, the item at the given path will be highlighted in the
      rendered tree.

    - [segment] and [item] can be used to change the apperance of row contents are
      rendered. The default simply renders the path segment for the given row in the tree
      using [Path.Segment.component].

    [item] is used to render rows in the tree that correspond to a given element in the
    map.

    [segment] is used to render rows in the tree that don't have a corresponding map
    element i.e. rows that only exist to structure the tree. *)
val component
  :  ?collapsed:Path.Set.t Bonsai.t * (Path.t -> unit Effect.t) Bonsai.t
  -> ?layout:Layout.t Bonsai.t
  -> ?merge_empty_paths:bool
  -> ?compare_path:(Path.t -> Path.t -> int)
  -> ?compare:('a -> 'a -> int)
  -> ?filter:string Bonsai.t
  -> ?on_click:(Path.t -> 'a option -> unit Effect.t option) Bonsai.t
  -> ?on_contextmenu:
       (Path.t -> 'a option -> unit Skyline_context_menu_v1.t Effect.t) Bonsai.t
  -> ?highlight:Path.t Bonsai.t
  -> ?decoration:(Path.t -> 'a option -> Decoration.t)
  -> ?alternating_row_background:bool
  -> ?disable_keyboard_navigation:bool
  -> ?segment:
       (Path.t Bonsai.t
        -> Path.Segment.t Bonsai.t
        -> Bonsai.graph @ local
        -> Vdom.Node.t Bonsai.t)
  -> ?item:
       (Path.t Bonsai.t
        -> Path.Segment.t Bonsai.t
        -> 'a Bonsai.t
        -> Bonsai.graph @ local
        -> Vdom.Node.t Bonsai.t)
  -> 'a Path.Map.t Bonsai.t
  -> Bonsai.graph @ local
  -> Vdom.Node.t Bonsai.t
