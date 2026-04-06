open! Core

(** A general purpose combinator to get the last value of two 'a Bonsai.t

    Note that this does not provide an override - both Bonsai.t must be passed in *)
val last_value
  :  equal:('a -> 'a -> bool)
  -> 'a Bonsai.t
  -> 'a Bonsai.t
  -> local_ Bonsai.graph
  -> 'a Bonsai.t

(** A general purpose combinator for overriding a Bonsai.t with a [setter]. The returned
    Value is equal to the last value passed to [set] OR the last value assigned to
    [default_model], whichever occurred more recently.

    (Note the difference to [Bonsai_extra.value_with_override], which always returns the
    override, if set, even if the default has changed since.) *)
val last_value_update_or_override
  :  equal:('a -> 'a -> bool)
  -> default_model:'a Bonsai.t
  -> local_ Bonsai.graph
  -> ('a * ('a -> unit Bonsai.Effect.t)) Bonsai.t
