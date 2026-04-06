open! Core
open Virtual_dom

module Style = struct
  include
    [%css
    stylesheet
      ~dont_hash:
        [ "cm-diff-added-line-bg"
        ; "cm-diff-added-line-fg"
        ; "cm-diff-deleted-line-bg"
        ; "cm-diff-deleted-line-fg"
        ; "cm-diff-deleted-content-fg"
        ; "cm-diff-deleted-content-bg"
        ; "cm-diff-hidden"
        ; "cm-diff-added-refinement"
        ; "cm-diff-deleted-refinement"
        ; "--cm-diff-added-user-select-var"
        ; "--cm-diff-deleted-user-select-var"
        ; "cm-activeLine" (* existing Codemirror class *)
        ]
      {|
        /* Note: The [-fg] variants have opacity [50], which visually matches with
           the refinement decorations that overlay opacity [33] onto [22]. */

        .cm-diff-deleted-content-bg {
          background: #ff000022;
          user-select: var(--cm-diff-deleted-user-select-var, none);
        }
        .cm-diff-deleted-content-fg {
          background: #ff000050;
          user-select: var(--cm-diff-deleted-user-select-var, none);
        }

        /* Note that we also want to show the diff decorations when the given line is a
          [cm-activeLine] for fg added lines.

          This is not necessary for bg decorations since for those lines we still keep the
          inline refinements.
        */

        .cm-diff-deleted-line-bg {
          background: #ff000022;
        }
        .cm-diff-deleted-line-fg,
        .cm-activeLine.cm-diff-deleted-line-fg {
          background: #ff000050;
        }

        .cm-diff-added-line-bg {
          background: #00ff0022;
          user-select: var(--cm-diff-added-user-select-var, auto);
        }
        .cm-diff-added-line-fg,
        .cm-activeLine.cm-diff-added-line-fg {
          background: #00ff0050;
          user-select: var(--cm-diff-added-user-select-var, auto);
        }

        .cm-diff-deleted-refinement {
          background: #ff000033;
        }

        .cm-diff-added-refinement {
          background: #00ff0033;
        }

        .cm-diff-hidden {
          height: 24px;
          background-image: linear-gradient(
            -45deg,
            #88888833 12.5%,
            #0000 12.5%,
            #0000 50%,
            #88888833 50%,
            #88888833 62.5%,
            #0000 62.5%,
            #0000 100%
          );
          background-size: 8px 8px;
          user-select: none;
        }
      |}]
end

module Segment = struct
  type replace =
    [ `Prev
    | `Next
    | `Same
    ]

  type t =
    | Same of string array
    | Different of string array * string array
    | Replace of ((replace * string) list array * (replace * string) list array)
end

let start_of_line ~text line =
  (* Return the end of the last line, if we're asking for the start of the line just after
     the current last line. *)
  if Codemirror.Text.Text.lines text + 1 = line
  then Codemirror.Text.Text.line text (line - 1) |> Codemirror.Text.Line.to_
  else Codemirror.Text.Text.line text line |> Codemirror.Text.Line.from
;;

let end_of_line ~text line =
  Codemirror.Text.Text.line text line |> Codemirror.Text.Line.to_
;;

let deleted_inline_content_of_segments ~text segments =
  Array.fold segments ~init:(1, []) ~f:(fun (current_line, accum) segment ->
    match (segment : Segment.t) with
    | Same arr | Different ([||], arr) -> current_line + Array.length arr, accum
    | Different (prev, next) ->
      let content = String.concat_array ~sep:"\n" prev in
      let decoration = start_of_line ~text current_line, `Deleted content in
      current_line + Array.length next, decoration :: accum
    | Replace (prev, next) ->
      let decoration = start_of_line ~text current_line, `Replaced prev in
      current_line + Array.length next, decoration :: accum)
  |> snd
;;

let added_lines_of_segments ~text segments =
  let added_lines ~kind ~accum ~current_line arr =
    let accum =
      Array.foldi arr ~init:accum ~f:(fun idx accum _ ->
        let location = start_of_line ~text (current_line + idx) in
        (kind, location) :: accum)
    in
    current_line + Array.length arr, accum
  in
  Array.fold segments ~init:(1, []) ~f:(fun (current_line, accum) segment ->
    match (segment : Segment.t) with
    | Same arr -> current_line + Array.length arr, accum
    | Different (_, [||]) -> current_line, accum
    | Different (_, arr) -> added_lines ~kind:`fg ~accum ~current_line arr
    | Replace (_, arr) -> added_lines ~kind:`bg ~accum ~current_line arr)
  |> snd
;;

let count_leading_whitespace string =
  Option.value
    (String.lfindi ~f:(fun _ c -> not (Char.is_whitespace c)) string)
    ~default:0
;;

let utf8_length string = string |> String.Utf8.of_string |> String.Utf8.length_in_uchars

let added_refinements_of_segments ~text segments =
  Array.fold segments ~init:(1, []) ~f:(fun (current_line, accum) segment ->
    match (segment : Segment.t) with
    | Same arr -> current_line + Array.length arr, accum
    | Different (_, [||]) -> current_line, accum
    | Different (_, arr) -> current_line + Array.length arr, accum
    | Replace (_, arr) ->
      let accum =
        Array.foldi arr ~init:accum ~f:(fun idx accum line ->
          let line_num = current_line + idx in
          let start_of_line = start_of_line ~text line_num in
          let _, accum =
            List.fold line ~init:(0, accum) ~f:(fun (offset, accum) (kind, part) ->
              match kind with
              | `Same -> offset + String.length part, accum
              | _ ->
                (* Patdiff uses byte offsets, but CodeMirror needs character positions. We
                   convert to avoid issues with multi-byte characters *)
                let line_text =
                  Codemirror.Text.Text.line text line_num |> Codemirror.Text.Line.text
                in
                let char_offset =
                  String.sub
                    ~pos:0
                    ~len:(Int.min offset (String.length line_text))
                    line_text
                  |> utf8_length
                in
                let start = start_of_line + char_offset + count_leading_whitespace part in
                let end_ = start_of_line + char_offset + utf8_length part in
                offset + String.length part, (start, end_) :: accum)
          in
          accum)
      in
      current_line + Array.length arr, accum)
  |> snd
