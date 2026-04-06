open! Core
open! Bonsai_web

type t =
  { layout : Layout.t
  ; parent_path_length : int
  ; matching_indices : int array option
  ; intent :
      [ `Primary of
        [ `Background of Css_gen.Color.t | `Foreground of Css_gen.Color.t | `None ]
      | `Secondary of Css_gen.Color.t option
      ]
  ; segments : string Nonempty_list.t
  ; indent_tree_leaf : bool
  }

val component : t -> Vdom.Node.t
