open! Core
open! Bonsai_web

(** An individual radio button control for selecting between mutually exclusive values. *)

module Controller : sig
  (** A [Controller.t] manages the shared state of the radio inputs. *)
  type 'a t

  module Item : sig
    (** An [Item.t] represents one radio input in a controller's group. *)
    type 'a t

    (** [value] returns the value this item represents. *)
    val value : 'a t -> 'a
  end

  (** [component] creates a [Controller] for managing state.
      - [~state] - the currently selected item and a setter
      - [~equal] - the equality method used for detecting the selected *)
  val make
    :  state:'a Bonsai.t * ('a -> unit Effect.t) Bonsai.t
    -> equal:('a -> 'a -> bool)
    -> Bonsai.graph @ local
    -> 'a t Bonsai.t

  (** [item] produces an [Item.t] for a single option. *)
  val item : 'a t -> value:'a -> 'a Item.t
end

(** [content] creates a `Content.t` that can inherit sizing / intent from
    [Skyline_field_v2.content].

    Parameters:
    - [item] - input item state provided by a [Controller]. *)
val content
  :  ?test_selector:Test_selector.t
  -> ?attrs:Vdom.Attr.t list
  -> item:'a Controller.Item.t
  -> unit
  -> Skyline_field_v2.Content.t

module For_testing : sig
  val item
    :  value:'a
    -> group:string
    -> state:bool * unit Effect.t
    -> 'a Controller.Item.t
end

module For_docs : sig
  val ml_filepath : string
end
