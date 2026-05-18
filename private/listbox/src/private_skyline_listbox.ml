open! Core
open! Private_skyline_prelude

module Container = struct
  let view ?(attrs = []) children =
    {%html.jsx|
      <Skyline_card_v2.view
        style="overflow-x: hidden; overflow-y: auto; max-height: 240px"
        *{attrs}
        ~elevation:%{Two}
        ~surface_color:%{One}
        ~size:%{`Sm}
      >
        <Skyline_card_v2.Section.content
          ~full_bleed:%{true}
          style="background-color: inherit"
        >
          *{children}</></>
    |}
  ;;
end

module Item = struct
  let styles ~size ~is_active ~is_disabled =
    let bg =
      Attr.many
        (match is_disabled, is_active with
         | true, _ -> [ Classes.bg_one; Classes.text_disabled ]
         | false, true -> [ Classes.bg_primary_alt; Classes.text_default ]
         | false, false ->
           [ Classes.bg_one
           ; Classes.text_default
           ; {%css|
               &:hover {
                 background-color: %{Colors.Background.secondary#Css_gen.Color};
               }
             |}
           ])
    in
    let text =
      match size with
      | `Xs -> Classes.text_2xs
      | `Sm -> Classes.text_xs
      | `Md -> Classes.text_sm
      | `Lg -> Classes.text_base
    in
    let padding =
      match size with
      | `Xs ->
        {%css|
          padding: %{Classes.spacing 0.25#Css_gen.Length}
            %{Classes.spacing 0.5#Css_gen.Length};
        |}
      | `Sm ->
        {%css|
          padding: %{Classes.spacing 0.5#Css_gen.Length}
            %{Classes.spacing 1.#Css_gen.Length};
        |}
      | `Md ->
        {%css|
          padding: %{Classes.spacing 1.#Css_gen.Length}
            %{Classes.spacing 2.#Css_gen.Length};
        |}
      | `Lg ->
        {%css|
          padding: %{Classes.spacing 2.#Css_gen.Length}
            %{Classes.spacing 4.#Css_gen.Length};
        |}
    in
    let rounded =
      match size with
      | `Xs -> Classes.rounded_xs
      | `Sm -> Classes.rounded_sm
      | `Md -> Classes.rounded_md
      | `Lg -> Classes.rounded_lg
    in
    Attr.many
      [ bg
      ; text
      ; padding
      ; rounded
      ; {%css|
          cursor: pointer;
          text-align: left;
          width: 100%;
          outline: none;
        |}
      ]
  ;;

  let view ?(attrs = []) ~size ~is_active ~is_disabled children =
    {%html.jsx|
      <div
        *{attrs}
        %{styles ~size ~is_active ~is_disabled}
        %{Attr.role "listitem"}
      >
        *{children}
      </div>
    |}
  ;;
end
