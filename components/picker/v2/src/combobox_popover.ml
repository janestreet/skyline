open! Core
open! Private_skyline_prelude
module Toplayer = Bonsai_web_toplayer
module Js = Js_of_ocaml.Js

let popover_attrs =
  [ [%css
      {|
        display: grid;
        grid-auto-flow: row;
        padding: 0;
        border: none;
        background: none;
      |}]
  ]
;;

let anchor_data_attr = "data-combobox-input-anchor"

let target_is_inside_anchor ~anchor_id ~target =
  let selector = Js.string [%string "[%{anchor_data_attr}=\"%{anchor_id}\"]"] in
  match Js.Opt.to_option target with
  | None -> false
  | Some element -> Js.Opt.test (element##closest selector)
;;

let component ~is_open ~close ~content (local_ graph) =
  let anchor_id = Bonsai.path_id graph in
  let close_on_click_outside =
    let%arr anchor_id in
    Toplayer.Close_on_click_outside.Custom
      (fun ~target ->
        let inside_popover =
          Toplayer.Close_on_click_outside.is_target_inside_a_popover ~target
        in
        let inside_anchor = target_is_inside_anchor ~anchor_id ~target in
        if inside_popover || inside_anchor then `Don't_close else `Close)
  in
  let autoclose =
    Toplayer.Autoclose.create
      ~close
      ~close_on_click_outside
      ~close_on_right_click_outside:close_on_click_outside
      ~close_on_esc:(return true)
      graph
  in
  let popover_anchor_attr =
    match%sub is_open with
    | true ->
      Toplayer.Popover.always_open
        ~attrs:(return popover_attrs)
        ~autoclose
        ~position:(return Toplayer.Position.Bottom)
        ~alignment:(return Toplayer.Alignment.Start)
        ~match_anchor_side_length:(return (Some Toplayer.Match_anchor_side.Match_exactly))
        ~focus_on_open:(return false)
        ~overflow_auto_wrapper:(return false)
        ~content
        graph
    | false -> return Attr.empty
  in
  let%arr popover_anchor_attr and anchor_id in
  Attr.many [ popover_anchor_attr; Attr.create anchor_data_attr anchor_id ]
;;
