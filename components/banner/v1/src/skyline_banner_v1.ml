open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Style = struct
  let ( @> ) = Css_gen.( @> )

  let banner intent =
    Css_gen.box_sizing `Border_box
    @> Css_gen.flex_container
         ~direction:`Row
         ~align_items:`Center
         ~justify_content:`Space_between
         ()
    @> Css_gen.row_gap (`Px 12)
    @> Css_gen.column_gap (`Px 12)
    @> Css_gen.width (`Percent Percent.one_hundred_percent)
    @> Css_gen.uniform_padding (`Px 4)
    @> Css_gen.uniform_margin (`Px 0)
    @> Css_gen.border_radius (`Px 4)
    @> Css_gen.border ~style:`Solid ~color:intent ~width:(`Px 1) ()
    @> Css_gen.color intent
    @> Css_gen.background_color `Inherit
    |> Vdom.Attr.style
  ;;

  let banner_with_dropdown intent =
    [%css
      {|
        cursor: pointer;
        &:hover {
          color: %{Skyline_theme_v1.background#Css_gen.Color} !important;
          background-color: %{intent#Css_gen.Color} !important;
        }
      |}]
  ;;

  let card_title =
    Css_gen.box_sizing `Border_box
    @> Css_gen.uniform_padding (`Px 4)
    @> Css_gen.uniform_margin (`Px 0)
    @> Css_gen.min_height (`Px 20)
    @> Css_gen.user_select `None
    @> Css_gen.text_align `Left
    |> Vdom.Attr.style
  ;;

  let full_width_card =
    Css_gen.box_sizing `Border_box
    @> Css_gen.uniform_padding (`Px 0)
    @> Css_gen.uniform_margin (`Px 0)
    @> Css_gen.width (`Percent Percent.one_hundred_percent)
    |> Vdom.Attr.style
  ;;

  let progress_spinner =
    Css_gen.box_sizing `Border_box
    @> Css_gen.uniform_padding (`Px 0)
    @> Css_gen.margin ~top:(`Px (-2)) ~right:(`Px (-2)) ~bottom:(`Px (-2)) ()
    |> Vdom.Attr.style
  ;;

  let content =
    Css_gen.box_sizing `Border_box
    @> Css_gen.width (`Percent Percent.one_hundred_percent)
    @> Css_gen.flex_item ~grow:1.0 ()
    @> Css_gen.padding ~left:(`Px 4) ~right:(`Px 4) ~bottom:(`Px 4) ()
    @> Css_gen.uniform_margin (`Px 0)
    |> Vdom.Attr.style
  ;;
end

let component' ~intent ~icon message =
  Vdom.Node.div
    ~attrs:[ Style.banner intent ]
    [ Skyline_flex_v1.row
        ~gap:(`Px 4)
        ~align:Center
        [ Codicons.svg icon; Skyline_text_v1.span' message ]
    ]
;;

let component ~intent ~icon message = component' ~intent ~icon [ Vdom.Node.text message ]

let with_actions ~dropdown ~intent ~icon message (local_ graph) =
  let has_menu =
    let%arr dropdown in
    not (List.is_empty dropdown)
  in
  let context_menu =
    match%sub dropdown with
    | [] -> return Vdom.Attr.empty
    | _ :: _ -> Skyline_context_menu_v1.component ~on_click:(return true) dropdown graph
  in
  let%arr has_menu and context_menu and intent and icon and message in
  let message =
    Skyline_flex_v1.row
      ~gap:(`Px 4)
      ~align:Center
      [ Codicons.svg icon; Skyline_text_v1.span message ]
  in
  Vdom.Node.button
    ~attrs:
      [ Style.banner intent
      ; context_menu
      ; (if has_menu then Style.banner_with_dropdown intent else Vdom.Attr.empty)
      ]
    [ message; (if has_menu then Codicons.svg Chevron_down else Vdom.Node.none) ]
;;

let collapsible
  ?state:external_state
  ?intent
  ?(actions = Bonsai.return [])
  ?(loading = Bonsai.return false)
  ~title
  content
  graph
  =
  let state, set_state =
    match external_state with
    | Some state -> state
    | None -> Bonsai.state `Expanded graph
  in
  let%arr intent = Bonsai.transpose_opt intent
  and title
  and actions
  and loading
  and state
  and set_state
  and content in
  let label_and_actions =
    let actions =
      let toggle_minimized =
        let on_click =
          match state with
          | `Expanded -> set_state `Collapsed
          | `Collapsed -> set_state `Expanded
        in
        let title =
          match state with
          | `Expanded -> "hide"
          | `Collapsed -> "show"
        in
        Skyline_button_v1.link ~size:Small ~on_click title
      in
      match state with
      | `Collapsed -> toggle_minimized
      | `Expanded ->
        let actions =
          match actions with
          | [] -> []
          | _ :: _ ->
            let actions =
              List.map actions ~f:(fun (title, on_click) ->
                Skyline_button_v1.link ~size:Small ~on_click title)
            in
            Skyline_divider_v1.interpunct :: actions
        in
        Skyline_flex_v1.row ~align:Center ~gap:(`Px 4) (toggle_minimized :: actions)
    in
    let loading =
      match state with
      | `Collapsed when loading ->
        Skyline_flex_v1.row
          ~attrs:[ Style.progress_spinner ]
          [ Skyline_loading_indicator_v1.spinner () ]
      | _ -> Vdom.Node.none
    in
    Skyline_flex_v1.row
      ~align:Center
      ~gap:(`Px 8)
      ~attrs:[ Style.card_title ]
      [ Skyline_text_v1.span ~size:Small title; actions; loading ]
  in
  Skyline_card_v1.column
    ?intent
    ~attrs:
      [ Vdom.Attr.style (Css_gen.color Skyline_theme_v1.primary)
      ; (match state with
         | `Expanded -> Style.full_width_card
         | `Collapsed -> Vdom.Attr.empty)
      ]
    ~align:Stretch
    ~justify:Space_between
    ~padding:(`Px 0)
    (match state with
     | `Expanded ->
       [ (if loading then Skyline_loading_indicator_v1.runner () else Vdom.Node.none)
       ; label_and_actions
       ; Skyline_flex_v1.column
           ~attrs:[ Style.content ]
           ~align:Stretch
           ~justify:Flex_start
           [ content ]
       ]
     | `Collapsed -> [ label_and_actions ])
;;