;;

let hidden_ranges_of_segments ~text ~context segments =
  let last_line = Codemirror.Text.Text.lines text in
  let has_trailing_diff =
    if Array.length segments > 0
    then (
      match Array.last_exn segments with
      | Segment.Same _ -> false
      | Different _ | Replace _ -> true)
    else false
  in
  Array.fold segments ~init:(1, []) ~f:(fun (current_line, accum) segment ->
    match (segment : Segment.t) with
    | Same arr ->
      let start_line = current_line in
      let stop_line = current_line + Array.length arr - 1 in
      let accum =
        if start_line = 1 && stop_line - start_line > context
        then (
          let start = start_of_line ~text 1 in
          let stop = end_of_line ~text (stop_line - context) in
          (start, stop) :: accum)
        else if stop_line = last_line
                (* If there is a trailing diff, this is not actually the end. *)
                && (not has_trailing_diff)
                && stop_line - start_line > context
        then (
          let start = start_of_line ~text (start_line + context) in
          let stop = end_of_line ~text last_line in
          (start, stop) :: accum)
        else if stop_line - start_line > 2 * context
        then (
          let start = start_of_line ~text (start_line + context) in
          let stop = end_of_line ~text (stop_line - context) in
          (start, stop) :: accum)
        else accum
      in
      current_line + Array.length arr, accum
    | Different (_, arr) -> current_line + Array.length arr, accum
    | Replace (_, arr) -> current_line + Array.length arr, accum)
  |> snd
;;

let alignment_placeholder_ranges_of_segments ~text segments =
  let delta ~current_line ~accum ~prev ~next =
    let current_line = current_line + Array.length next in
    let delta = Array.length prev - Array.length next in
    let accum =
      if delta > 0
      then (
        let placeholder = start_of_line ~text current_line, delta in
        placeholder :: accum)
      else accum
    in
    current_line, accum
  in
  Array.fold segments ~init:(1, []) ~f:(fun (current_line, accum) segment ->
    match (segment : Segment.t) with
    | Same arr | Different ([||], arr) -> current_line + Array.length arr, accum
    | Replace ([||], arr) -> current_line + Array.length arr, accum
    | Different (prev, next) -> delta ~current_line ~accum ~prev ~next
    | Replace (prev, next) -> delta ~current_line ~accum ~prev ~next)
  |> snd
;;

let patdiff ~keep_ws ~prev ~next =
  let open Patdiff_kernel in
  Patdiff_core.Without_unix.diff
    ~context:(max (Array.length prev) (Array.length next))
    ~keep_ws
    ~find_moves:false
    ~line_big_enough:Configuration.default_line_big_enough
    ~prev
    ~next
  |> Patdiff_core.Without_unix.refine_structured
       ~keep_ws
       ~produce_unified_lines:false
       ~split_long_lines:false
       ~interleave:true
       ~word_big_enough:Configuration.default_word_big_enough
       ~mark_newline_changes:true
