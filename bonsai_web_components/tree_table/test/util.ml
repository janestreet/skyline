open! Core
module Incr = Incremental.Make ()

module Nonempty_string_list = struct
  type t = string Nonempty_list.t [@@deriving quickcheck, sexp, compare, hash]

  include functor Comparable.Make
end

type t =
  { path : Nonempty_string_list.t
  ; review : int
  }
[@@deriving quickcheck, sexp, compare]

let nonincremental feature_map =
  let has_all_ancestors key =
    let key = Nonempty_list.to_list key in
    List.length key
    |> List.init ~f:(fun i ->
      List.drop (List.rev key) (i + 1) |> List.rev |> Nonempty_list.of_list)
    |> List.filter_opt
    |> List.for_all ~f:(fun ancestor -> Map.mem feature_map ancestor)
  in
  let compare =
    Comparable.lexicographic
      [ Comparable.lift [%compare: Nonempty_string_list.t] ~f:(fun { path; _ } -> path)
      ; Comparable.lift [%compare: int] ~f:(fun { review; _ } -> review)
      ]
  in
  feature_map
  |> Map.filteri ~f:(fun ~key ~data:_ -> has_all_ancestors key)
  |> Map.data
  |> List.sort ~compare
;;

let of_list features =
  features
  |> List.sort_and_group
       ~compare:
         (Comparable.lift Nonempty_string_list.compare ~f:(fun { path; _ } -> path))
  |> List.map ~f:(function
    | [] -> failwith "empty groups are impossible"
    | x :: _ -> x.path, x)
  |> Map.of_alist_exn (module Nonempty_string_list)
;;
