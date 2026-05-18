open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

let view
  ?test_selector
  ?confirm_test_selector
  ?cancel_test_selector
  ?(confirm_label = "Confirm")
  ?(confirm_intent = `Primary)
  ?(cancel_label = "Cancel")
  ?(cancel_intent = `Secondary)
  content
  ~title
  ~close
  ~confirm
  =
  [%html.jsx
    {|
      <Skyline_dialog_v2.view
        ?test_selector
        %{Private_skyline_utility_classes.data_skyline_component "confirm-dialog"}
      >
        <Skyline_dialog_v2.Section.title>
          #{title}
        </>
        <Skyline_dialog_v2.Section.content>
          %{content}
        </>
        <Skyline_dialog_v2.Section.footer style="flex-direction: row-reverse">
          <Skyline_button_v2.view
            ?test_selector:%{confirm_test_selector}
            ~intent:%{confirm_intent}
            ~on_click:%{confirm}
            autofocus=%{true}
            style="flex-grow: 0"
          >
            #{confirm_label}
          </>
          <Skyline_button_v2.view
            ?test_selector:%{cancel_test_selector}
            ~intent:%{cancel_intent}
            ~on_click:%{close}
            style="flex-grow: 0"
          >
            #{cancel_label}
          </>
        </>
      </>
    |}]
;;

let effect (graph @ local) =
  let effect_in =
    Skyline_modal_v2.effect
      ~close_on_esc:(Bonsai.return true)
      (fun in_ ~close ~resolve (_graph @ local) ->
        let%arr ( ~test_selector
                , ~confirm_test_selector
                , ~cancel_test_selector
                , ~confirm_label
                , ~confirm_intent
                , ~cancel_label
                , ~cancel_intent
                , content
                , ~title )
          =
          in_
        and resolve
        and close in
        view
          ?test_selector
          ?confirm_test_selector
          ?cancel_test_selector
          ?confirm_label
          ?confirm_intent
          ?cancel_label
          ?cancel_intent
          content
          ~title
          ~confirm:(resolve ())
          ~close)
      graph
  in
  let%arr effect_in in
  fun ?test_selector
    ?confirm_test_selector
    ?cancel_test_selector
    ?confirm_label
    ?confirm_intent
    ?cancel_label
    ?cancel_intent
    content
    ~title ->
    let%map.Effect opt =
      effect_in
        ( ~test_selector
        , ~confirm_test_selector
        , ~cancel_test_selector
        , ~confirm_label
        , ~confirm_intent
        , ~cancel_label
        , ~cancel_intent
        , content
        , ~title )
    in
    Option.is_some opt
;;

module For_screenshot_testing = struct
  let view = view
end

module Deprecated = struct
  module Actions = struct
    let view
      ?(action_attr = Vdom.Attr.empty)
      ?(action_label = "Ok")
      ?(close_label = "Close")
      ?close_selector
      ?confirm_selector
      ~close
      availability_like
      =
      let on_click =
        match availability_like with
        | `Available effect -> effect
        | _ -> Effect.Ignore
      in
      let disabled =
        match availability_like with
        | `Available _ -> false
        | _ -> true
      in
      let tooltip =
        match availability_like with
        | `Unavailable (Some reason) | `Unauthorized reason -> Some reason
        | _ -> None
      in
      [%html.jsx
        {|
          <Skyline_dialog_v2.Content.fragment>
            <Skyline_dialog_v2.Section.separator />
            <Skyline_dialog_v2.Section.footer style="flex-direction: row-reverse">
              <Skyline_button_v2.view
                ?test_selector:%{confirm_selector}
                ~intent:%{`Primary}
                ~on_click:%{on_click}
                ~disabled
                ?tooltip:%{tooltip}
                autofocus=%{true}
                %{action_attr}
              >
                #{action_label}
              </>
              <Skyline_button_v2.view
                ?test_selector:%{close_selector}
                ~intent:%{`Secondary}
                ~on_click:%{close}
              >
                #{close_label}
              </>
            </>
          </>
        |}]
    ;;
  end
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
