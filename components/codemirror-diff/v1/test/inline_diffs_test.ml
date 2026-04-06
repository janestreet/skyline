open! Core

let%expect_test "Basic diff" =
  let original = "Hello world!" in
  let doc = "Hello World!" in
  Harness.changes ~original doc;
  [%expect
    {|
    <div style="tab-size: 4;"
         spellcheck="false"
         autocorrect="off"
         autocapitalize="off"
         translate="no"
         contenteditable="true"
         class="cm-content"
         role="textbox"
         aria-multiline="true">
      <div>
        <div class="cm-line cm-diff-deleted-content-bg">
          Hello_
          <span class="cm-diff-deleted-refinement"> world </span>
          !
        </div>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        Hello_
        <span class="cm-diff-added-refinement"> World </span>
        !
      </div>
    </div>
    |}]
;;

let%expect_test "Basic diff with elided context" =
  let context = "Line one\nLine two\nLine three\nLine four\nLine five\nLine six" in
  let original =
    [%string "%{context}\nHello world!\n%{context}\nSome more diff\n%{context}"]
  in
  let doc =
    [%string "%{context}\nHello Jane Street!\n%{context}\nSome more changes\n%{context}"]
  in
  Harness.changes ~context:2 ~original doc;
  [%expect
    {|
    <div style="tab-size: 4;"
         spellcheck="false"
         autocorrect="off"
         autocapitalize="off"
         translate="no"
         contenteditable="true"
         class="cm-content"
         role="textbox"
         aria-multiline="true">
      <div> </div>
      <div class="cm-line"> Line_five </div>
      <div class="cm-line"> Line_six </div>
      <div>
        <div class="cm-line cm-diff-deleted-content-bg">
          Hello_
          <span class="cm-diff-deleted-refinement"> world </span>
          !
        </div>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        Hello_
        <span class="cm-diff-added-refinement"> Jane_Street </span>
        !
      </div>
      <div class="cm-line"> Line_one </div>
      <div class="cm-line"> Line_two </div>
      <div class="cm-diff-hidden cm-line"> </div>
      <div class="cm-line"> Line_five </div>
      <div class="cm-line"> Line_six </div>
      <div>
        <div class="cm-line cm-diff-deleted-content-bg">
          Some_more_
          <span class="cm-diff-deleted-refinement"> diff </span>
        </div>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        Some_more_
        <span class="cm-diff-added-refinement"> changes </span>
      </div>
      <div class="cm-line"> Line_one </div>
      <div class="cm-line"> Line_two </div>
      <div> </div>
    </div>
    |}]
;;

