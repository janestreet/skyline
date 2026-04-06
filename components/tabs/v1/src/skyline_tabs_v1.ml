open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

module type Tab = sig
  type t [@@deriving equal]

  val icon : t -> Codicons.t
  val label : t -> string
end

module Style = struct
  include
    [%css
    stylesheet
      ~dont_hash_prefixes:[ "--skyline" ]
      {|
        .container {
          width: 100%;
          margin: 0;
          padding: 0;
          display: flex;
          box-sizing: border-box;
          flex-direction: row;
          justify-content: space-between;
          align-items: center;
          gap: 8px;
        }

        .tab {
          height: 22px;
          margin: 0;
          padding: 0;
          display: flex;
          box-sizing: border-box;
          flex-direction: column;

          border: none;
          border-bottom-style: solid;
          border-bottom-width: 1px;
          border-bottom-color: rgba(0, 0, 0, 0);

          -webkit-appearance: button;
          appearance: button;
          color: var(--skyline-color-primary, inherit);
          background-color: transparent;
          user-select: none;
          cursor: pointer;
        }

        .tab .title {
          position: relative;
          padding: 2px 4px;
          border-radius: 4px;
          line-height: 18px;
        }

        .tab:not(.active):hover .title {
          background-color: var(--skyline-color-border);
        }

        .tab:not(.active) .notification:after {
          height: 8px;
          width: 8px;
          display: block;
          position: absolute;
          top: -2px;
          right: -2px;
          border-radius: 100%;
          background: var(--skyline-color-accent);
          content: "";
        }

        .tab.active:not(.secondary) {
          border-bottom-color: var(--skyline-color-accent);
        }

        .tab.secondary .icon {
          width: 22px;
          height: 22px;
          display: flex;
          align-items: center;
          justify-content: center;
          position: relative;
          border-radius: 4px;
        }

        .tab.active .icon {
          color: var(--skyline-color-accent);
        }

        .tab.secondary:not(.active):hover .icon {
          background-color: var(--skyline-color-border);
        }
      |}]
end

type 'tab t =
  { current : 'tab
  ; set_current : 'tab -> unit Effect.t
  ; view : Vdom.Node.t
  }

let primary_tab ~active ~notification ~on_click title =
  let title =
    Skyline_text_v1.span
      ~attrs:
        [ Style.title; (if notification then Style.notification else Vdom.Attr.empty) ]
      ~style:Bold
      title
  in
  match active with
  | true -> Vdom.Node.div ~attrs:[ Style.tab; Style.active ] [ title ]
  | false ->
    Vdom.Node.button ~attrs:[ Style.tab; Vdom.Attr.on_click (const on_click) ] [ title ]
;;

let secondary_tab ~active ~notification ~on_click ~tooltip icon =
  let icon =
    Vdom.Node.div
      ~attrs:
        [ Style.icon; (if notification then Style.notification else Vdom.Attr.empty) ]
      [ Codicons.svg ~size:(`Px 16) icon ]
  in
  match active with
  | true ->
    Vdom.Node.div
      ~attrs:[ Style.tab; Style.secondary; Style.active; Skyline_tooltip_v1.text tooltip ]
      [ icon ]
  | false ->
    Vdom.Node.button
      ~attrs:
        [ Vdom.Attr.on_click (const on_click)
        ; Style.tab
        ; Style.secondary
        ; Skyline_tooltip_v1.text tooltip
        ]
      [ icon ]
;;

let component
  (type tab)
  (module Tab : Tab with type t = tab)
  ?state:external_state
  ?notifications
  ?(secondary = Bonsai.return [])
  primary
  (local_ graph)
  =
  let current, set_current =
    match external_state with
    | Some state -> state
    | None ->
      let current, set_current = Bonsai.state ~equal:[%equal: Tab.t option] None graph in
      let current =
        let%arr current and primary in
        match current with
        | Some tab -> tab
        | None -> Nonempty_list.hd primary
      in
      let set_current =
        let%arr set_current in
        fun tab -> set_current (Some tab)
      in
      current, set_current
  in
  Bonsai.Edge.on_change
    ~trigger:`After_display
    ~equal:[%equal: Tab.t Nonempty_list.t]
    (let%arr primary and secondary in
     Nonempty_list.append primary secondary)
    ~callback:
      (let%arr current and set_current in
       fun visible ->
         if not (Nonempty_list.mem visible current ~equal:Tab.equal)
         then set_current (Nonempty_list.hd visible)
         else Effect.return ())
    graph;
  let view =
    let%arr primary
    and secondary
    and notifications = Bonsai.transpose_opt notifications
    and current
    and set_current in
    let has_notification tab =
      match notifications with
      | Some set -> Set.mem set tab
      | None -> false
    in
    let primary =
      View.hbox_wrap
        ~main_axis_alignment:Start
        ~cross_axis_alignment:Center
        ~row_gap:(`Px 8)
        ~column_gap:(`Px 8)
        (Nonempty_list.map primary ~f:(fun tab ->
           let active = Tab.equal tab current in
           let notification = has_notification tab in
           let on_click = set_current tab in
           primary_tab ~active ~notification ~on_click (Tab.label tab))
         |> Nonempty_list.to_list)
    in
    let secondary =
      View.hbox
        ~main_axis_alignment:End
        ~cross_axis_alignment:Center
        ~gap:(`Px 2)
        (List.map secondary ~f:(fun tab ->
           let active = Tab.equal tab current in
           let notification = has_notification tab in
           let tooltip = Tab.label tab in
           let on_click = set_current tab in
           secondary_tab ~active ~notification ~tooltip ~on_click (Tab.icon tab)))
    in
    Vdom.Node.div ~attrs:[ Style.container ] [ primary; secondary ]
  in
  let%arr current and set_current and view in
  { current; set_current; view }
;;

let current { current; _ } = current
let change { set_current; _ } tab = set_current tab
let view { view; _ } = view
