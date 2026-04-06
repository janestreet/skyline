open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

type 'a t = 'a option Skyline_input_v1.t

let picker_icon =
  [%css
    {|
      padding: 0 0 0 4px;

      &::-webkit-calendar-picker-indicator {
        display: block;
        width: 24px;
        height: 24px;
        margin: 0;
        background-color: var(--skyline-color-border);
        background-size: 16px 16px;
        background-position: center;
        background-repeat: no-repeat;
      }
    |}]
;;

(* We want the date-picker icons to respect the color theme, so we need to override the
   default icon by setting a custom background image.

   The icons are the calendar/clock pulled from [Codicons] with fill color being the
   light/dark themes primary colors. *)

let calendar_icon_light =
  [%css
    {|
      &::-webkit-calendar-picker-indicator {
        background-image: url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNnB4IiBoZWlnaHQ9IjE2cHgiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0iIzNCM0IzQiIgc3R5bGU9ImZsZXgtc2hyaW5rOiAwOyBvdmVyZmxvdzogdmlzaWJsZTsiPjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgY2xpcC1ydWxlPSJldmVub2RkIiBkPSJNMTQuNSAySDEzVjFoLTF2MUg0VjFIM3YxSDEuNWwtLjUuNXYxMmwuNS41aDEzbC41LS41di0xMmwtLjUtLjV6TTE0IDE0SDJWNWgxMnY5em0wLTEwSDJWM2gxMnYxek00IDhIM3YxaDFWOHptLTEgMmgxdjFIM3YtMXptMSAySDN2MWgxdi0xem0yLTRoMXYxSDZWOHptMSAySDZ2MWgxdi0xem0tMSAyaDF2MUg2di0xem0xLTZINnYxaDFWNnptMiAyaDF2MUg5Vjh6bTEgMkg5djFoMXYtMXptLTEgMmgxdjFIOXYtMXptMS02SDl2MWgxVjZ6bTIgMmgxdjFoLTFWOHptMSAyaC0xdjFoMXYtMXptLTEtNGgxdjFoLTFWNnoiPjwvcGF0aD48L3N2Zz4=");
      }
    |}]
;;

let calendar_icon_dark =
  [%css
    {|
      &::-webkit-calendar-picker-indicator {
        background-image: url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNnB4IiBoZWlnaHQ9IjE2cHgiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0iI0Q0RDRENCIgc3R5bGU9ImZsZXgtc2hyaW5rOiAwOyBvdmVyZmxvdzogdmlzaWJsZTsiPjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgY2xpcC1ydWxlPSJldmVub2RkIiBkPSJNMTQuNSAySDEzVjFoLTF2MUg0VjFIM3YxSDEuNWwtLjUuNXYxMmwuNS41aDEzbC41LS41di0xMmwtLjUtLjV6TTE0IDE0SDJWNWgxMnY5em0wLTEwSDJWM2gxMnYxek00IDhIM3YxaDFWOHptLTEgMmgxdjFIM3YtMXptMSAySDN2MWgxdi0xem0yLTRoMXYxSDZWOHptMSAySDZ2MWgxdi0xem0tMSAyaDF2MUg2di0xem0xLTZINnYxaDFWNnptMiAyaDF2MUg5Vjh6bTEgMkg5djFoMXYtMXptLTEgMmgxdjFIOXYtMXptMS02SDl2MWgxVjZ6bTIgMmgxdjFoLTFWOHptMSAyaC0xdjFoMXYtMXptLTEtNGgxdjFoLTFWNnoiPjwvcGF0aD48L3N2Zz4=");
      }
    |}]
;;

