open! Core
open! Private_skyline_prelude

module Style =
  [%css
  stylesheet
    {|
      .chevron {
        display: inline;
      }

      .details[open] > .summary > .chevron {
        transform: rotate(90deg);
      }

      /* If this accordion is closed and followed by any accordion, collapse the bottom. */
      .container:not(:has(details[open])):has(+ .container) {
        border-bottom-left-radius: 0;
        border-bottom-right-radius: 0;
        border-bottom: none;
      }

      /* If this accordion is preceded by a closed accordion, collapse the top. */
      .container:not(:has(details[open])) + .container {
        border-top-left-radius: 0;
        border-top-right-radius: 0;
      }

      /* If this accordion is preceded by an open accordion, add 4px gap. */
      .container:has(details[open]) + .container {
        margin-top: %{Classes.spacing 1.#Css_gen.Length};
      }
    |}]

module Header = struct
  type t = attr:Attr.t -> size:Skyline_size.t -> Node.t

  let style =
    {%css|list-style-type: none;|}
    :: Classes.[ flex; flex_row; items_center; gap 2.; py 1.; px 2.; cursor_pointer ]
  ;;

  let content ?test_selector ?(attrs = []) children ~attr:attr_from_container ~size:_ =
    let attrs =
      Attr.many
        [ Test_selector.attr_of_opt test_selector
        ; Attr.many style
        ; attr_from_container
        ; Attr.many attrs
        ]
    in
    {%html|
      <summary %{Style.summary} %{attrs}>
        <Bonsai_web_icon.view
          %{Style.chevron}
          ~size:%{Font.size_base}
          ~icon:%{Lucide.chevron_right}
          ~color:%{Colors.Text.secondary}
        />
        *{children}
      </summary>
    |}
  ;;

  let text
    ?test_selector
    ?contents_test_selector
    ?attrs
    ?contents_attrs
    contents
    ~attr
    ~size
    =
    content
      ?test_selector
      ?attrs
      ~attr
      ~size
      [ Skyline_text_v2.view
          ~size:(size :> Skyline_text_v2.Size.t)
          ?test_selector:contents_test_selector
          ?attrs:contents_attrs
          contents
      ]
  ;;
end

module Section = struct
  type t = size:Skyline_size.t -> Node.t

  let style ~full_bleed =
    Classes.[ (if full_bleed then Attr.empty else p 1.); border_t 1; border_default ]
  ;;

  let content ?test_selector ?(full_bleed = false) ?(attrs = []) children ~size:_ =
    let attrs =
      [ Test_selector.attr_of_opt test_selector
      ; Attr.many (style ~full_bleed)
      ; Attr.many attrs
      ]
    in
    Node.div ~attrs children
  ;;

  let text ?test_selector ?full_bleed ?attrs contents ~size =
    Skyline_text_v2.view
      ~size:(size :> Skyline_text_v2.Size.t)
      ~layout:`Contents
      [ content ?test_selector ?full_bleed ?attrs contents ~size ]
  ;;
end

module Group_name = struct
  (* <details> elements with the same name will be grouped, regardless of where they are
     in the dom. We use a [Uuid] rather than a [string] to prevent users from accidentally
     grouping two disparate accordions together. *)
  type t = Uuid.t [@@deriving string]

  let create () = Uuid.create_random Random.State.default

  let attr t =
    let prefix = [%loc.module_name] in
    Attr.name [%string "%{prefix}-%{to_string t}"]
  ;;
end

module Container = struct
  let style = Classes.[ text_default; bg_one; border 1; border_default; rounded_sm ]

  let view ?test_selector ?(attrs = []) children =
    {%html|
      <div
        %{Test_selector.attr_of_opt test_selector}
        %{Style.container}
        *{style}
        *{attrs}
      >
        *{children}
      </div>
    |}
  ;;
end

let view
  ?test_selector
  ?attrs
  ?(default_open = false)
  ?(on_toggle = fun ~open_:_ -> Effect.Ignore)
  ?group
  ?(size = `Md)
  ~(header : Header.t)
  (children : Section.t list)
  =
  let open_attr =
    match default_open with
    | true -> Attr.open_
    | false -> Attr.empty
  in
  let name_attr =
    match group with
    | Some group -> Group_name.attr group
    | None -> Attr.empty
  in
  let on_toggle =
    Attr.on_toggle (fun evt ->
      let open Js_of_ocaml in
      match
        evt |> Dom_html.eventTarget |> Dom_html.CoerceTo.details |> Js.Opt.to_option
      with
      | None -> Effect.Ignore
      | Some element -> on_toggle ~open_:(Js.to_bool element##.open_))
  in
  {%html|
    <Container.view ?test_selector ?attrs>
      <details %{open_attr} %{Style.details} %{name_attr} %{on_toggle}>
        %{header ~attr:Attr.empty ~size} *{List.map children ~f:(fun section -> section ~size)}
      </details>
    </>
  |}
;;

module Controlled = struct
  let view
    ?test_selector
    ?(size = `Md)
    ?attrs
    ~(header : Header.t)
    (children : Section.t list)
    ~state:(open_state, set_open_state)
    =
    let open_attr =
      match open_state with
      | true -> Attr.open_
      | false -> Attr.empty
    in
    (* We need to intercept clicks on the summary element before they trigger the
       browser's default toggle behavior. *)
    let header_attr =
      let a11y =
        (* For screenreader/vimium support mark the controlled version as a button. *)
        Attr.many
          [ Attr.role "button"; Attr.create "aria-expanded" (Bool.to_string open_state) ]
      in
      let on_summary_click =
        Attr.on_click (fun _ ->
          Effect.Many
            [ (Effect.Prevent_default [@alert "-deprecated"])
            ; set_open_state (not open_state)
            ])
      in
      Attr.many [ on_summary_click; a11y ]
    in
    {%html|
      <Container.view ?test_selector ?attrs>
        <details %{open_attr} %{Style.details}>
          %{header ~attr:header_attr ~size}
          *{List.map children ~f:(fun section -> section ~size)}
        </details>
      </>
    |}
  ;;

  let make_grouped_state ?initial_open ~equal (graph @ local) =
    let open_id, set_open_id = Bonsai.state initial_open graph in
    fun id ->
      let open_state =
        let%arr open_id and id in
        Option.equal equal (Some id) open_id
      in
      let set_state =
        let%arr open_id and set_open_id and id in
        fun state ->
          let current_open_state =
            match open_id with
            | Some current_id when equal id current_id -> `Open
            | None | Some _ -> `Closed
          in
          match state, current_open_state with
          | true, `Open -> Effect.Ignore
          | false, `Open -> set_open_id None
          | true, `Closed -> set_open_id (Some id)
          | false, `Closed -> Effect.Ignore
      in
      open_state, set_state
  ;;
end

module For_docs = struct
  let ml_filepath = __FILE__
end
