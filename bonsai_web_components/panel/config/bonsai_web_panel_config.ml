open! Core

module Stable = struct
  open Stable_witness.Export

  module Size = struct
    module V1 = struct
      type%delta_knot t =
        | Px of int
        | Percent of Percent.Stable.V3.t
      [@@deriving sexp, compare, equal, bin_io, sexp_grammar, stable_witness]

      let%expect_test _ =
        print_endline [%bin_and_sexp_digest: t];
        [%expect {| 8603a0d985af20c2647d6a704d826780 |}]
      ;;
    end

    module Latest = V1
  end

  module Panel_id = struct
    module V1 = struct
      module Id =
        (val String_id.make
               ~module_name:"Bonsai_web_panel_config.Panel_id"
               ~include_default_validation:true
               ())

      include Id.Stable.V1
      include functor Comparable.Make

      let%expect_test _ =
        print_endline [%bin_and_sexp_digest: t];
        [%expect {| 4d0c124af9d4a2e75d8a4b16a6fcb66a |}]
      ;;
    end

    module Latest = V1
  end

  module Child_layout = struct
    module Layout_type = struct
      module Accordion = struct
        module V1 = struct
          type%delta_knot t = { title : string }
          [@@deriving sexp, compare, equal, bin_io, sexp_grammar, stable_witness]

          let%expect_test _ =
            print_endline [%bin_and_sexp_digest: t];
            [%expect {| 77dd2b456232c8d4495df908f7681dfa |}]
          ;;
        end

        module Latest = V1
      end

      module V1 = struct
        type%delta_knot t =
          | Accordion of Accordion.V1.t
          | Raw
        [@@deriving sexp, compare, equal, bin_io, sexp_grammar, stable_witness]

        let%expect_test _ =
          print_endline [%bin_and_sexp_digest: t];
          [%expect {| 7e4cd92d8400e2e1dae5587c267eb512 |}]
        ;;
      end

      module Latest = V1
    end

    module V1 = struct
      type%delta_knot t =
        { size : Size.V1.t
        ; layout_type : Layout_type.V1.t
        ; min_size : Size.V1.t
        ; hidden : bool
        ; expanded : bool
        }
      [@@deriving
        sexp, compare, equal, bin_io, sexp_grammar, stable_witness, fields ~getters]

      let%expect_test _ =
        print_endline [%bin_and_sexp_digest: t];
        [%expect {| 8789df25f1d71330fa910fbfc3679da4 |}]
      ;;
    end

    module Latest = V1
  end

  module Tabbed = struct
    module V1 = struct
      type%delta_knot 'a t =
        { tabs : ('a * string) Nonempty_list.Stable.V3.t
        ; current_tab : int
        }
      [@@deriving
        sexp, compare, equal, bin_io, sexp_grammar, fields ~getters, stable_witness]

      let%expect_test _ =
        print_endline [%bin_and_sexp_digest: int t];
        [%expect {| 6f6170d10887d0b874cb3bb52c5c4132 |}]
      ;;
    end

    module Latest = V1
  end

  module V1 = struct
    type%delta_knot 'a t =
      | Content of 'a
      | Vertical_variable of ('a t * Child_layout.V1.t) list
      | Vertical_fixed of ('a t * Child_layout.V1.t) list
      | Horizontal_fixed of ('a t * Child_layout.V1.t) list
      | Tabbed of 'a t Tabbed.V1.t
    [@@deriving sexp, compare, equal, bin_io, sexp_grammar, stable_witness]

    let%expect_test _ =
      print_endline [%bin_and_sexp_digest: int t];
      [%expect {| 4102fabf0701c63e2d23153c02561402 |}]
    ;;

    let rec map t ~f =
      match t with
      | Content c -> Content (f c)
      | Horizontal_fixed children ->
        Horizontal_fixed (List.map children ~f:(fun (t, layout) -> map ~f t, layout))
      | Vertical_fixed children ->
        Vertical_fixed (List.map children ~f:(fun (t, layout) -> map ~f t, layout))
      | Vertical_variable children ->
        Vertical_variable (List.map children ~f:(fun (t, layout) -> map ~f t, layout))
      | Tabbed { tabs; current_tab } ->
        Tabbed
          { current_tab
          ; tabs = Nonempty_list.map tabs ~f:(fun (t, name) -> map ~f t, name)
          }
    ;;
  end

  module V2 = struct
    type%delta_knot 'a t =
      { panel_id : Panel_id.V1.t
      ; config : 'a config
      }

    and 'a config =
      | Content of 'a
      | Vertical_variable of ('a t * Child_layout.V1.t) list
      | Vertical_fixed of ('a t * Child_layout.V1.t) list
      | Horizontal_fixed of ('a t * Child_layout.V1.t) list
      | Tabbed of 'a t Tabbed.V1.t
    [@@deriving sexp, compare, equal, bin_io, sexp_grammar, stable_witness]

    let rec of_V1 ?(random_state = Random.State.default) (t : 'a V1.t) : 'a t =
      let uuid = Uuid.create_random random_state in
      let config =
        let map_children children =
          List.map children ~f:(fun (child, layout) -> of_V1 ~random_state child, layout)
        in
        match t with
        | V1.Content content -> Content content
        | V1.Vertical_variable children -> Vertical_variable (map_children children)
        | V1.Vertical_fixed children -> Vertical_fixed (map_children children)
        | V1.Horizontal_fixed children -> Horizontal_fixed (map_children children)
        | V1.Tabbed { tabs; current_tab } ->
          Tabbed
            { tabs =
                Nonempty_list.map tabs ~f:(fun (child, label) ->
                  of_V1 ~random_state child, label)
            ; current_tab
            }
      in
      { panel_id = Panel_id.V1.of_string (Uuid.to_string uuid |> String.sub ~pos:0 ~len:8)
      ; config
      }
    ;;

    let t_of_sexp_with_state ?(random_state = Random.State.default) sexp_of_a s =
      match Or_error.try_with (fun () -> t_of_sexp sexp_of_a s) with
      | Ok result -> result
      | Error _ -> V1.t_of_sexp sexp_of_a s |> of_V1 ~random_state
    ;;

    let t_of_sexp sexp_of_a s = t_of_sexp_with_state sexp_of_a s

    let rec map t ~f =
      match t.config with
      | Content c -> { t with config = Content (f c) }
      | Horizontal_fixed children ->
        { t with
          config =
            Horizontal_fixed (List.map children ~f:(fun (t, layout) -> map ~f t, layout))
        }
      | Vertical_fixed children ->
        { t with
          config =
            Vertical_fixed (List.map children ~f:(fun (t, layout) -> map ~f t, layout))
        }
      | Vertical_variable children ->
        { t with
          config =
            Vertical_variable (List.map children ~f:(fun (t, layout) -> map ~f t, layout))
        }
      | Tabbed { tabs; current_tab } ->
        { t with
          config =
            Tabbed
              { current_tab
              ; tabs = Nonempty_list.map tabs ~f:(fun (t, name) -> map ~f t, name)
              }
        }
    ;;

    let rec fold t ~init ~f =
      match t.config with
      | Content c -> f init c
      | Horizontal_fixed children ->
        List.fold children ~init ~f:(fun init (t, _) -> fold ~init ~f t)
      | Vertical_fixed children ->
        List.fold children ~init ~f:(fun init (t, _) -> fold ~init ~f t)
      | Vertical_variable children ->
        List.fold children ~init ~f:(fun init (t, _) -> fold ~init ~f t)
      | Tabbed { tabs; _ } ->
        Nonempty_list.fold ~init tabs ~f:(fun init (t, _) -> fold ~init ~f t)
    ;;

    let rec to_V1 (t : 'a t) : 'a V1.t =
      match t.config with
      | Content c -> V1.Content c
      | Vertical_variable children ->
        V1.Vertical_variable
          (List.map children ~f:(fun (child, layout) -> to_V1 child, layout))
      | Vertical_fixed children ->
        V1.Vertical_fixed
          (List.map children ~f:(fun (child, layout) -> to_V1 child, layout))
      | Horizontal_fixed children ->
        V1.Horizontal_fixed
          (List.map children ~f:(fun (child, layout) -> to_V1 child, layout))
      | Tabbed { tabs; current_tab } ->
        V1.Tabbed
          { tabs = Nonempty_list.map tabs ~f:(fun (child, name) -> to_V1 child, name)
          ; current_tab
          }
    ;;

    let%expect_test _ =
      print_endline [%bin_and_sexp_digest: int t];
      [%expect {| 89d04b66765d9f9e3cfe30c9164513ae |}]
    ;;
  end

  module Latest = V2
end

module Size = struct
  type t = Stable.Size.Latest.t =
    | Px of int
    | Percent of Percent.t
  [@@deriving sexp, compare, equal, bin_io, sexp_grammar]

  let percent_of_float percent = Percent (Percent.of_mult percent)

  let to_pixels_value ~parent_size percent =
    Float.of_int parent_size *. Percent.to_mult percent |> Float.to_int
  ;;

  let to_percent_value ~parent_size px =
    Float.of_int px /. Float.of_int parent_size |> Percent.of_mult
  ;;

  let to_pixels ~parent_size = function
    | Px pixels -> pixels
    | Percent percent -> to_pixels_value ~parent_size percent
  ;;

  let to_percent ~parent_size = function
    | Px pixels -> to_percent_value ~parent_size pixels
    | Percent percent -> percent
  ;;

  let to_percent_size ~parent_size = function
    | Px v -> Percent (to_percent_value ~parent_size v)
    | Percent v -> Percent v
  ;;

  let to_px_size ~parent_size = function
    | Px v -> Px v
    | Percent v -> Px (to_pixels_value ~parent_size v)
  ;;

  let consolidate_with_op ~percent_op ~int_op ~parent_size a b =
    match a, b with
    | Px a, Px b -> Px (int_op a b)
    | Percent a, Percent b -> Percent (percent_op a b)
    | Px a, Percent b -> Px (int_op a (to_pixels_value ~parent_size b))
    | Percent a, Px b -> Percent (percent_op a (to_percent_value ~parent_size b))
  ;;

  let make_arithmetic_op percent_op int_op = consolidate_with_op ~percent_op ~int_op
  let sub = make_arithmetic_op Percent.( - ) ( - )
  let add = make_arithmetic_op Percent.( + ) ( + )
  let mul = make_arithmetic_op Percent.( * ) ( * )
  let div = make_arithmetic_op Percent.( / ) ( / )

  let div_to_percent ~parent_size a b =
    let a = to_percent_size ~parent_size a in
    let b = to_percent_size ~parent_size b in
    div ~parent_size a b
  ;;

  let%expect_test "size math" =
    let parent_size = 100 in
    let zero = Px 0 in
    let add_px = add ~parent_size zero (Px 10) in
    print_s [%message (add_px : t)];
    [%expect {| (add_px (Px 10)) |}];
    let add_percent = add ~parent_size zero (percent_of_float 0.1) in
    print_s [%message (add_percent : t)];
    [%expect {| (add_percent (Px 10)) |}];
    let half_px = Px 50 in
    let half_percent = percent_of_float 0.5 in
    let sub_px = sub ~parent_size half_px (percent_of_float 0.2) in
    print_s [%message (sub_px : t)];
    [%expect {| (sub_px (Px 30)) |}];
    let sub_percent = sub ~parent_size half_percent (Px 10) in
    print_s [%message (sub_percent : t)];
    [%expect {| (sub_percent (Percent 40%)) |}];
    let div_px_to_percent = div_to_percent ~parent_size half_px (Px 100) in
    print_s [%message (div_px_to_percent : t)];
    [%expect {| (div_px_to_percent (Percent 50%)) |}];
    ()
  ;;
end

module Panel_id = struct
  include Stable.Panel_id.Latest

  let generate_id ?(random_state = Random.State.default) () =
    let uuid = Uuid.create_random random_state in
    let full_string = Uuid.to_string uuid in
    let short_id = String.prefix full_string 8 in
    of_string short_id
  ;;
end

module Child_layout = struct
  module Layout_type = struct
    module Accordion = struct
      type t = Stable.Child_layout.Layout_type.Accordion.Latest.t = { title : string }
      [@@deriving sexp, compare, equal, bin_io, sexp_grammar]
    end

    type t = Stable.Child_layout.Layout_type.Latest.t =
      | Accordion of Accordion.t
      | Raw
    [@@deriving sexp, compare, equal, bin_io, sexp_grammar]
  end

  type t = Stable.Child_layout.Latest.t =
    { size : Size.t
    ; layout_type : Layout_type.t
    ; min_size : Size.t
    ; hidden : bool
    ; expanded : bool
    }
  [@@deriving fields ~getters ~setters, sexp, compare, equal, bin_io, sexp_grammar]

  let create
    ?(expanded = true)
    ?(hidden = false)
    ?title
    ~(min_size : Size.t)
    (size : Size.t)
    =
    { layout_type =
        Option.value_map
          ~f:(fun title -> Accordion { title })
          ~default:Layout_type.Raw
          title
    ; size
    ; min_size
    ; hidden
    ; expanded
    }
  ;;

  let expanded { expanded; _ } = expanded

  let title { layout_type; _ } =
    match layout_type with
    | Raw -> None
    | Accordion { title; _ } -> Some title
  ;;

  let current_size t = if expanded t && not t.hidden then t.size else Px 0
  let set_size ~size t = { t with size }
  let toggle t = { t with expanded = not t.expanded }
  let set_expanded ~expanded t = { t with expanded }
end

module Tabbed = struct
  type 'a t = 'a Stable.Tabbed.Latest.t =
    { tabs : ('a * string) Nonempty_list.t
    ; current_tab : int
    }
  [@@deriving sexp, compare, equal, bin_io, sexp_grammar, fields ~getters]
end

type 'a t = 'a Stable.Latest.t =
  { panel_id : Panel_id.t
  ; config : 'a config
  }
[@@deriving sexp, compare, equal, bin_io, sexp_grammar, fields ~getters]

and 'a config = 'a Stable.Latest.config =
  | Content of 'a
  | Vertical_variable of ('a t * Child_layout.t) list
  | Vertical_fixed of ('a t * Child_layout.t) list
  | Horizontal_fixed of ('a t * Child_layout.t) list
  | Tabbed of 'a t Tabbed.t
[@@deriving sexp, equal, bin_io, sexp_grammar, compare]

let t_of_sexp = Stable.Latest.t_of_sexp
let resolve_panel_id panel_id = Option.value ~default:(Panel_id.generate_id ()) panel_id

let create_stack_horizontal ?panel_id children : 'a t =
  { panel_id = resolve_panel_id panel_id; config = Horizontal_fixed children }
;;

let create_stack_vertical ?panel_id children : 'a t =
  { panel_id = resolve_panel_id panel_id; config = Vertical_variable children }
;;

let create_stack_vertical_fixed ?panel_id children : 'a t =
  { panel_id = resolve_panel_id panel_id; config = Vertical_fixed children }
;;

let create_stack_tabbed ?panel_id ?(initial_active_tab = 0) children : 'a t =
  { panel_id = resolve_panel_id panel_id
  ; config = Tabbed { tabs = children; current_tab = initial_active_tab }
  }
;;

let create_content ?panel_id content : 'a t =
  { panel_id = resolve_panel_id panel_id; config = Content content }
;;

let panel_id (t : 'a t) = t.panel_id

let child_configs (t : 'a t) =
  match t.config with
  | Content _ -> None
  | Vertical_variable children -> List.map ~f:fst children |> Some
  | Horizontal_fixed children | Vertical_fixed children ->
    List.map ~f:fst children |> Some
  | Tabbed { tabs; _ } -> Nonempty_list.to_list tabs |> List.map ~f:fst |> Some
;;

let child_float_layouts (t : 'a t) =
  match t.config with
  | Content _ -> None
  | Tabbed _ -> None
  | Horizontal_fixed children | Vertical_fixed children | Vertical_variable children ->
    List.map ~f:snd children |> Some
;;

let set_child_layout_configs t layout_configs =
  match t.config with
  | Content _ | Tabbed _ -> t
  | Vertical_variable _ -> { t with config = Vertical_variable layout_configs }
  | Vertical_fixed _ -> { t with config = Vertical_fixed layout_configs }
  | Horizontal_fixed _ -> { t with config = Horizontal_fixed layout_configs }
;;

let set_child_configs t configs =
  let zip children = List.zip_exn configs (List.map ~f:snd children) in
  match t.config with
  | Content _ -> t
  | Vertical_variable children -> { t with config = Vertical_variable (zip children) }
  | Vertical_fixed children -> { t with config = Vertical_fixed (zip children) }
  | Horizontal_fixed children -> { t with config = Horizontal_fixed (zip children) }
  | Tabbed tabbed ->
    { t with
      config =
        Tabbed
          { tabbed with
            tabs = Nonempty_list.to_list tabbed.tabs |> zip |> Nonempty_list.of_list_exn
          }
    }
;;

let set_child_layouts t (child_layouts : Child_layout.t list) : 'a t =
  let child_layouts children = List.zip_exn (List.map ~f:fst children) child_layouts in
  match t.config with
  | Content _ -> t
  | Horizontal_fixed children ->
    { t with config = Horizontal_fixed (child_layouts children) }
  | Vertical_fixed children -> { t with config = Vertical_fixed (child_layouts children) }
  | Vertical_variable children ->
    { t with config = Vertical_variable (child_layouts children) }
  | Tabbed _ -> t
;;

let set_tab_titles t titles =
  match t.config with
  | Tabbed tabbed ->
    { t with
      config =
        Tabbed
          { tabbed with
            tabs = Nonempty_list.zip_exn (Nonempty_list.map ~f:fst tabbed.tabs) titles
          }
    }
  | _ -> t
;;

let create_children = List.zip_exn
let map = Stable.Latest.map
let fold = Stable.Latest.fold