let clock_icon_light =
  [%css
    {|
      &::-webkit-calendar-picker-indicator {
        background-image: url("data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiBmaWxsPSIjM0IzQjNCIiBzdHlsZT0iZmxleC1zaHJpbms6MDsgb3ZlcmZsb3c6IHZpc2libGU7Ij4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik04IDE0QzExLjMxMzcgMTQgMTQgMTEuMzEzNyAxNCA4QzE0IDQuNjg2MjkgMTEuMzEzNyAyIDggMkM0LjY4NjI5IDIgMiA0LjY4NjI5IDIgOEMyIDExLjMxMzcgNC42ODYyOSAxNCA4IDE0Wk04IDE1QzExLjg2NiAxNSAxNSAxMS44NjYgMTUgOEMxNSA0LjEzNDAxIDExLjg2NiAxIDggMUM0LjEzNDAxIDEgMSA0LjEzNDAxIDEgOEMxIDExLjg2NiA0LjEzNDAxIDE1IDggMTVaIiAvPgo8cGF0aCBkPSJNMTAuODU0IDEwLjY0N0wxMC4xNDYgMTEuMzU0TDcuMTQ2IDguMzU0TDcgOFY0SDhWNy43OTJMMTAuODU0IDEwLjY0N1oiIC8+Cjwvc3ZnPgo=");
      }
    |}]
;;

let clock_icon_dark =
  [%css
    {|
      &::-webkit-calendar-picker-indicator {
        background-image: url("data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiBmaWxsPSIjRDRENEQ0IiBzdHlsZT0iZmxleC1zaHJpbms6MDsgb3ZlcmZsb3c6IHZpc2libGU7Ij4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik04IDE0QzExLjMxMzcgMTQgMTQgMTEuMzEzNyAxNCA4QzE0IDQuNjg2MjkgMTEuMzEzNyAyIDggMkM0LjY4NjI5IDIgMiA0LjY4NjI5IDIgOEMyIDExLjMxMzcgNC42ODYyOSAxNCA4IDE0Wk04IDE1QzExLjg2NiAxNSAxNSAxMS44NjYgMTUgOEMxNSA0LjEzNDAxIDExLjg2NiAxIDggMUM0LjEzNDAxIDEgMSA0LjEzNDAxIDEgOEMxIDExLjg2NiA0LjEzNDAxIDE1IDggMTVaIiAvPgo8cGF0aCBkPSJNMTAuODU0IDEwLjY0N0wxMC4xNDYgMTEuMzU0TDcuMTQ2IDguMzU0TDcgOFY0SDhWNy43OTJMMTAuODU0IDEwLjY0N1oiIC8+Cjwvc3ZnPgo=");
      }
    |}]
;;

let common_attrs
  ~to_string
  ?test_selector
  ?min
  ?max
  ?(disabled = return false)
  ?(autofocus = return false)
  graph
  =
  let input_id = Bonsai.path_id graph in
  let%arr input_id
  and test_selector = Bonsai.transpose_opt test_selector
  and min = Bonsai.transpose_opt min
  and max = Bonsai.transpose_opt max
  and disabled
  and autofocus =
    match%arr autofocus with
    | true -> Private_skyline_autofocus.focus_on_mount
    | false -> Vdom.Attr.empty
  in
  let maybe_disabled =
    if disabled
    then Vdom.Attr.many [ [%css {|cursor: not-allowed;|}]; Vdom.Attr.disabled ]
    else Vdom.Attr.empty
  in
  let min_attr =
    Option.value_map
      ~f:(Fn.compose (Vdom.Attr.create "min") to_string)
      min
      ~default:Vdom.Attr.empty
  in
  let max_attr =
    Option.value_map
      ~f:(Fn.compose (Vdom.Attr.create "max") to_string)
      max
      ~default:Vdom.Attr.empty
  in
  [ Vdom.Attr.id input_id
  ; min_attr
  ; max_attr
  ; autofocus
  ; maybe_disabled
  ; picker_icon
  ; Test_selector.attr_of_opt test_selector
  ; Skyline_text_input_v1.Expert.style
  ]
;;

let clamp compare ~min ~max value =
  (* [clamp] does exist for all types we want to use, also we don't want to crash the
     whole app when given invalid bounds. *)
  match min, max with
  | Some min, _ when compare value min < 0 -> min
  | _, Some max when compare value max > 0 -> max
  | _ -> value
;;

