open! Core
open! Bonsai_web

module Input = struct
  type t = unit [@@deriving sexp_of]

  let combine () () = ()
end

module State = Unit

let init () _ = ()

let on_mount =
  `Schedule_immediately_after_this_dom_patch_completes (fun () () elem -> elem##focus)
;;

let update ~old_input:() ~new_input:() () _ = ()
let destroy () () _ = ()

include functor Vdom.Attr.Hooks.Make

let focus_on_mount = Vdom.Attr.create_hook "skyline-focus-on-mount" (create ())
