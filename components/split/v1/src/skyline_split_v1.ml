open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module Size = struct
  type length =
    [ `Px of int
    | `Percent of Percent.t
    ]

  type t = min:Bonsai_web_panel.Config.Size.t * Bonsai_web_panel.Config.Size.t

  let length_to_byo : length -> Bonsai_web_panel.Config.Size.t = function
    | `Px px -> Px px
    | `Percent percent -> Percent percent
  ;;

  let create ?(min = `Px 24) length = ~min:(length_to_byo min), length_to_byo length

  let t_to_byo (~min, length) : Bonsai_web_panel.Config.Child_layout.t =
    Bonsai_web_panel.Config.Child_layout.create
      ~expanded:true
      ~hidden:false
      ~min_size:min
      length
  ;;
end

module Layout = struct
  type t =
    | Content of Vdom.Node.t
    | Columns of (t * Size.t) list
    | Rows of (t * Size.t) list

  let single node = Content node
  let columns columns = Columns columns
  let rows rows = Rows rows

  let rec to_config rev_path layout : int list Bonsai_web_panel.Config.t =
    match layout with
    | Content _ -> Bonsai_web_panel.Config.create_content (List.rev rev_path)
    | Columns columns ->
      List.mapi columns ~f:(fun idx (child, size) ->
        to_config (idx :: rev_path) child, Size.t_to_byo size)
      |> Bonsai_web_panel.Config.create_stack_horizontal
    | Rows rows ->
      List.mapi rows ~f:(fun idx (child, size) ->
        to_config (idx :: rev_path) child, Size.t_to_byo size)
      |> Bonsai_web_panel.Config.create_stack_vertical_fixed
  ;;

  let rec access_at_path layout path =
    match layout, path with
    | Content node, [] -> Some node
    | Columns items, idx :: path | Rows items, idx :: path ->
      let%bind.Option child, _ = List.nth items idx in
      access_at_path child path
    | Content _, _ :: _ | (Columns _ | Rows _), [] -> None
  ;;
end

let component layout graph =
  let config =
    let%arr layout in
    Layout.to_config [] layout
  in
  let logic =
    Bonsai_web_panel.Logic.create
      ~equal:[%equal: int list]
      ~sexp_of:sexp_of_opaque
      ~config
      graph
  in
  Bonsai_web_panel.component
    ~style_config:(return Skyline_panel_v1.style_config)
    ~logic
    ~content:(fun path _ ->
      let%arr path and layout in
      Layout.access_at_path layout path |> Option.value ~default:Vdom.Node.none)
    graph
;;

let space_evenly nodes =
  let length = List.length nodes in
  let single_size = Percent.of_mult (1. /. float_of_int length) in
  ( ~min:(Bonsai_web_panel.Config.Size.Px 24)
  , Bonsai_web_panel.Config.Size.Percent single_size )
;;

let columns columns graph =
  let layout =
    let%arr columns in
    let size = space_evenly columns in
    List.map columns ~f:(fun col -> Layout.single col, size) |> Layout.columns
  in
  component layout graph
;;

let rows rows graph =
  let layout =
    let%arr rows in
    let size = space_evenly rows in
    List.map rows ~f:(fun row -> Layout.single row, size) |> Layout.rows
  in
  component layout graph
;;