let date ?test_selector ?state:external_state ?min ?max ?disabled ?autofocus graph =
  let value, update =
    match external_state with
    | Some state -> state
    | None -> Bonsai.state None graph
  in
  let update =
    let%arr update
    and min = Bonsai.transpose_opt min
    and max = Bonsai.transpose_opt max in
    fun value ->
      update (Option.map value ~f:(fun value -> clamp Date.compare ~min ~max value))
  in
  let view =
    let attrs =
      common_attrs
        ?test_selector
        ?min
        ?max
        ?disabled
        ?autofocus
        ~to_string:Date.to_string
        graph
    and picker_icon_detail =
      let%arr theme = Skyline_entrypoint.theme graph in
      let is_dark_theme =
        match theme with
        | Dark -> true
        | Light -> false
        | Vscode { is_dark } -> is_dark
      in
      if is_dark_theme then calendar_icon_dark else calendar_icon_light
    in
    let%arr attrs and picker_icon_detail and value and update in
    Vdom_input_widgets.Entry.date
      ~extra_attrs:(picker_icon_detail :: attrs)
      ~value
      ~on_input:update
      ()
  in
  Skyline_input_v1.create view value update
;;

let ofday_to_string_hhmmss ofday =
  let { Time_ns.Span.Parts.hr; min; sec; _ } = Time_ns.Ofday.to_parts ofday in
  sprintf "%02d:%02d:%02d" hr min sec
;;

let time ?test_selector ?state:external_state ?min ?max ?disabled ?autofocus graph =
  let value, update =
    match external_state with
    | Some state -> state
    | None -> Bonsai.state None graph
  in
  let update =
    let%arr update
    and min = Bonsai.transpose_opt min
    and max = Bonsai.transpose_opt max in
    fun value ->
      update
        (Option.map value ~f:(fun value -> clamp Time_ns.Ofday.compare ~min ~max value))
  in
  let view =
    let attrs =
      common_attrs
        ?test_selector
        ?min
        ?max
        ?disabled
        ?autofocus
        ~to_string:ofday_to_string_hhmmss
        graph
    and picker_icon_detail =
      let%arr theme = Skyline_entrypoint.theme graph in
      let is_dark_theme =
        match theme with
        | Dark -> true
        | Light -> false
        | Vscode { is_dark } -> is_dark
      in
      if is_dark_theme then clock_icon_dark else clock_icon_light
    in
    let%arr attrs and picker_icon_detail and value and update in
    Vdom_input_widgets.Entry.time
      ~extra_attrs:(picker_icon_detail :: attrs)
      ~allow_updates_when_focused:`Never
        (* time input specifically has issues when it's set while focused, so we never set
           it. *)
      ~value
      ~on_input:update
      ()
  in
  Skyline_input_v1.create view value update
;;

let date_time ?test_selector ?state:external_state ?min ?max ?disabled ?autofocus graph =
  let to_string time_ns =
    (* datetime-local value format is YYYY-MM-DDTHH:mm:ss *)
    let date, of_day = Time_ns.to_date_ofday ~zone:(force Timezone.local) time_ns in
    sprintf !"%{Date}T%{ofday_to_string_hhmmss}" date of_day
  in
  let value, update =
    match external_state with
    | Some state -> state
    | None -> Bonsai.state None graph
  in
  let update =
    let%arr update
    and min = Bonsai.transpose_opt min
    and max = Bonsai.transpose_opt max in
    fun value ->
      update (Option.map value ~f:(fun value -> clamp Time_ns.compare ~min ~max value))
  in
  let view =
    let attrs =
      common_attrs ?test_selector ?min ?max ?disabled ?autofocus ~to_string graph
    and picker_icon_detail =
      let%arr theme = Skyline_entrypoint.theme graph in
      let is_dark_theme =
        match theme with
        | Dark -> true
        | Light -> false
        | Vscode { is_dark } -> is_dark
      in
      if is_dark_theme then calendar_icon_dark else calendar_icon_light
    in
    let%arr attrs and picker_icon_detail and value and update in
    Vdom_input_widgets.Entry.datetime_local
      ~extra_attrs:(picker_icon_detail :: attrs)
      ~value
      ~on_input:update
      ()
  in
  Skyline_input_v1.create view value update
;;

let view input = Skyline_input_v1.view input
let value input = Skyline_input_v1.value input
let update input new_value = Skyline_input_v1.update input new_value
