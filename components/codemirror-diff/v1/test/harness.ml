open! Core

let print_dom = Jsdom.Expert_for_custom_test_handles.Dom_serialization.print_dom

let codemirror ~extensions doc =
  let state =
    Codemirror.State.Editor_state.create
      (Codemirror.State.Editor_state_config.create ~extensions ~doc ())
  in
  let view =
    Codemirror.View.Editor_view.create (Codemirror.View.Config.create ~state ())
  in
  let content = Codemirror.View.Editor_view.content_dom view in
  print_dom ~with_visible_whitespace:true ~node:content ()
;;

let changes ?context ~original doc =
  codemirror
    ~extensions:[ Skyline_codemirror_diff_v1.changes ~keep_ws:false ~context ~original ]
    doc
;;

let side_by_side ~context ~lhs ~rhs =
  print_endline "Left Hand Side\n=======================";
  codemirror
    ~extensions:
      [ Skyline_codemirror_diff_v1.side_by_side
          ~keep_ws:false
          ~context
          ~other_side:rhs
          `Left
      ]
    lhs;
  print_endline "=======================\nRight Hand Side\n=======================";
  codemirror
    ~extensions:
      [ Skyline_codemirror_diff_v1.side_by_side
          ~keep_ws:false
          ~context
          ~other_side:lhs
          `Right
      ]
    rhs
;;
