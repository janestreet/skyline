open! Core
open! Private_skyline_prelude

type t = ([ `Matching | `Not_matching ] * string) list

let of_string ~needle item =
  let fuzzy_highlight = Fuzzy_search.Query.create (String.strip needle) in
  match Fuzzy_search.split_by_matching_sections fuzzy_highlight ~item with
  | None -> [ `Not_matching, item ]
  | Some splits -> splits
;;

let view ?attrs (t : t) =
  List.map t ~f:(function
    | `Matching, s -> Vdom.Node.strong [ Vdom.Node.text s ]
    | `Not_matching, s -> Vdom.Node.text s)
  |> Vdom.Node.span ?attrs
;;
