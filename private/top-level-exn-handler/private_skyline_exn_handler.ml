open! Core
open! Js_of_ocaml

let async_main_monitor_handler = ref ignore

let () =
  Async_kernel.Monitor.detach_and_iter_errors Async_kernel.Monitor.main ~f:(fun exn ->
    !async_main_monitor_handler (Async_kernel.Monitor.extract_exn exn))
;;

let handle_top_level_exn exn =
  (Js.Unsafe.coerce Dom_html.document##.documentElement)##replaceChildren
    (Virtual_dom.Vdom.Node.to_dom (Error_page.view exn))
  |> (ignore : _ Js.t -> unit)
;;

let set_uncaught_exception_handler () =
  (Stdlib.Printexc.set_uncaught_exception_handler [@ocaml.alert "-unsafe_multidomain"])
    (fun exn backtrace ->
       handle_top_level_exn exn;
       Stdlib.Printexc.default_uncaught_exception_handler exn backtrace);
  async_main_monitor_handler := handle_top_level_exn
;;

let remove_uncaught_exception_handler () =
  (Stdlib.Printexc.set_uncaught_exception_handler [@ocaml.alert "-unsafe_multidomain"])
    Stdlib.Printexc.default_uncaught_exception_handler;
  async_main_monitor_handler := ignore
;;
