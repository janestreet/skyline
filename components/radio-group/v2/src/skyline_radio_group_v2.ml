open! Core
open! Private_skyline_prelude
open Bonsai.Let_syntax

type 'a t =
  { value : 'a
  ; set_value : 'a -> unit Effect.t
  ; view : Vdom.Node.t
  }

let view_with_state
  (type a)
  ?(test_selectors : a Test_selector.Keyed.t option)
  ?(attrs = [])
  ?(size = `Md)
  ?(intent = `Primary)
  ?(disabled = false)
  ~name
  ~state:(current_value, set_value)
  ~equal
  ~to_string
  ~values
  ()
  =
  let fields =
    List.map values ~f:(fun value ->
      let is_checked = equal value current_value in
      let test_selector =
        let%map.Option test_selectors in
        Test_selector.Keyed.get test_selectors value
      in
      {%html|
        <Skyline_field_v2.Grid.field
          ~attrs:%{[Test_selector.attr_of_opt test_selector]}
          ~size
          ~intent
          ~disabled
          ~label:(<Skyline_field_v2.Label.content> #{to_string value} </>)
          ~label_position:%{Skyline_field_v2.Label_position.Right} >
            <Skyline_radio_input_v2.content
              ~group:%{name}
              ~state:%{(is_checked, set_value value)} />
        </>
      |})
  in
  let view =
    {%html|
      <Skyline_field_v2.Grid.view *{attrs}>
        *{fields}
      </>
    |}
  in
  { value = current_value; set_value; view }
;;

let view
  ?test_selectors
  ?attrs
  ?size
  ?intent
  ?disabled
  ~name
  ~state
  ~equal
  ~to_string
  ~values
  ()
  =
  let { view; set_value = _; value = _ } =
    view_with_state
      ?test_selectors
      ?attrs
      ?size
      ?intent
      ?disabled
      ~name
      ~state
      ~equal
      ~to_string
      ~values
      ()
  in
  view
;;

let component
  (type a)
  ?test_selectors
  ?attrs
  ?size
  ?intent
  ?disabled
  ?state
  ~(equal : a -> a -> bool)
  ~to_string
  ~values
  graph
  =
  let current_value, set_value =
    match state with
    | None -> Bonsai_kernel_selection_state.One_of_many.create ~equal values graph
    | Some state -> state
  in
  let%arr current_value
  and set_value
  and values
  and name = Bonsai.path_id graph
  and attrs = Bonsai.transpose_opt attrs
  and size = Bonsai.transpose_opt size
  and intent = Bonsai.transpose_opt intent
  and disabled = Bonsai.transpose_opt disabled in
  view_with_state
    ?test_selectors
    ?attrs
    ?size
    ?intent
    ?disabled
    ~name
    ~state:(current_value, set_value)
    ~equal
    ~to_string
    ~values:(Nonempty_list.to_list values)
    ()
;;

module For_docs = struct
  let ml_filepath = __FILE__
end

module For_testing = struct
  let ascii_render ~selected ~values ~to_string ~equal =
    let open Ascii_table_kernel in
    let columns =
      [ Column.create "Value" (fun value ->
          let is_selected = equal value selected in
          let selected_marker = if is_selected then "[x]" else "[ ]" in
          [%string "%{selected_marker} %{to_string value}"])
      ]
    in
    Ascii_table_kernel.to_string_noattr columns values ~bars:`Unicode
  ;;
end
