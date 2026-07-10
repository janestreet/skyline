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

module Controller = struct
  type t =
    { autoclose : Vdom.Attr.t
    ; is_open : bool
    ; set_is_open : bool -> unit Effect.t
    }
  [@@deriving fields ~getters]

  let component ?(close_on_click_outside = return true) ?state (local_ graph) =
    (* [Bonsai_web_toplayer.Popover.*] does this too: mounting the toplayer root early
       avoids an expensive whole-document style recalculation when the first popover
       opens. *)
    Bonsai_web_toplayer.Expert.ensure_global_toplayer_root_mounted ();
    let is_open, set_is_open =
      match state with
      | Some (visible, set_visible) -> visible, set_visible
      | None -> Bonsai.state false graph
    in
    let autoclose =
      let close =
        let%arr set_is_open in
        set_is_open false
      in
      let close_on_click_outside =
        if%arr close_on_click_outside
        then Bonsai_web_toplayer.Close_on_click_outside.Yes
        else No
      in
      Bonsai_web_toplayer.Autoclose.create
        ~close
        ~close_on_click_outside
        ~close_on_right_click_outside:close_on_click_outside
        ~close_on_esc:(return true)
        graph
    in
    let%arr autoclose and is_open and set_is_open in
    { autoclose :> Vdom.Attr.t; is_open; set_is_open }
  ;;
end

let popover_attrs ~match_anchor_side_length =
  [ (match match_anchor_side_length with
     | None ->
       (* We set a 4px offset for the popover, so we reduce the width by 8px to allow for
          the same amount of margin to either side of the viewport. *)
       [%css
         {|
           display: flex;
           flex-direction: column;
           width: max-content;
           max-width: max(300px, calc(100vw - 8px));
         |}]
     | Some (_ : Match_anchor_side.t) ->
       (* If [match_anchor_side_length] is set, then [Bonsai_web_toplayer] will manage our
          width. We apply CSS Grid to allow the content to grow in either axis. *)
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
;;

let attr
  ?(position = Position.Auto)
  ?(alignment = Alignment.Center)
  ?match_anchor_side_length
  ?(focus_on_show = true)
  ~controller:
    ({ autoclose; is_open; set_is_open = (_ : bool -> unit Effect.t) } : Controller.t)
  contents
  =
  match is_open with
  | false -> Vdom.Attr.empty
  | true ->
    let focus_attrs =
      if focus_on_show then [ Bonsai_web_toplayer.Expert.focus_popover_on_open ] else []
    in
    Bonsai_web_toplayer.vdom_popover
      ~popover_attrs:(focus_attrs @ (autoclose :: popover_attrs ~match_anchor_side_length))
      ~position
      ~alignment
      ?match_anchor_side_length
      ~overflow_auto_wrapper:false
      contents
;;

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
  ?close_on_click_outside
  ?state
  contents
  (local_ graph)
  =
  let controller = Controller.component ?close_on_click_outside ?state graph in
  let%sub { Controller.is_open; set_is_open; autoclose = _ } = controller in
  let contents =
    (* Gate the contents' activity on [is_open] so that they are only active while the
       popover is shown. This means contents can use [on_activate] / [on_deactivate]
       lifecycle hooks, and don't recompute while hidden. *)
    match%sub is_open with
    | true ->
      let hide =
        let%arr set_is_open in
        set_is_open false
      in
      contents ~hide graph
    | false -> return Vdom.Node.none
  in
  let%arr controller
  and contents
  and position
  and alignment
  and match_anchor_side_length = Bonsai.transpose_opt match_anchor_side_length
  and focus_on_show in
  let anchor =
    attr
      ~position
      ~alignment
      ?match_anchor_side_length
      ~focus_on_show
      ~controller
      contents
  in
  { anchor
  ; is_open = Controller.is_open controller
  ; set_is_open = Controller.set_is_open controller
  }
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
      [%html
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
