open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

let view
  ?test_selector
  ?button_test_selector
  ?(button_label = "Ok")
  ?(button_intent = `Secondary)
  content
  ~title
  ~close
  =
  [%html.jsx
    {|
      <Skyline_dialog_v2.view
        ?test_selector
        %{Private_skyline_utility_classes.data_skyline_component "alert-dialog"}
      >
        <Skyline_dialog_v2.Section.title>
          #{title}
        </>
        <Skyline_dialog_v2.Section.content>
          %{content}
        </>
        <Skyline_dialog_v2.Section.footer style="flex-direction: row-reverse">
          <Skyline_button_v2.view
            ?test_selector:%{button_test_selector}
            ~intent:%{button_intent}
            ~on_click:%{close}
            autofocus=%{true}
          >
            #{button_label}
          </>
        </>
      </>
    |}]
;;

let effect (graph @ local) =
  let effect_in =
    Skyline_modal_v2.effect
      ~close_on_esc:(Bonsai.return true)
      (fun in_ ~close ~resolve:_ (_graph @ local) ->
        let%arr ( ~test_selector
                , ~button_test_selector
                , ~button_label
                , ~button_intent
                , content
                , ~title )
          =
          in_
        and close in
        view
          ?test_selector
          ?button_test_selector
          ?button_label
          ?button_intent
          content
          ~title
          ~close)
      graph
  in
  let%arr effect_in in
  fun ?test_selector ?button_test_selector ?button_label ?button_intent content ~title ->
    effect_in
      ( ~test_selector
      , ~button_test_selector
      , ~button_label
      , ~button_intent
      , content
      , ~title )
    |> Effect.ignore_m
;;

module For_screenshot_testing = struct
  let view = view
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
