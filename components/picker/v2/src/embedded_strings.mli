open! Core

(** This file is just a place to put large [%embed_file_as_string] uses so that
    [ocaml-ir-show-ppx] et alia remain usable in the files where those embedded strings
    get used. Otherwise, the embedded contents can easily be the vast majority of the
    post-expansion file, which makes them very hard to read. *)

module For_worker_filter : sig
  val worker_blob_js : string
end