let%expect_test "Changes in a record type" =
  let before =
    {|module Foo = struct
  type t =
    { limit : int
    ; time_window : Time_ns.Span.t
    }
  [@@deriving sexp_of]
end
|}
  in
  let after =
    {|module Foo = struct
  type t =
    { limit : (int[@quickcheck.generator Int.gen_incl 1 1000])
    ; time_window :
        (Time_ns.Span.t
         [@quickcheck.generator
           Time_ns.Span.gen_incl (Time_ns.Span.of_int_ms 1) (Time_ns.Span.of_int_ms 1000)])
    }
  [@@deriving sexp_of, quickcheck]
end|}
  in
  Harness.changes ~original:before after;
  [%expect
    {|
    <div style="tab-size: 4;"
         spellcheck="false"
         autocorrect="off"
         autocapitalize="off"
         translate="no"
         contenteditable="true"
         class="cm-content"
         role="textbox"
         aria-multiline="true">
      <div class="cm-line"> module_Foo_=_struct </div>
      <div class="cm-line"> __type_t_= </div>
      <div>
        <div class="cm-line cm-diff-deleted-content-bg"> ____{_limit_:_int </div>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        ____{_limit_:_
        <span class="cm-diff-added-refinement"> ( </span>
        int
        <span class="cm-diff-added-refinement"> [@quickcheck.generator_Int.gen_incl_1_1000]) </span>
      </div>
      <div>
        <div class="cm-line cm-diff-deleted-content-bg"> ____;_time_window_:_Time_ns.Span.t </div>
      </div>
      <div class="cm-diff-added-line-bg cm-line"> ____;_time_window_: </div>
      <div class="cm-diff-added-line-bg cm-line">
        ________
        <span class="cm-diff-added-refinement"> ( </span>
        Time_ns.Span.t
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        _________
        <span class="cm-diff-added-refinement"> [@quickcheck.generator </span>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        ___________
        <span class="cm-diff-added-refinement">
          Time_ns.Span.gen_incl_(Time_ns.Span.of_int_ms_1)_(Time_ns.Span.of_int_ms_1000)])
        </span>
      </div>
      <div class="cm-line"> ____} </div>
      <div>
        <div class="cm-line cm-diff-deleted-content-bg"> __[@@deriving_sexp_of] </div>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        __[@@deriving_sexp_of
        <span class="cm-diff-added-refinement"> ,_quickcheck </span>
        ]
      </div>
      <div class="cm-line"> end </div>
    </div>
    |}]
;;

let%expect_test "Mix of more complex adds and removes" =
  let before =
    {ocaml|let prompt_if_large_build t (targets : Target.t list) dirs =
      match Customization.value warn_on_large_build_goal with
      | false -> return ()
      | true ->
        (match
           List.exists all_dirs_and_targets ~f:(function
             (* Large_goal_detection only appears to care about aliases, and it's not
                clear what to pass in for [basename] in the other cases. *)
             | dir, Alias target ->
               let root_dir =
                 Build_id.jenga_root_absolute t |> File_path.Absolute.to_string
               in
               Jenga_public.Large_goal_detection.is_large_alias
                 ~dir
                 ~basename:target
                 ~root_dir
             | _, _ -> false)
         with
         | false -> return ()
|ocaml}
  in
  let after =
    {ocaml|let prompt_if_large_build t (targets : Build_target_inference.Targets.t list) dirs =
      match Customization.value warn_on_large_build_goal with
      | false -> return ()
      | true ->
        (match
           (* Large_goal_detection only appears to care about aliases, and it's not
              clear what to pass in for [basename] in the other cases. *)
           List.exists all_dirs_and_targets ~f:(fun (dir, dependency) ->
             match Build_target_inference.Targets.to_alias dependency with
             | None -> false
             | Some alias_name ->
               let root_dir =
                 Build_id.jenga_root_absolute t |> File_path.Absolute.to_string
               in
               Jenga_public.Large_goal_detection.is_large_alias
                 ~dir
                 ~basename:alias_name
                 ~root_dir)
         with
         | false -> return ()
|ocaml}
  in
  Harness.changes ~original:before after;
  [%expect
    {|
    <div style="tab-size: 4;"
         spellcheck="false"
         autocorrect="off"
         autocapitalize="off"
         translate="no"
         contenteditable="true"
         class="cm-content"
         role="textbox"
         aria-multiline="true">
      <div>
        <div class="cm-line cm-diff-deleted-content-bg">
          let_prompt_if_large_build_t_(targets_:_
          <span class="cm-diff-deleted-refinement"> Target </span>
          .t_list)_dirs_=
        </div>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        let_prompt_if_large_build_t_(targets_:_
        <span class="cm-diff-added-refinement"> Build_target_inference.Targets </span>
        .t_list)_dirs_=
      </div>
      <div class="cm-line"> ______match_Customization.value_warn_on_large_build_goal_with </div>
      <div class="cm-line"> ______|_false_->_return_() </div>
      <div class="cm-line"> ______|_true_-> </div>
      <div class="cm-line"> ________(match </div>
      <div class="cm-line cm-diff-deleted-content-fg"> ___________List.exists_all_dirs_and_targets_~f:(function </div>
      <div class="cm-line">
        ___________(*_Large_goal_detection_only_appears_to_care_about_aliases,_and_it's_not
      </div>
      <div class="cm-line"> ______________clear_what_to_pass_in_for_[basename]_in_the_other_cases._*) </div>
      <div>
        <div class="cm-line cm-diff-deleted-content-bg">
          _____________
          <span class="cm-diff-deleted-refinement"> |_dir,_Alias_target </span>
          _->
        </div>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        ___________
        <span class="cm-diff-added-refinement"> List.exists_all_dirs_and_targets_~f:(fun_(dir,_dependency)_-> </span>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        _____________
        <span class="cm-diff-added-refinement"> match_Build_target_inference.Targets.to_alias_dependency_with </span>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        _____________
        <span class="cm-diff-added-refinement"> |_None_->_false </span>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        _____________
        <span class="cm-diff-added-refinement"> |_Some_alias_name </span>
        _->
      </div>
      <div class="cm-line"> _______________let_root_dir_= </div>
      <div class="cm-line">
        _________________Build_id.jenga_root_absolute_t_|>_File_path.Absolute.to_string
      </div>
      <div class="cm-line"> _______________in </div>
      <div class="cm-line"> _______________Jenga_public.Large_goal_detection.is_large_alias </div>
      <div class="cm-line"> _________________~dir </div>
      <div>
        <div class="cm-line cm-diff-deleted-content-bg">
          _________________~basename:
          <span class="cm-diff-deleted-refinement"> target </span>
        </div>
      </div>
      <div class="cm-diff-added-line-bg cm-line">
        _________________~basename:
        <span class="cm-diff-added-refinement"> alias_name </span>
      </div>
      <div>
        <div class="cm-line cm-diff-deleted-content-bg"> _________________~root_dir </div>
        <div class="cm-line cm-diff-deleted-content-bg">
          _____________
          <span class="cm-diff-deleted-refinement"> |__,___->_false </span>
          )
        </div>
      </div>
      <div class="cm-diff-added-line-bg cm-line"> _________________~root_dir) </div>
      <div class="cm-line"> _________with </div>
      <div class="cm-line"> _________|_false_->_return_() </div>
      <div class="cm-diff-added-line-fg cm-line">
        <br/>
      </div>
    </div>
    |}]
;;

let%expect_test "Deleted lines at the start and end of the document." =
  let before = "line one\nline two\nline three\nline four\nline five" in
  let after = "line two\nline three" in
  Harness.changes ~original:before after;
  [%expect
    {|
    <div style="tab-size: 4;"
         spellcheck="false"
         autocorrect="off"
         autocapitalize="off"
         translate="no"
         contenteditable="true"
         class="cm-content"
         role="textbox"
         aria-multiline="true">
      <div class="cm-line cm-diff-deleted-content-fg"> line_one </div>
      <div class="cm-line"> line_two </div>
      <div class="cm-line"> line_three </div>
      <div class="cm-line cm-diff-deleted-content-fg"> line_four↵line_five </div>
      <div class="cm-line">
        <br/>
      </div>
    </div>
    |}]
;;