;;

let filter_empty_parts arr =
  Array.map arr ~f:(fun x -> List.filter x ~f:(fun (_, s) -> not (String.is_empty s)))
;;

let segment ~keep_ws ~original ~text =
  let prev = String.split_lines original |> List.to_array in
  let next =
    Array.init (Codemirror.Text.Text.lines text) ~f:(fun idx ->
      Codemirror.Text.Text.line text (idx + 1) |> Codemirror.Text.Line.text)
  in
  patdiff ~keep_ws ~prev ~next
  |> List.map ~f:(fun { ranges; _ } ->
    Array.of_list_map ranges ~f:(function
      | Same arr ->
        Segment.Same
          (Array.map arr ~f:(function
            | (_, line) :: _, _ -> line
            | [], _ -> ""))
      | Replace (prev, next, _) ->
        Replace (filter_empty_parts prev, filter_empty_parts next)
      | Prev (prev, _) ->
        let prev = Array.map prev ~f:(fun x -> List.map x ~f:snd |> String.concat) in
        Different (prev, [||])
      | Next (next, _) ->
        let next = Array.map next ~f:(fun x -> List.map x ~f:snd |> String.concat) in
        Different ([||], next)
      | Unified _ -> assert false))
  |> Array.concat
;;

let segment_reverse ~keep_ws ~original ~text =
  let prev =
    Array.init (Codemirror.Text.Text.lines text) ~f:(fun idx ->
      Codemirror.Text.Text.line text (idx + 1) |> Codemirror.Text.Line.text)
  in
  let next = String.split_lines original |> List.to_array in
  patdiff ~keep_ws ~prev ~next
  |> List.map ~f:(fun { ranges; _ } ->
    Array.of_list_map ranges ~f:(function
      | Same arr ->
        Segment.Same
          (Array.map arr ~f:(function
            | (_, line) :: _, _ -> line
            | [], _ -> ""))
      | Replace (prev, next, _) ->
        Replace (filter_empty_parts next, filter_empty_parts prev)
      | Prev (prev, _) ->
        let prev = Array.map prev ~f:(fun x -> List.map x ~f:snd |> String.concat) in
        Different ([||], prev)
      | Next (next, _) ->
        let next = Array.map next ~f:(fun x -> List.map x ~f:snd |> String.concat) in
        Different (next, [||])
      | Unified _ -> assert false))
  |> Array.concat
;;

let create_widget ~to_dom =
  let widget = Codemirror.View.Widget_type.create () in
  Codemirror.View.Widget_type.set_to_dom widget (fun () ->
    to_dom () |> Vdom.Node.to_dom |> (Obj.magic : _ Js_of_ocaml.Js.t -> Gen_js_api.Ojs.t));
  widget
;;

