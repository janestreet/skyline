open! Core
open! Bonsai_web
open! Bonsai.Let_syntax
open! Jsdom
module Handle = Handle_experimental
module Component_template = Skyline_key_value_pairs_v1

let filter_printed_attributes ~key ~data:_ =
  not String.(key = "tabindex" || key = "style" || key = "class")
;;

let%expect_test "One column" =
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (local_ _graph) ->
      Bonsai.return
      @@ Component_template.view
           ~layout:One_column
           [ {%html|Key1|}, {%html|Value1|}
           ; {%html|Key2|}, {%html|Value2|}
           ; Component_template.key "Key3", {%html|Value3|}
           ; Component_template.key ~icon:Lucide.mail "Key4", {%html|Value4|}
           ])
  in
  Handle.one_frame handle;
  Handle.print_dom handle;
  [%expect
    {|
    <html>
      <head>
        <meta charset="UTF-8"/>
      </head>
      <body>
        <div>
          <div>
            <div> Key1 </div>
            <div> Value1 </div>
          </div>
          <div>
            <div> Key2 </div>
            <div> Value2 </div>
          </div>
          <div>
            <div>
              <div> Key3 </div>
            </div>
            <div> Value3 </div>
          </div>
          <div>
            <div>
              <div>
                <div>
                  <icon-mail size="16px"
                             color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-mail>
                </div>
                Key4
              </div>
            </div>
            <div> Value4 </div>
          </div>
        </div>
      </body>
    </html>
    |}];
  ()
;;

let%expect_test "Two columns" =
  let%with handle =
    Handle.with_ ~get_vdom:Fn.id ~filter_printed_attributes (fun (local_ _graph) ->
      Bonsai.return
      @@ Component_template.view
           ~layout:One_column
           [ {%html|Key1|}, {%html|Value1|}
           ; {%html|Key2|}, {%html|Value2|}
           ; Component_template.key "Key3", {%html|Value3|}
           ; Component_template.key ~icon:Lucide.mail "Key4", {%html|Value4|}
           ])
  in
  Handle.one_frame handle;
  Handle.print_dom handle;
  [%expect
    {|
    <html>
      <head>
        <meta charset="UTF-8"/>
      </head>
      <body>
        <div>
          <div>
            <div> Key1 </div>
            <div> Value1 </div>
          </div>
          <div>
            <div> Key2 </div>
            <div> Value2 </div>
          </div>
          <div>
            <div>
              <div> Key3 </div>
            </div>
            <div> Value3 </div>
          </div>
          <div>
            <div>
              <div>
                <div>
                  <icon-mail size="16px"
                             color="light-dark(oklch(55% 4% 285.94), oklch(71% 4% 286.07))"> </icon-mail>
                </div>
                Key4
              </div>
            </div>
            <div> Value4 </div>
          </div>
        </div>
      </body>
    </html>
    |}];
  ()
;;
