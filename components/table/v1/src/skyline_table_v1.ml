open! Core
open! Bonsai_web

module Layout = struct
  type t =
    | Auto
    | Fixed of Css_gen.Length.t
  [@@deriving sexp_of, compare]

  let equal = [%compare.equal: t]
end

module Alignment = struct
  type t =
    | Left
    | Right
    | Center
  [@@deriving sexp_of, equal]

  let to_css = function
    | Left -> `Left
    | Right -> `Right
    | Center -> `Center
  ;;
end

module Style = struct
  let ( @> ) = Css_gen.( @> )

  let table ~layout ~border =
    let style =
      let layout =
        match layout with
        | Layout.Auto -> Css_gen.create ~field:"table-layout" ~value:"auto"
        | Fixed width ->
          Css_gen.create ~field:"table-layout" ~value:"fixed" @> Css_gen.width width
      in
      let border =
        if border
        then
          Css_gen.border ~width:(`Px 1) ~style:`Solid ~color:Skyline_theme_v1.border ()
          @> Css_gen.border_radius (`Px 4)
          @> Css_gen.overflow `Hidden
          @> Css_gen.background_color Skyline_theme_v1.surface
          @> Css_gen.border_spacing (`Px 0)
        else Css_gen.empty
      in
      Vdom.Attr.style (layout @> border @> Css_gen.border_spacing (`Px 0))
    in
    if border
    then Vdom.Attr.combine style Private_skyline_theme.Stylesheet.step_nested_surface_ramp
    else style
  ;;

  let row ~border ~idx =
    let background =
      if idx % 2 = 0 || not border
      then Css_gen.empty
      else
        Css_gen.background_color
          (Skyline_theme_v1.fade Skyline_theme_v1.primary (Percent.of_percentage 5.))
    in
    Vdom.Attr.style background
  ;;

  let cell ~padding ~align =
    Vdom.Attr.style
      (Css_gen.uniform_padding padding @> Css_gen.text_align (Alignment.to_css align))
  ;;
end

module Col = struct
  type 'a t =
    | Cell :
        { heading : string
        ; tooltip : string option
        ; icon : Codicons.t option
        ; align : Alignment.t
        ; cell : 'a -> Vdom.Node.t
        }
        -> 'a t
    | Group : 'a t list -> 'a t
    | Lift : ('a -> 'b) * 'b t -> 'a t

  type 'a t_list =
    | [] : unit t_list
    | ( :: ) : 'hd t * 'tl t_list -> ('hd * 'tl) t_list

  let create ?tooltip ?icon ?(align = Alignment.Left) ~heading cell =
    Cell { heading; tooltip; icon; align; cell }
  ;;

  let lift column ~f = Lift (f, column)
  let group columns = Group columns

  let impl_for_type to_string ?tooltip ?icon ?align ?font ?style ?decoration heading =
    create ?tooltip ?icon ?align ~heading (fun value ->
      Skyline_text_v1.span
        ?font
        ?style
        ?decoration
        ?align:(Option.map align ~f:Alignment.to_css)
        (to_string value))
  ;;

  let string = impl_for_type Fn.id
  let int = impl_for_type Int.to_string_hum
  let float = impl_for_type Float.to_string_hum
  let bool = impl_for_type Bool.to_string

  let sexp
    ?tooltip
    ?icon
    ?align
    ?(font = Skyline_text_v1.Font_family.Monospace)
    ?style
    ?decoration
    heading
    =
    impl_for_type
      Sexp.to_string_hum
      ?tooltip
      ?icon
      ?align
      ~font
      ?style
      ?decoration
      heading
  ;;

  let vdom ?tooltip ?icon ?align heading =
    create ?tooltip ?icon ?align ~heading (fun vdom -> vdom)
  ;;
end

module Row = struct
  type 'cols t =
    | [] : unit t
    | ( :: ) : 'hd * 'tl t -> ('hd * 'tl) t
end

let rec list_of_cols : type cols. cols Col.t_list -> f:('a. 'a Col.t -> 'b) -> 'b list =
  fun cols ~f ->
  match cols with
  | [] -> []
  | hd :: tl -> f hd :: list_of_cols tl ~f
;;

let rec exists_in_cols : type cols. cols Col.t_list -> f:('a. 'a Col.t -> bool) -> bool =
  fun cols ~f ->
  match cols with
  | [] -> false
  | hd :: tl -> f hd || exists_in_cols tl ~f
;;

let rec list_of_row
  : type cols. cols Col.t_list -> cols Row.t -> f:('a. 'a Col.t -> 'a -> 'b) -> 'b list
  =
  fun cols row ~f ->
  match cols, row with
  | [], [] -> []
  | col_hd :: col_tl, row_hd :: row_tl -> f col_hd row_hd :: list_of_row col_tl row_tl ~f
;;

let table_head ~padding cols =
  let rec unroll_column : type a. a Col.t -> _ list = function
    | Cell { heading; tooltip; icon; align; cell = _ } ->
      let tooltip =
        let alignment =
          match align with
          | Left -> Skyline_tooltip_v1.Alignment.Start
          | Center -> Center
          | Right -> End
        in
        Option.value_map
          tooltip
          ~f:(Skyline_tooltip_v1.text ~alignment)
          ~default:Vdom.Attr.empty
      in
      [ Vdom.Node.th
          ~attrs:[ Style.cell ~padding ~align; tooltip ]
          [ Skyline_flex_v1.row
              ~gap:(`Px 4)
              ~align:Center
              ~justify:
                (match align with
                 | Left -> Flex_start
                 | Right -> Flex_end
                 | Center -> Center)
              [ Skyline_text_v1.span ~style:Bold ~size:Small heading
              ; Option.value_map
                  icon
                  ~f:(Codicons.svg ~size:(`Px 14))
                  ~default:Vdom.Node.none
              ]
          ]
      ]
    | Group columns -> List.concat_map columns ~f:unroll_column
    | Lift (_, col) -> unroll_column col
  in
  let rec should_render_heading : type a. a Col.t -> bool = function
    | Cell { heading; icon; _ } ->
      let has_icon =
        match icon with
        | None | Some Blank -> false
        | Some _ -> true
      in
      (not (String.is_empty heading)) || has_icon
    | Group columns -> List.exists columns ~f:should_render_heading
    | Lift (_, col) -> should_render_heading col
  in
  if exists_in_cols cols ~f:should_render_heading
  then Vdom.Node.thead [ Vdom.Node.tr (List.concat (list_of_cols cols ~f:unroll_column)) ]
  else Vdom.Node.none
;;

let table_row ~border ~padding cols idx row =
  let rec unroll_row : type a. a Col.t -> a -> Vdom.Node.t list =
    fun col value ->
    match col with
    | Cell { align; cell; _ } ->
      [ Vdom.Node.td ~attrs:[ Style.cell ~padding ~align ] [ cell value ] ]
    | Group columns -> List.concat_map columns ~f:(fun col -> unroll_row col value)
    | Lift (lift, col) -> unroll_row col (lift value)
  in
  Vdom.Node.tr
    ~attrs:[ Style.row ~border ~idx ]
    (List.concat (list_of_row cols row ~f:(fun col value -> unroll_row col value)))
;;

let table_body ~border ~padding cols rows =
  Vdom.Node.tbody (List.mapi rows ~f:(table_row ~border ~padding cols))
;;

let component
  ?(layout = Layout.Auto)
  ?(border = true)
  ?(padding = if border then `Px 6 else `Px 4)
  cols
  rows
  =
  Vdom.Node.table
    ~attrs:[ Style.table ~layout ~border; Vdom.Attr.create "cellspacing" "0" ]
    [ table_head ~padding cols; table_body ~border ~padding cols rows ]
;;