let deleted_inline_decorations ~text segments =
  let decoration ~content ~location =
    let widget =
      create_widget ~to_dom:(fun () ->
        match content with
        | `Deleted content ->
          Vdom.Node.div
            ~attrs:[ Vdom.Attr.class_ "cm-line"; Style.cm_diff_deleted_content_fg ]
            [ Vdom.Node.text content ]
        | `Replaced lines ->
          let lines =
            List.map (Array.to_list lines) ~f:(fun parts ->
              List.concat_map parts ~f:(function
                | `Prev, part ->
                  let leading_whitespace = count_leading_whitespace part in
                  [ Vdom.Node.text (String.prefix part leading_whitespace)
                  ; Vdom.Node.span
                      ~attrs:[ Style.cm_diff_deleted_refinement ]
                      [ Vdom.Node.text (String.drop_prefix part leading_whitespace) ]
                  ]
                | (`Same | `Next), part -> [ Vdom.Node.text part ])
              |> Vdom.Node.div
                   ~attrs:[ Vdom.Attr.class_ "cm-line"; Style.cm_diff_deleted_content_bg ])
          in
          Vdom.Node.div lines)
    in
    Codemirror.View.Decoration.Widget_spec.create ~widget ~block:true ()
    |> Codemirror.View.Decoration.widget
    |> Codemirror.View.Decoration.range ~from:location ~to_:location
  in
  let deleted = deleted_inline_content_of_segments ~text segments in
  List.map deleted ~f:(fun (location, content) -> decoration ~content ~location)
;;

let changed_line_decorations ~bg ~fg ~text segments =
  let background =
    Codemirror.View.Decoration.Line_spec.create ~class_:bg ()
    |> Codemirror.View.Decoration.line
  in
  let foreground =
    Codemirror.View.Decoration.Line_spec.create ~class_:fg ()
    |> Codemirror.View.Decoration.line
  in
  added_lines_of_segments ~text segments
  |> List.map ~f:(function
    | `bg, loc -> Codemirror.View.Decoration.range background ~from:loc ~to_:loc
    | `fg, loc -> Codemirror.View.Decoration.range foreground ~from:loc ~to_:loc)
;;

let refinements ~class_ ~text segments =
  let decoration =
    Codemirror.View.Decoration.Mark_spec.create ~class_ ()
    |> Codemirror.View.Decoration.mark
  in
  added_refinements_of_segments ~text segments
  |> List.map ~f:(fun (from, to_) ->
    Codemirror.View.Decoration.range decoration ~from ~to_)
;;

let hidden_decorations ~text ~context segments =
  let decoration_replace =
    let widget =
      create_widget ~to_dom:(fun () ->
        Vdom.Node.div ~attrs:[ Style.cm_diff_hidden; Vdom.Attr.class_ "cm-line" ] [])
    in
    Codemirror.View.Decoration.Replace_spec.create ~widget ~block:true ()
    |> Codemirror.View.Decoration.replace
  in
  let decoration_hide =
    Codemirror.View.Decoration.Replace_spec.create ~block:true ()
    |> Codemirror.View.Decoration.replace
  in
  let end_of_document = Codemirror.Text.Text.length text in
  hidden_ranges_of_segments ~text ~context segments
  |> List.map ~f:(fun (from, to_) ->
    Codemirror.View.Decoration.range
      (if from = 0 || to_ = end_of_document then decoration_hide else decoration_replace)
      ~from
      ~to_)
;;

let alignment_placeholder_decorations ~text segments =
  let decoration ~location ~lines =
    let lines = String.init lines ~f:(const '\n') in
    let widget =
      create_widget ~to_dom:(fun () ->
        let attrs =
          [ Style.cm_diff_hidden
          ; Vdom.Attr.class_ "cm-line"
          ; Vdom.Attr.style (Css_gen.height `Inherit)
          ]
        in
        Vdom.Node.div ~attrs [ Vdom.Node.text lines ])
    in
    Codemirror.View.Decoration.Widget_spec.create ~widget ~block:true ()
    |> Codemirror.View.Decoration.widget
    |> Codemirror.View.Decoration.range ~from:location ~to_:location
  in
  alignment_placeholder_ranges_of_segments ~text segments
  |> List.map ~f:(fun (location, lines) -> decoration ~location ~lines)
;;

(* A lazy which registers an event listener that toggles which region in an inline diff
   can be selected:
   - If the selection starts on the unchanged / green regions the new document can be
     selected
   - If the selection starts on the red regions, the old document can be selected *)
