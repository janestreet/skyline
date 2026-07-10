open Skyline_picker_v2_typeahead_search_worker_protocol
module Worker_state = Skyline_picker_v2_typeahead_search_worker_state

let () =
  let t = Worker_state.create ~post_message:From_worker.post_message () in
  Js_of_ocaml.Worker.set_onmessage (fun message -> Worker_state.handle_message t message)
;;
