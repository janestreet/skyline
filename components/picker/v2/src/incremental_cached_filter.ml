open! Core
open! Private_skyline_prelude

module Scored = struct
  type 'a t =
    { value : 'a
    ; score : int
    }
  [@@deriving fields ~getters, sexp_of]

  let compare_scores = [%eta2 Comparable.lift ~f:score Int.compare]
  let default value = { value; score = 1 }
end

let score_and_sort ~to_search_string ~(items : _ Scored.t iarray) ~query =
  let fuzzy_query = Fuzzy_search.Query.create query in
  let scored : _ Scored.t Queue.t = Queue.create () in
  for i = 0 to Iarray.length items - 1 do
    let prev = Iarray.unsafe_get items i in
    let item_string = to_search_string prev.value in
    let score = Fuzzy_search.score fuzzy_query ~item:item_string in
    if score <> 0 then Queue.enqueue scored { prev with score }
  done;
  let scored = Queue.to_array scored in
  Array.sort scored ~compare:Scored.compare_scores;
  Iarray.unsafe_of_array__promise_no_mutation scored
;;

module Model = struct
  type 'elt t = { prev_scored : 'elt Scored.t iarray } [@@unboxed] [@@deriving sexp_of]

  let default = { prev_scored = Iarray.empty }
end

module Input = struct
  type 'collection t =
    { items : 'collection
    ; query : string
    }
  [@@deriving sexp_of]

  let equal { items; query } (t2 : _ t) =
    phys_equal items t2.items && String.equal query t2.query
  ;;
end

let trim_query query =
  Bonsai.cutoff
    ~equal:String.equal
    (let%arr query in
     String.strip query)
;;

let component
  (type collection elt)
  ~items
  ~query_for_suggestions
  ~to_search_string
  ~(to_iarray : 'out. collection -> f:(elt -> 'out) @ local -> 'out iarray)
  (graph @ local)
  =
  let query = trim_query query_for_suggestions in
  let model, set_model =
    Bonsai.state ~sexp_of_model:[%sexp_of: _ Model.t] Model.default graph
  in
  let input =
    let%arr query and items in
    ({ query; items } : collection Input.t)
  in
  let prev_input =
    Bonsai.previous_value
      ~sexp_of_model:[%sexp_of: _ Input.t]
      ~equal:Input.equal
      input
      graph
  in
  let default_items =
    let%arr items in
    lazy (to_iarray items ~f:Scored.default)
  in
  Bonsai.Edge.Poll.effect_on_change
    ~sexp_of_input:[%sexp_of: _ Input.t]
    ~equal_input:Input.equal
    (Bonsai.Edge.Poll.Starting.initial Iarray.empty)
    input
    ~effect:
      (let%arr model and set_model and prev_input and default_items in
       fun ({ query; items } : _ Input.t) ->
         let scored =
           if String.is_empty query
           then force default_items
           else
             score_and_sort
               ~to_search_string
               ~query
               ~items:
                 (match prev_input with
                  | Some prev
                    when phys_equal items prev.items
                         && String.is_prefix query ~prefix:prev.query -> model.prev_scored
                  | _ -> force default_items)
         in
         let%map.Effect () = set_model { prev_scored = scored } in
         Iarray.map ~f:Scored.value scored)
    graph
;;
