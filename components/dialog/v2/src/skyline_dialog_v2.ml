open! Core
open! Private_skyline_prelude

module Style = struct
  let root size =
    Attr.many
      Classes.
        [ flex
        ; flex_col
        ; w_fit
        ; max_w_full
        ; h_full
        ; {%css|
            position: relative;
            overflow: hidden;
          |}
        ; {%css|max-width: 100vw;|}
        ; {%css|max-height: 100vh;|}
        ; shadow_sm
        ; border 1
        ; border_default
        ; text_default
        ; bg_one
        ; (match size with
           | `Xs -> Classes.gap 1.
           | `Sm | `Md | `Lg -> Classes.gap 2.)
        ; (match size with
           | `Xs -> rounded_xs
           | `Sm -> rounded_sm
           | `Md -> rounded_md
           | `Lg -> rounded_lg)
        ]
  ;;

  (* We measure Skyline v2 button dimensions (inner height + paddings) to know how much
     room we need to reserve for it. *)
  let close_hitbox = function
    | `Xs -> 4.5
    | `Sm -> 6.
    | `Md -> 7.
    | `Lg -> 8.
  ;;

  let paddings = function
    | `Xs -> ~pad_x:1., ~pad_y:1.
    | `Sm -> ~pad_x:2., ~pad_y:2.
    | `Md | `Lg -> ~pad_x:3., ~pad_y:2.
  ;;

  let section ~is_first ~is_last ~close_button_present ~scrollable ~full_bleed size =
    Attr.many
      Classes.
        [ flex
        ; gap 1.
        ; (if scrollable
           then
             {%css|
               flex: 1;
               overflow: auto;
             |}
           else
             {%css|
               flex: 0;
               overflow: visible;
             |})
        ; (if full_bleed
           then Attr.empty
           else (
             let ~pad_x, ~pad_y = paddings size in
             Attr.many
               [ (if is_first && close_button_present
                  then (
                    let close_hitbox = close_hitbox size in
                    Attr.many [ pl pad_x; pr ((2. *. pad_x) +. close_hitbox) ])
                  else px pad_x)
               ; (if is_first then pt pad_y else Attr.empty)
               ; (if is_last then pb pad_y else Attr.empty)
               ]))
        ]
  ;;

  let separator = {%css|border-top: 1px solid %{Colors.Border.default#Css_gen.Color};|}

  let close_button size =
    Attr.many
      Classes.(
        let hitbox = close_hitbox size in
        [ p 0.
        ; w hitbox
        ; h hitbox
        ; min_w hitbox
        ; min_h hitbox
        ; (let ~pad_x, ~pad_y = paddings size in
           {%css|
             position: absolute;

             /* Those offsets are manually adjusted in screenshot testing to "feel" good */
             top: %{spacing (pad_y *. 0.75)#Css_gen.Length};
             right: %{spacing pad_x#Css_gen.Length};
           |})
        ])
  ;;
end

module Content = struct
  type t =
    | Section of
        (size:Skyline_size.t
         -> close_button_present:bool
         -> is_first:bool
         -> is_last:bool
         -> Node.t)
    | Separator of Node.t
    | Close_button of (size:Skyline_size.t -> Node.t)
    | Fragment of t list

  let fragment l = Fragment l

  let rec flatten l =
    List.map l ~f:(function
      | Fragment l -> flatten l
      | v -> [ v ])
    |> List.concat
  ;;

  let to_vdom_nodes l ~size =
    let l = flatten l in
    let ~close_button, ~first_section_idx, ~last_section_idx =
      List.foldi
        l
        ~init:(~close_button:None, ~first_section_idx:(-1), ~last_section_idx:(-1))
        ~f:(fun i (~close_button, ~first_section_idx, ~last_section_idx) -> function
        | Close_button close_button ->
          ~close_button:(Some close_button), ~first_section_idx, ~last_section_idx
        | Section _ ->
          ( ~close_button
          , ~first_section_idx:(if first_section_idx < 0 then i else first_section_idx)
          , ~last_section_idx:i )
        | Separator _ | Fragment _ -> ~close_button, ~first_section_idx, ~last_section_idx)
    in
    List.mapi l ~f:(fun i -> function
      | Fragment _ | Close_button _ -> Node.none
      | Separator v -> v
      | Section f ->
        f
          ~size
          ~close_button_present:(Option.is_some close_button)
          ~is_first:(i = first_section_idx)
          ~is_last:(i = last_section_idx))
    @
    match close_button with
    | None -> []
    | Some close -> [ close ~size ]
  ;;
end

let view ?test_selector ?(size = `Md) ?(attrs = []) children =
  [%html.jsx
    {|
      <dialog
        open
        %{Style.root size}
        %{Bonsai.Test_selector.attr_of_opt test_selector}
        %{Classes.data_skyline_component "dialog"}
        *{attrs}
      >
        *{Content.to_vdom_nodes ~size children}
      </dialog>
    |}]
;;

module Section = struct
  let content'
    ?test_selector
    ?(scrollable = true)
    ?(full_bleed = false)
    ?(attrs = [])
    children
    ~size
    ~close_button_present
    ~is_first
    ~is_last
    =
    [%html.jsx
      {|
        <section
          %{Style.section ~is_first ~is_last ~close_button_present ~scrollable ~full_bleed size}
          %{Bonsai.Test_selector.attr_of_opt test_selector}
          *{attrs}
        >
          *{children}
        </section>
      |}]
  ;;

  let content ?test_selector ?scrollable ?full_bleed ?attrs children =
    Content.Section (content' ?test_selector ?scrollable ?full_bleed ?attrs children)
  ;;

  let title ?test_selector ?(scrollable = false) ?full_bleed ?(attrs = []) children =
    Content.Section
      (fun ~size ~close_button_present ~is_first ~is_last ->
        Skyline_text_v2.view
          ~size:(size :> Skyline_text_v2.Size.t)
          ~weight:`Bold
          ~layout:`Contents
          [ content'
              ~attrs:(Attr.role "sectionhead" :: attrs)
              ~scrollable
              ?full_bleed
              ?test_selector
              children
              ~size
              ~close_button_present
              ~is_first
              ~is_last
          ])
  ;;

  let text ?test_selector ?(scrollable = true) ?full_bleed ?attrs children =
    Content.Section
      (fun ~size ~close_button_present ~is_first ~is_last ->
        Skyline_text_v2.view
          ~size:(size :> Skyline_text_v2.Size.t)
          ~layout:`Contents
          [ content'
              ?attrs
              ~scrollable
              ?full_bleed
              ?test_selector
              children
              ~size
              ~close_button_present
              ~is_first
              ~is_last
          ])
  ;;

  let footer ?test_selector ?(scrollable = false) ?full_bleed ?(attrs = []) l =
    content
      ?test_selector
      ~scrollable
      ?full_bleed
      ~attrs:(Attr.role "navigation" :: attrs)
      l
  ;;

  let separator ?(attrs = []) () =
    Content.Separator (Node.hr ~attrs:(Style.separator :: attrs) ())
  ;;
end

module Close_button = struct
  let content ?test_selector ?(attrs = []) () ~close =
    Content.Close_button
      (fun ~size ->
        [%html.jsx
          {|
            <Skyline_button_v2.view
              ?test_selector
              ~size
              ~variant:%{Ghost}
              ~intent:%{`Secondary}
              %{Style.close_button size}
              ~on_click:%{close}
              *{attrs}
            >
              <Skyline_button_v2.Icon.view ~icon:%{Lucide.x} />
            </>
          |}])
  ;;
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