let register_deleted_selection_listener =
  let open Js_of_ocaml in
  let open Style.For_referencing in
  let on_mouse_down (event : Dom_html.mouseEvent Js.t) =
    let has_class name =
      Js.Opt.case event##.target (const false) (fun target ->
        Js.to_bool (target##.classList##contains (Js.string name)))
    in
    let set name value =
      let (_ : _ Js.t) =
        Dom_html.document##.body##.style##setProperty
          (Js.string name)
          (Js.string value)
          Js.Optdef.empty
      in
      ()
    in
    let clear name =
      let (_ : _ Js.t) =
        Dom_html.document##.body##.style##removeProperty (Js.string name)
      in
      ()
    in
    if has_class cm_diff_deleted_content_bg
       || has_class cm_diff_deleted_content_fg
       || has_class cm_diff_deleted_refinement
    then (
      set cm_diff_added_user_select_var "none";
      set cm_diff_deleted_user_select_var "auto")
    else (
      clear cm_diff_added_user_select_var;
      clear cm_diff_deleted_user_select_var);
    Js._true
  in
  lazy
    (Dom.addEventListener
       Dom_html.document##.body
       Dom_html.Event.mousedown
       (Dom.handler on_mouse_down)
       Js._false
     |> (ignore : Dom.event_listener_id -> unit))
;;

let changes ~keep_ws ~context ~original =
  force register_deleted_selection_listener;
  Codemirror.State.Facet.compute
    Codemirror.View.Editor_view.decorations
    ~deps:[ Doc ]
    ~get:(fun state ->
      let text = Codemirror.State.Editor_state.doc state in
      let segments = segment ~keep_ws ~original ~text in
      let deleted = deleted_inline_decorations ~text segments in
      let added =
        changed_line_decorations
          ~bg:Style.For_referencing.cm_diff_added_line_bg
          ~fg:Style.For_referencing.cm_diff_added_line_fg
          ~text
          segments
      in
      let refinements =
        refinements ~class_:Style.For_referencing.cm_diff_added_refinement ~text segments
      in
      let hidden_context =
        match context with
        | Some context -> hidden_decorations ~text ~context segments
        | None -> []
      in
      List.concat [ deleted; added; refinements; hidden_context ]
      |> Codemirror.View.Decoration.set ~sort:true)
;;

let side_by_side ?report_error ~keep_ws ~context ~other_side left_or_right =
  match left_or_right with
  | `Left ->
    Codemirror.State.Facet.compute
      Codemirror.View.Editor_view.decorations
      ~deps:[ Doc ]
      ~get:(fun state ->
        try
          let text = Codemirror.State.Editor_state.doc state in
          let segments = segment_reverse ~keep_ws ~original:other_side ~text in
          let deleted =
            changed_line_decorations
              ~bg:Style.For_referencing.cm_diff_deleted_line_bg
              ~fg:Style.For_referencing.cm_diff_deleted_line_fg
              ~text
              segments
          in
          let refinements =
            refinements
              ~class_:Style.For_referencing.cm_diff_deleted_refinement
              ~text
              segments
          in
          let hidden_context =
            match context with
            | Some context -> hidden_decorations ~text ~context segments
            | None -> []
          in
          let alignment = alignment_placeholder_decorations ~text segments in
          List.concat [ deleted; refinements; hidden_context; alignment ]
          |> Codemirror.View.Decoration.set ~sort:true
        with
        | exn ->
          (match report_error with
           | Some report_error ->
             Bonsai.Effect.Expert.handle
               (report_error (Or_error.of_exn exn))
               ~on_exn:(fun exn -> Exn.reraise exn "Unhandled exception raised in effect");
             Codemirror.View.Decoration.set ~sort:true []
           | None -> raise exn))
  | `Right ->
    Codemirror.State.Facet.compute
      Codemirror.View.Editor_view.decorations
      ~deps:[ Doc ]
      ~get:(fun state ->
        try
          let text = Codemirror.State.Editor_state.doc state in
          let segments = segment ~keep_ws ~original:other_side ~text in
          let added =
            changed_line_decorations
              ~bg:Style.For_referencing.cm_diff_added_line_bg
              ~fg:Style.For_referencing.cm_diff_added_line_fg
              ~text
              segments
          in
          let refinements =
            refinements
              ~class_:Style.For_referencing.cm_diff_added_refinement
              ~text
              segments
          in
          let hidden_context =
            match context with
            | Some context -> hidden_decorations ~text ~context segments
            | None -> []
          in
          let alignment = alignment_placeholder_decorations ~text segments in
          List.concat [ added; refinements; hidden_context; alignment ]
          |> Codemirror.View.Decoration.set ~sort:true
        with
        | exn ->
          (match report_error with
           | Some report_error ->
             Bonsai.Effect.Expert.handle
               (report_error (Or_error.of_exn exn))
               ~on_exn:(fun exn -> Exn.reraise exn "Unhandled exception raised in effect");
             Codemirror.View.Decoration.set ~sort:true []
           | None -> raise exn))
;;

let all_lines ~class_name =
  let decoration =
    Codemirror.View.Decoration.Line_spec.create ~class_:class_name ()
    |> Codemirror.View.Decoration.line
  in
  let decorate_view view =
    let text =
      Codemirror.View.Editor_view.state view |> Codemirror.State.Editor_state.doc
    in
    let viewport = Codemirror.View.Editor_view.viewport view in
    let start_line =
      Codemirror.Text.Text.line_at
        text
        (Codemirror.View.Editor_view.Viewport.from viewport)
      |> Codemirror.Text.Line.number
    in
    let end_line =
      Codemirror.Text.Text.line_at
        text
        (Codemirror.View.Editor_view.Viewport.to_ viewport)
      |> Codemirror.Text.Line.number
    in
    List.init
      (end_line - start_line + 1)
      ~f:(fun idx ->
        let line = idx + start_line in
        let location = start_of_line ~text line in
        Codemirror.View.Decoration.range decoration ~from:location ~to_:location)
    |> Codemirror.View.Decoration.set ~sort:false
  in
  Codemirror.State.Facet.compute
    Codemirror.View.Editor_view.decorations'
    ~deps:[]
    ~get:(const (Js_of_ocaml.Js.wrap_callback decorate_view))
;;

let all_added = lazy (all_lines ~class_name:Style.For_referencing.cm_diff_added_line_fg)

let all_deleted =
  lazy (all_lines ~class_name:Style.For_referencing.cm_diff_deleted_line_fg)
;;
