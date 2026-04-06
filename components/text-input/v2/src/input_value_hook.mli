open! Core
open! Bonsai_web

(** A hook that decouples the model value from the DOM input value.

    This hook solves the problem where typing partial input (like "1." for a float) causes
    the input to immediately parse to "1", preventing the user from continuing to type. It
    also allows for filtering to prevent invalid values from being typed or copy/pasted
    in.

    NOTE: No-op if not attached to an [input] element.

    - [filter_input] is called on_input, and if it returns [false], the input is reverted
      to its previous value. This is useful for rejecting inputs that can never become
      valid (e.g. "." might become a valid Float, but ".." or ".a" never will be).
    - [parse] is called on the input's current text when the user blurs or presses enter,
      and also on input to determine whether to update external state. It should return
      [Some parsed_string] if the input is valid, or [None] if the input is incomplete or
      invalid. NOTE: [parse] should be idempotent, i.e. parse (parse s) shouldn't return a
      different value than (parse s).
    - [state] represents the string state of the text in the input. *)
val create
  :  ?filter_input:(string -> bool)
  -> ?parse:(string -> string option)
  -> state:string * (string -> unit Effect.t)
  -> unit
  -> Vdom.Attr.t
