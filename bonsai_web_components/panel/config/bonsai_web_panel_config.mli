(** A panel's layout, used by a panel's parent to place the child.

    It can be an accordion or raw. Raw has no title and is always expanded (but can be
    hidden). *)
open! Core

module Stable : sig
  module Size : sig
    module V1 : sig
      type t =
        | Px of int
        | Percent of Percent.t
      [@@deriving sexp, compare, equal, bin_io, stable_witness]
    end

    module Latest = V1
  end

  module Panel_id : sig
    module V1 : sig
      type t [@@deriving sexp, compare, equal, bin_io, stable_witness, hash, string]
    end

    module Latest = V1
  end

  module Child_layout : sig
    module Layout_type : sig
      module Accordion : sig
        module V1 : sig
          type t = { title : string }
          [@@deriving sexp, compare, equal, bin_io, stable_witness]
        end

        module Latest = V1
      end

      module V1 : sig
        type t =
          | Accordion of Accordion.V1.t
          | Raw
        [@@deriving sexp, compare, equal, bin_io, stable_witness]
      end

      module Latest = V1
    end

    module V1 : sig
      type t =
        { size : Size.V1.t
        ; layout_type : Layout_type.V1.t
        ; min_size : Size.V1.t
        ; hidden : bool
        ; expanded : bool
        }
      [@@deriving sexp, compare, equal, bin_io, stable_witness, fields ~getters]
    end

    module Latest = V1
  end

  module Tabbed : sig
    module V1 : sig
      type 'a t =
        { tabs : ('a * string) Nonempty_list.Stable.V3.t
        ; current_tab : int
        }
      [@@deriving sexp, compare, equal, bin_io, fields ~getters, stable_witness]
    end

    module Latest = V1
  end

  module V1 : sig
    type 'a t =
      | Content of 'a
      | Vertical_variable of ('a t * Child_layout.V1.t) list
      | Vertical_fixed of ('a t * Child_layout.V1.t) list
      | Horizontal_fixed of ('a t * Child_layout.V1.t) list
      | Tabbed of 'a t Tabbed.V1.t
    [@@deriving sexp, compare, equal, bin_io, sexp_grammar, stable_witness]

    val map : 'a t -> f:('a -> 'b) -> 'b t
  end

  module V2 : sig
    type 'a t =
      { panel_id : Panel_id.V1.t
      ; config : 'a config
      }

    and 'a config =
      | Content of 'a
      | Vertical_variable of ('a t * Child_layout.V1.t) list
      | Vertical_fixed of ('a t * Child_layout.V1.t) list
      | Horizontal_fixed of ('a t * Child_layout.V1.t) list
      | Tabbed of 'a t Tabbed.V1.t
    [@@deriving sexp, compare, equal, bin_io, sexp_grammar, stable_witness]

    (** Convert V1 config to V2, generating new panel IDs *)
    val of_V1 : ?random_state:Random.State.t -> 'a V1.t -> 'a t

    (** Custom t_of_sexp that handles V1 to V2 conversion with deterministic UUID
        generation *)
    val t_of_sexp_with_state
      :  ?random_state:Random.State.t
      -> (Sexp.t -> 'a)
      -> Sexp.t
      -> 'a t

    val map : 'a t -> f:('a -> 'b) -> 'b t

    (** Convert V2 config to V1, discarding panel IDs *)
    val to_V1 : 'a t -> 'a V1.t
  end

  module Latest = V2
end

module Size : sig
  type t = Stable.Size.Latest.t =
    | Px of int
    | Percent of Percent.t
  [@@deriving sexp, compare, equal]

  val percent_of_float : float -> t

  (* parent_size is in the native js unit of pixels *)
  val to_pixels : parent_size:int -> t -> int
  val to_percent : parent_size:int -> t -> Percent.t
  val to_percent_size : parent_size:int -> t -> t
  val to_px_size : parent_size:int -> t -> t
  val sub : parent_size:int -> t -> t -> t
  val add : parent_size:int -> t -> t -> t
  val mul : parent_size:int -> t -> t -> t
  val div : parent_size:int -> t -> t -> t
  val div_to_percent : parent_size:int -> t -> t -> t
end

module Panel_id : sig
  type t = Stable.Panel_id.Latest.t [@@deriving sexp, compare, equal, bin_io, hash]

  include Comparator.S with type t := t
  include Stringable.S with type t := t

  (** Generate a new unique panel ID using a UUID *)
  val generate_id : ?random_state:Random.State.t -> unit -> t
end

module Child_layout : sig
  module Layout_type : sig
    module Accordion : sig
      type t = Stable.Child_layout.Layout_type.Accordion.Latest.t = { title : string }
      [@@deriving sexp, compare, equal]
    end

    type t = Stable.Child_layout.Layout_type.Latest.t =
      | Accordion of Accordion.t
      | Raw
    [@@deriving sexp, compare, equal]
  end

  type t = Stable.Child_layout.Latest.t =
    { size : Size.t
    ; layout_type : Layout_type.t
    ; min_size : Size.t
    ; hidden : bool
    ; expanded : bool
    }
  [@@deriving sexp, compare, equal, bin_io, fields ~getters]

  (** Create a child layout.
      @param expanded If true, the child is expanded by default.
      @param hidden
        If true, the child is hidden meaning it won't be rendered at all in the UI - no
        title, no content.
      @param title
        The title of the child. If [None], then the child is Raw and not collapsible.
      @param min_size The minimum size of the child in pixels or as a percent
      @param size
        The initial size of the child. A percentage of total size for fixed size parents
        or a pixel value for variable size parents whose total size grows as the child is
        resized. *)
  val create
    :  ?expanded:bool
    -> ?hidden:bool
    -> ?title:string
    -> min_size:Size.t
    -> Size.t
    -> t

  val expanded : t -> bool
  val title : t -> string option
  val current_size : t -> Size.t
  val set_size : size:Size.t -> t -> t
  val set_expanded : expanded:bool -> t -> t
  val toggle : t -> t
end

module Tabbed : sig
  type 'a t = 'a Stable.Tabbed.Latest.t =
    { tabs : ('a * string) Nonempty_list.t
    ; current_tab : int
    }
  [@@deriving sexp, compare, equal, bin_io, fields ~getters]
end

type 'a t = 'a Stable.Latest.t = private
  { panel_id : Panel_id.t
  ; config : 'a config
  }
[@@deriving sexp, compare, equal, bin_io, sexp_grammar, fields ~getters]

and 'a config = 'a Stable.Latest.config = private
  | Content of 'a
  | Vertical_variable of ('a t * Child_layout.t) list
  | Vertical_fixed of ('a t * Child_layout.t) list
  | Horizontal_fixed of ('a t * Child_layout.t) list
  | Tabbed of 'a t Tabbed.t
[@@deriving sexp, compare, equal, bin_io, sexp_grammar]

(** Create a horizontal panel stack

    @param panel_id
      Optional explicit panel ID. If not provided, a random ID will be generated. *)
val create_stack_horizontal : ?panel_id:Panel_id.t -> ('a t * Child_layout.t) list -> 'a t

(** Create a vertical panel stack whose height scales with the children.

    @param panel_id
      Optional explicit panel ID. If not provided, a random ID will be generated. *)
val create_stack_vertical : ?panel_id:Panel_id.t -> ('a t * Child_layout.t) list -> 'a t

(** Create a vertical panel stack whose height is fixed - the other children will resize
    when one is changed.

    @param panel_id
      Optional explicit panel ID. If not provided, a random ID will be generated. *)
val create_stack_vertical_fixed
  :  ?panel_id:Panel_id.t
  -> ('a t * Child_layout.t) list
  -> 'a t

(** Create a tabbed panel stack

    @param panel_id
      Optional explicit panel ID. If not provided, a random ID will be generated. *)
val create_stack_tabbed
  :  ?panel_id:Panel_id.t
  -> ?initial_active_tab:int
  -> ('a t * string) Nonempty_list.t
  -> 'a t

val create_content : ?panel_id:Panel_id.t -> 'a -> 'a t
val child_float_layouts : 'a t -> Child_layout.t list option
val panel_id : 'a t -> Panel_id.t
val child_configs : 'a t -> 'a t list option
val set_child_layout_configs : 'a t -> ('a t * Child_layout.t) list -> 'a t
val set_child_configs : 'a t -> 'a t list -> 'a t
val set_child_layouts : 'a t -> Child_layout.t list -> 'a t
val set_tab_titles : 'a t -> string Nonempty_list.t -> 'a t
val create_children : 'a t list -> Child_layout.t list -> ('a t * Child_layout.t) list
val map : 'a t -> f:('a -> 'b) -> 'b t
val fold : 'a t -> init:'accum -> f:('accum -> 'a -> 'accum) -> 'accum
