open! Core

let time_span_hum span =
  Time_ns.Span.to_int_sec span
  |> Time_ns.Span.of_int_sec
  |> Time_ns.Span.(max second)
  |> Time_ns.Span.to_short_string
;;

let date_hum time =
  let zone =
    try Some (force Timezone.local) with
    | _ -> None
  in
  let date, utc_suffix =
    match zone with
    | Some zone -> Time_ns.to_date time ~zone, ""
    | None -> Time_ns.to_date time ~zone:Timezone.utc, " UTC"
  in
  [%string
    "%{Date.day date#Int} %{Date.month date#Month} %{Date.year date#Int}%{utc_suffix}"]
;;

let time_hum ~now time =
  let span = Time_ns.abs_diff time now in
  if Time_ns.Span.(of_day 7. < span)
  then date_hum time
  else if Time_ns.Span.(abs span < Time_ns.Span.second)
  then "now"
  else if Time_ns.( < ) time now
  then [%string "%{time_span_hum span} ago"]
  else [%string "in %{time_span_hum span}"]
;;
