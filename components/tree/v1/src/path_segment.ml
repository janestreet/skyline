open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  include
    [%css
    stylesheet
      {|
        .segment {
          box-sizing: border-box;
          display: block;
          vertical-align: top;
          line-height: 18px;
          color: var(--foreground);
          background-color: var(--background);
          border-radius: 4px;
          white-space: var(--whitespace);
        }

        .segment:hover {
          text-decoration: underline;
          text-decoration-color: var(--underline);
        }

        .segment.limit-width {
          max-width: 120px;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        .leaf-segment-indent {
          margin-left: 20px;
        }
      |}]

  let segment ~layout ~contracted ~underline ~faded ~foreground ~background =
    let foreground =
      if faded
      then Skyline_theme_v1.fade foreground (Percent.of_percentage 70.)
      else foreground
    in
    let underline =
      if underline then Css_gen.Color.to_string_css Skyline_theme_v1.border else "unset"
    in
    let whitespace =
      match layout with
      | Layout.Tree -> "normal"
      | Layout.List -> "nowrap"
    in
    Vdom.Attr.many
      [ Variables.set
          ~foreground:(Css_gen.Color.to_string_css foreground)
          ~background:(Css_gen.Color.to_string_css background)
          ~underline
          ~whitespace
          ()
      ; segment
      ; (if contracted then limit_width else Vdom.Attr.empty)
      ]
  ;;

  let squishy_text =
    Css_gen.(
      flex_item ~shrink:10. ~grow:1. ()
      @> overflow `Hidden
      @> create ~field:"text-overflow" ~value:"ellipsis"
      @> white_space `Nowrap)
    |> Vdom.Attr.style
  ;;
end

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

let highlight_matching_sections_in_substring ~matching_indices ~pos substring =
  Skyline_fuzzy_match_v1.matching_sections_in_substring ~matching_indices ~pos ~substring
  |> List.map ~f:(function
    | `Matching, part ->
      Skyline_text_v1.span ~intent:Skyline_theme_v1.accent ~style:Bold part
    | `Not_matching, part -> Skyline_text_v1.span part)
;;

let single_path_segment
  ~layout
  ~matching_indices
  ~parent_path_length
  ~contracted
  ~intent
  ~faded
  segment
  =
  let foreground, background =
    match intent with
    | `Primary (`Foreground intent) | `Secondary (Some intent) ->
      intent, `Name "transparent"
    | `Primary (`Background intent) -> Skyline_theme_v1.background, intent
    | `Primary `None | `Secondary None -> Skyline_theme_v1.primary, `Name "transparent"
  in
  let highlighted_name =
    match matching_indices with
    | Some matching_indices ->
      (* This is subtly broken for items that have multiple children, since the common
         parent may not match (and so get [None] when we compute) matching indices for a
         given row. (It's subtle enough that we decided to ignore the issue for now
         though.) *)
      highlight_matching_sections_in_substring
        ~matching_indices
        ~pos:parent_path_length
        segment
    | None -> [ Skyline_text_v1.span segment ]
  in
  Vdom.Node.span
    ~attrs:
      [ Style.segment ~layout ~contracted ~underline:true ~faded ~foreground ~background
      ; Vdom.Attr.title segment
      ]
    highlighted_name
;;

let tree_path_segments
  { layout; parent_path_length; matching_indices; intent; segments; indent_tree_leaf }
  =
  let rec loop ~parent_path_length (segments : string Nonempty_list.t) =
    match segments with
    | [ primary_segment ] ->
      let faded =
        match intent with
        | `Primary _ -> false
        | `Secondary _ -> true
      in
      [ single_path_segment
          ~matching_indices
          ~parent_path_length
          ~contracted:false
          ~intent
          ~faded
          ~layout
          primary_segment
      ]
    | merged_segment :: hd :: tl ->
      let merged_segment =
        single_path_segment
          ~matching_indices
          ~parent_path_length:(parent_path_length + 1 + String.length merged_segment)
          ~contracted:true
          ~intent
          ~faded:true
          ~layout
          merged_segment
      in
      merged_segment :: Skyline_divider_v1.slash :: loop ~parent_path_length (hd :: tl)
  in
  Skyline_flex_v1.row
    ~wrap:Wrap
    ~align:Center
    ~justify:Flex_start
    ~attrs:(if indent_tree_leaf then [ Style.leaf_segment_indent ] else [])
    (loop segments ~parent_path_length)
;;

let list_path_segments
  { layout
  ; parent_path_length = _
  ; matching_indices
  ; intent
  ; segments
  ; indent_tree_leaf = _
  }
  =
  let item_name = Nonempty_list.last segments in
  let item_prefix =
    let rec loop (segments : string Nonempty_list.t) =
      match segments with
      | [ _ ] -> []
      | item :: hd :: tl -> item :: loop (hd :: tl)
    in
    String.concat ~sep:"/" (loop segments)
  in
  let fade_full_path =
    match intent with
    | `Primary _ -> false
    | `Secondary _ -> true
  in
  Skyline_flex_v1.row
    ~gap:(`Px 4)
    ~align:Baseline
    ~justify:Flex_start
    ~attrs:[ Vdom.Attr.style (Css_gen.max_width (`Percent (Percent.of_percentage 80.))) ]
    [ single_path_segment
        ~matching_indices
        ~parent_path_length:(String.length item_prefix)
        ~contracted:false
        ~intent
        ~faded:fade_full_path
        ~layout
        item_name
    ; Skyline_text_v1.span
        ~secondary:true
        ~size:Small
        ~attrs:[ Style.squishy_text; Vdom.Attr.title item_prefix ]
        item_prefix
    ]
;;

let component segment =
  match segment.layout with
  | Tree -> tree_path_segments segment
  | List -> list_path_segments segment
;;
