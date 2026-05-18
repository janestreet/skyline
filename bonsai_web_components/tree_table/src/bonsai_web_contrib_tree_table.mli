open! Core

module Make_nonempty_list_comparator (T : Comparator.S) : sig
  type t = T.t Nonempty_list.t [@@deriving sexp_of]

  val comparator
    : ( T.t Nonempty_list.t
        , T.comparator_witness Nonempty_list.comparator_witness )
        Comparator.t

  type comparator_witness = T.comparator_witness Nonempty_list.comparator_witness
end

module Row : sig
  type 'a compare := 'a -> 'a -> int

  (** After treeification, this row type knows more about its ancestors, which is useful
      for rendering and sorting. You can always retreive the key and data for the original
      row with the [key] and [data] functions. *)
  type ('key, 'data) t [@@deriving sexp_of]

  (** Builds a comparison function for tree-style-table rows out of a comparison function
      for individual rows. *)
  val lift_comparison : ('key * 'data) compare -> ('key * ('key, 'data) t) compare

  (** Fetch the original key *)
  val key : ('key, _) t -> 'key

  (** Fetch the original data *)
  val data : (_, 'data) t -> 'data

  (** Return the parents that this row has. The list is ordered as
      [parent; grandparent; ...]. *)
  val ancestors : ('key, 'data) t -> ('key * 'data) list

  (** Returns the number of parents that this row has. Useful for indenting the children
      of rows by a set amount. *)
  val ancestor_count : _ t -> int

  (** Pass this to the Bonsai partial-render-table's [override_sort] optional parameter *)
  val sort_override
    :  'key compare
    -> ('key * ('key, 'data) t) compare
    -> ('key * ('key, 'data) t) compare

  (** Maps over the data inside the row and all of its stored ancestors *)
  val map_data : ('key, 'a) t -> f:('a -> 'b) -> ('key, 'b) t

  (** Changes the data inside of the row for the same type. Does not affect the ancestors.

      WARNING: Only use this function if your mapping has no impact on row ordering.
      Previous row-ordering data will be used after this mapping. *)
  val map_data_skipping_ancestors_not_impacting_sorting
    :  ('key, 'data) t
    -> f:('data -> 'data)
    -> ('key, 'data) t
end

module Tree : sig
  (** A [branch] refers to a node at a single path through the tree, and has some data
      associated with it. *)
  type ('k, 'v, 'cmp) branch

  (** Accessor for the data attached to the branch *)
  val data : (_, 'v, _) branch -> 'v

  (** Tree.t is an intermediate representation of the tree. Though this module does
      technically support building an empty tree, adding elements to the tree and removing
      on that tree, I actually suspect that most people will build their trees with the
      [map_to_tree] function.

      A tree with an optional [data] type parameter indicates that the tree might have
      holes: nodes with no associated data. *)

  type ('k, 'v, 'cmp) t

  (** Create an empty tree *)
  val empty : ('k, 'cmp) Comparator.Module.t -> ('k, 'v, 'cmp) t

  (** Set a value via a path through the tree. Because this [set] might introduce
      intermediate paths that don't have data associated with them, the type parameter for
      the data is restricted to [option]s *)
  val set
    :  ('k, 'v option, 'cmp) t
    -> key:'k Nonempty_list.t
    -> data:'v
    -> ('k, 'v option, 'cmp) t

  (** Removes a value from the tree. Removing a value from the middle of a tree would
      leave a hole at that branch, so the type parameter for the data is restricted to
      [option]s *)
  val remove : ('k, 'v option, 'cmp) t -> 'k Nonempty_list.t -> ('k, 'v option, 'cmp) t
end

type ('k, 'v, 'cmp) branches := ('k, ('k, 'v, 'cmp) Tree.branch, 'cmp) Map.t

(** Converts a map whose key type is a a nonempty-list of path elements to a Tree.t. *)
val map_to_tree
  :  ?instrumentation:Incr_map.Instrumentation.t
  -> ('path_elt, 'cmp) Comparator.Module.t
  -> (('path_elt Nonempty_list.t, 'data, _) Map.t, 'w) Incremental.t
  -> (('path_elt, 'data option, 'cmp) Tree.t, 'w) Incremental.t

module How_to_map : sig
  type ('path_elt, 'cmp, 'a, 'b, 'w) t

  (** Apply the given function to each element in the tree. The downside of
      non-incrementality is that the function will run for all ancestors every time a
      child element is updated. In contrast, `incrementally` will re-run the function for
      ancestors, well, incrementally. *)
  val nonincrementally
    :  (key:'path_elt Nonempty_list.t
        -> data:'a
        -> children:('path_elt, 'b, 'cmp) branches
        -> 'b)
    -> ('path_elt, 'cmp, 'a, 'b, _) t

  (** Run the given incremental function on each element in the tree. However if the tree
      being processed can deeply nested, this can quickly exhaust the maximum incremental
      computation depth.

      Note: For the default max depth this happens after ~ 8 levels of nesting. *)
  val incrementally
    :  ?comparator:('path_elt, 'cmp) Comparator.Module.t
    -> (key:'path_elt Nonempty_list.t
        -> data:('a, 'w) Incremental.t
        -> children:(('path_elt, 'b, 'cmp) branches, 'w) Incremental.t
        -> ('b, 'w) Incremental.t)
    -> ('path_elt, 'cmp, 'a, 'b, 'w) t

  (** Provide an incremental and a non-incremental function to process tree elements. This
      allows you to incrementally update parents where possible without running a risk of
      exhausting the allowed incremental depth.

      Note that you need to ensure that [nonincremental] and [incremental] behave the
      same, otherwise you will get unexpected results. *)
  val incrementally_with_nonincremental_fallback
    :  ?switch_from_incremental_to_nonincremental_at_this_depth:int
    -> ?comparator:('path_elt, 'cmp) Comparator.Module.t
    -> nonincremental:
         (key:'path_elt Nonempty_list.t
          -> data:'a
          -> children:('path_elt, 'b, 'cmp) branches
          -> 'b)
    -> incremental:
         (key:'path_elt Nonempty_list.t
          -> data:('a, 'w) Incremental.t
          -> children:(('path_elt, 'b, 'cmp) branches, 'w) Incremental.t
          -> ('b, 'w) Incremental.t)
    -> unit
    -> ('path_elt, 'cmp, 'a, 'b, 'w) t
end

(** Transforms a tree parameterized with one type of [data] into another.

    If you aren't a fan of the [option] in the data type parameter, this function will
    allow you to come up with default values for those holes, so frequently, [map] will
    just turn a tree of ['a option] into a tree of ['a].

    The mapping function on a node has access to that nodes children, allowing it to
    compute aggregations on its children. *)
val map
  :  ?instrumentation:
       (depth:int -> step:[ `mapi' | `nonincremental ] -> Incr_map.Instrumentation.t)
  -> (('path_elt, 'a, 'cmp) Tree.t, 'w) Incremental.t
  -> how_to_map:('path_elt, 'cmp, 'a, 'b, 'w) How_to_map.t
  -> (('path_elt, 'b, 'cmp) Tree.t, 'w) Incremental.t

(** If your map still has options in them, you can pass
    [Remove_and_also_remove_descendants] to [tree_to_map] in order to get rid of them (and
    any child of those nodes). *)
type (_, _) how_to_deal_with_nones =
  | Preserve : ('a, 'a) how_to_deal_with_nones
  | Remove_and_also_remove_descendants : ('a option, 'a) how_to_deal_with_nones

(** Converts a [Tree.t] back to a map, but this time, it's a map whose data is a [Row.t],
    which carries enough information with it to properly sort rows in the map with respect
    to the values influenced by their parent. *)
val tree_to_map
  :  ?instrumentation:
       (depth:int
        -> step:[ `mapi' | `filter_mapi' | `collapse_by | `nonincremental ]
        -> Incr_map.Instrumentation.t)
  -> ?max_incremental_recursion_depth:int
  -> how_to_deal_with_nones:('i, 'o) how_to_deal_with_nones
  -> (('k, 'i, 'cmp) Tree.t, 'w) Incremental.t
  -> ( ( 'k Nonempty_list.t
         , ('k Nonempty_list.t, 'o) Row.t
         , 'cmp Nonempty_list.comparator_witness )
         Map.t
       , 'w )
       Incremental.t
