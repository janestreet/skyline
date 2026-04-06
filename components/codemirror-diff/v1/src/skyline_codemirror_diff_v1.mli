open! Core

(** A Codemirror extension that renders a diff of the editor state vs [original]. When
    [context] is [Some lines], the document contents that are beyond the context will be
    hidden. *)
val changes
  :  keep_ws:bool
  -> context:int option
  -> original:string
  -> Codemirror.State.Extension.t

(** A pair of codemirror extensions that can render a side-by-side diff in two differerent
    editors.

    This will add spacing to align both sides, assuming the other editors contents match
    the provided value. *)
val side_by_side
  :  ?report_error:(unit Or_error.t -> unit Bonsai.Effect.t)
  -> keep_ws:bool
  -> context:int option
  -> other_side:string
  -> [ `Left | `Right ]
  -> Codemirror.State.Extension.t

(** Renders all lines with a green background, matching the way added lines are rendered
    by [changes]. *)
val all_added : Codemirror.State.Extension.t Lazy.t

(** Renders all lines with a red background, matching the way deleted lines are rendered
    by [changes]. *)
val all_deleted : Codemirror.State.Extension.t Lazy.t
