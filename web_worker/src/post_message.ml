open! Core
open! Js_of_ocaml

class type ['message, 'transfer] t = object
  method _postMessage :
    message:'message -> transfer:'transfer Js.js_array Js.t -> unit Js.meth
end

let post_message (t : ('message, 'transfer) #t Js.t) ~message ~transfer : unit =
  t##_postMessage ~message ~transfer:(Js.array transfer)
;;

let from_worker () : _ t Js.t = Js.Unsafe.coerce Js.Unsafe.global

class type ['message, 'response, 'transfer] to_worker = object
  inherit ['message, 'response] Js_of_ocaml.Worker.worker
  inherit ['message, 'transfer] t
end

let to_worker
  :  ('message, 'response) #Js_of_ocaml.Worker.worker Js.t
  -> ('message, 'response, 'transfer) to_worker Js.t
  =
  Js.Unsafe.coerce
;;
