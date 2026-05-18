open! Core
open! Private_skyline_prelude

module Position = struct
  type t = Bonsai_web_toplayer.Position.t =
    | Auto
    | Top
    | Bottom
    | Left
    | Right
  [@@deriving sexp, equal, compare, enumerate, to_string]
end

module Alignment = struct
  type t = Bonsai_web_toplayer.Alignment.t =
    | Center
    | Start
    | End
  [@@deriving sexp_of, equal, to_string]
end

module Match_anchor_side = struct
  type t = Bonsai_web_toplayer.Match_anchor_side.t =
    | Grow_to_match
    | Match_exactly
    | Shrink_to_match
  [@@deriving sexp_of, equal, to_string]
end

type t =
  { anchor : Vdom.Attr.t
  ; is_open : bool
  ; set_is_open : bool -> unit Effect.t
  }

let component'
  ?(position = return Position.Auto)
  ?(alignment = return Alignment.Center)
  ?match_anchor_side_length
  ?(focus_on_show = return true)
  ?(close_on_click_outside = return true)
  ?state
  contents
  (local_ graph)
  =
  let is_open, set_is_open =
    match state with
    | Some (visible, set_visible) -> visible, set_visible
    | None -> Bonsai.state false graph
  in
  let attrs =
    Bonsai.return
      [ [%css {||}]
      ; (match match_anchor_side_length with
         | None ->
           (* We set a 4px offset for the popover, so we reduce the width by 8px to allow
              for the same amount of margin to either side of the viewport. *)
           [%css
             {|
               display: flex;
               flex-direction: column;
               width: max-content;
               max-width: max(300px, calc(100vw - 8px));
             |}]
         | Some _ ->
           (* If [match_anchor_side_length] is set, then [Bonsai_web_toplayer] will manage
              our width. We apply CSS Grid to allow the content to in either axis. *)
           [%css
             {|
               display: grid;
               grid-auto-flow: row;
             |}])
      ; (* Override default styles applied by [Bonsai_web_themed_toplayer.Popover] *)
        [%css
          {|
            padding: 0;
            border: none;
            background: none;
          |}]
      ; Classes.data_skyline_component "popover"
      ]
  in
  let anchor =
    let close =
      let%arr set_is_open in
      set_is_open false
    in
    let close_on_click_outside =
      if%arr close_on_click_outside
      then Bonsai_web_toplayer.Close_on_click_outside.Yes
      else No
    in
    let autoclose =
      Bonsai_web_toplayer.Autoclose.create
        ~close
        ~close_on_click_outside
        ~close_on_right_click_outside:close_on_click_outside
        ~close_on_esc:(return true)
        graph
    in
    match%sub is_open with
    | true ->
      Bonsai_web_toplayer.Popover.always_open
        ~attrs
        ~autoclose
        ~position
        ~alignment
        ~match_anchor_side_length:(Bonsai.transpose_opt match_anchor_side_length)
        ~focus_on_open:focus_on_show
        ~overflow_auto_wrapper:(return false)
        ~content:(fun graph -> contents ~hide:close graph)
        graph
    | false -> return Vdom.Attr.empty
  in
  let%arr anchor and is_open and set_is_open in
  { anchor; is_open; set_is_open }
;;

let component
  ?position
  ?alignment
  ?match_anchor_side_length
  ?focus_on_show
  ?close_on_click_outside
  ?state
  contents
  (local_ graph)
  =
  component'
    ?position
    ?alignment
    ?match_anchor_side_length
    ?focus_on_show
    ?close_on_click_outside
    ?state
    (fun ~hide graph ->
      let%arr content = contents ~hide graph in
      [%html.jsx
        {|
          <Skyline_card_v2.view
            ~elevation:%{Two}
            ~size:%{`Xs}
            style="min-width: 0"
          >
            <Skyline_card_v2.Section.text> %{content} </>
          </>
        |}])
    graph
;;

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
