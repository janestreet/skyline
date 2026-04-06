open! Core

(** Render a human-readable time span. E.g. [5s] or [4min]. *)
val time_span_hum : Time_ns.Span.t -> string

(** Render a human-readable date. E.g. [2023-11-20]. *)
val date_hum : Time_ns.t -> string

(** Render a point in time. E.g. [in 5min], [3s ago], [2023-04-05]. *)
val time_hum : now:Time_ns.t -> Time_ns.t -> string
