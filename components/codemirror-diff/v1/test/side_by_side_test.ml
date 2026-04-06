open! Core

let%expect_test "Basic diff" =
  let lhs = "Hello world!" in
  let rhs = "Hello World!" in
  Harness.side_by_side ~context:None ~lhs ~rhs;
  [%expect
    {|
    Left Hand Side
    =======================
    <div style="tab-size: 4;"
         spellcheck="false"
         autocorrect="off"
         autocapitalize="off"
         translate="no"
         contenteditable="true"
         class="cm-content"
         role="textbox"
         aria-multiline="true">
      <div class="cm-diff-deleted-line-bg cm-line">
        Hello_
        <span class="cm-diff-deleted-refinement"> world </span>
        !
      </div>
    </div>
    =======================
    Right Hand Side
    =======================
    <div style="tab-size: 4;"
         spellcheck="false"
         autocorrect="off"
         autocapitalize="off"
         translate="no"
         contenteditable="true"
         class="cm-content"
         role="textbox"
         aria-multiline="true">
      <div class="cm-diff-added-line-bg cm-line">
        Hello_
        <span class="cm-diff-added-refinement"> World </span>
        !
      </div>
    </div>
    |}]
;;

let%expect_test "Side by side with hidden ranges and adjustments for multi line" =
  let context = "Line one\nLine two\nLine three\nLine four\nLine five\nLine six" in
  let lhs =
    [%string "%{context}\nHello world!\n%{context}\nSome more diff\n%{context}"]
  in
  let rhs =
    [%string
      "%{context}\n\
       Hello Jane Street!\n\
       %{context}\n\
       Some more\n\
       multi-line changes\n\
       %{context}"]
  in
  Harness.side_by_side ~context:(Some 1) ~lhs ~rhs;
  [%expect
    {|
    Left Hand Side
    =======================
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
      <div class="cm-line"> Line_six </div>
      <div class="cm-diff-deleted-line-bg cm-line">
        Hello_
        <span class="cm-diff-deleted-refinement"> world </span>
        !
      </div>
      <div class="cm-line"> Line_one </div>
      <div class="cm-diff-hidden cm-line"> </div>
      <div class="cm-line"> Line_six </div>
      <div class="cm-diff-deleted-line-bg cm-line">
        Some_more_
        <span class="cm-diff-deleted-refinement"> diff </span>
      </div>
      <div style="height: inherit;" class="cm-diff-hidden cm-line"> ↵ </div>
      <div class="cm-line"> Line_one </div>
      <div> </div>
    </div>
    =======================
    Right Hand Side
    =======================
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
      <div class="cm-line"> Line_six </div>
      <div class="cm-diff-added-line-bg cm-line">
        Hello_
        <span class="cm-diff-added-refinement"> Jane_Street </span>
        !
      </div>
      <div class="cm-line"> Line_one </div>
      <div class="cm-diff-hidden cm-line"> </div>
      <div class="cm-line"> Line_six </div>
      <div class="cm-diff-added-line-bg cm-line"> Some_more </div>
      <div class="cm-diff-added-line-bg cm-line">
        <span class="cm-diff-added-refinement"> multi-line_changes </span>
      </div>
      <div class="cm-line"> Line_one </div>
      <div> </div>
    </div>
    |}]
;;
