open! Gen_js_api

let highlight' ~regexp href_of_match =
  let regexp = Codemirror.RegExp.create regexp (Some "ig") in
  let decorate ~add ~from ~to_ matches _ =
    match matches with
    | Some matched_text :: _ ->
      let decoration =
        Codemirror.View.Decoration.mark
          (Codemirror.View.Decoration.Mark_spec.create
             ~attributes:
               (Ojs.obj
                  [| "href", Ojs.string_to_js (href_of_match matched_text)
                   ; "target", Ojs.string_to_js "_blank"
                   ; "style", Ojs.string_to_js "text-decoration:underline; color:#3794FF;"
                  |])
             ~tag_name:"a"
             ())
      in
      add ~from ~to_ decoration
    | _ -> ()
  in
  let decorator =
    let decoration =
      Codemirror.View.Decoration.mark
        (Codemirror.View.Decoration.Mark_spec.create ~tag_name:"a" ())
    in
    Codemirror.View.Match_decorator.create
      (Codemirror.View.Match_decorator.Config.create ~regexp ~decoration ~decorate ())
  in
  Codemirror.State.Facet.compute
    Codemirror.View.Editor_view.decorations'
    ~deps:[ Doc ]
    ~get:(fun _ ->
      Js_of_ocaml.Js.wrap_callback (fun view ->
        Codemirror.View.Match_decorator.create_deco decorator view))
;;

let urls_regexp =
  {|https?:\/\/[a-z0-9:\-.]+(.?\/[^/>\s]*[^/>\s\.\),\]])*((?<=https.*\(+.*)\)+)?\/?|[a-z\-]+(\.[a-z\-]+)*\.(com|org)(\/[^/>?\s]+)*(\?[^?\s]+)?\b|[a-z\-]+\/(\?[^\s]+)?(?=\s|$)|}
;;

let features_regexp = {|\bfe-\d+\b|(?<=^|[ [(\{])jane(/[a-zA-Z0-9_][a-zA-Z0-9._\-]*)+\b|}
let regexp = [%string {|%{urls_regexp}|%{features_regexp}|}]

let is_digit = function
  | '0' .. '9' -> true
  | _ -> false
;;

let looks_like_a_date text =
  (* Check for [YYYY-MM-DD] format. *)
  String.length text == 10
  && is_digit text.[0]
  && is_digit text.[1]
  && is_digit text.[2]
  && is_digit text.[3]
  && Char.equal text.[4] '-'
  && is_digit text.[5]
  && is_digit text.[6]
  && Char.equal text.[7] '-'
  && is_digit text.[8]
  && is_digit text.[9]
;;

let looks_like_a_time text =
  (* Check for [HH-MM-SS.<digits>Z] format. *)
  let len = String.length text in
  len >= 10
  && is_digit text.[0]
  && is_digit text.[1]
  && Char.equal text.[2] '-'
  && is_digit text.[3]
  && is_digit text.[4]
  && Char.equal text.[5] '-'
  && is_digit text.[6]
  && is_digit text.[7]
  && Char.equal text.[8] '.'
  &&
  let rec all_digits i = i >= len - 1 || (is_digit text.[i] && all_digits (i + 1)) in
  all_digits 9 && Char.equal text.[len - 1] 'Z'
;;

let href_of_match link =
  if String.starts_with link ~prefix:"http" then link else "https://" ^ link
;;

let highlight = lazy (highlight' ~regexp href_of_match)

module For_testing = struct
  let regexp = regexp
  let href_of_match = href_of_match
end
