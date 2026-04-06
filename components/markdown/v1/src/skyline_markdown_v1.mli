open! Core
open! Bonsai_web

(** A markdown parser and rendered that looks good when embedded within a Skyline app. *)

module Code_block_style : sig
  type t =
    | Block
    | Inline
end

(** Parse and render a markdown document. If the document is large, you should consider
    embedding this within a [Bonsai.t] to avoid re-computing it unless the markdown
    document changes. *)
val component : ?code_block_style:Code_block_style.t -> string -> Vdom.Node.t
