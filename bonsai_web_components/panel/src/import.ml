include Bonsai_web
include Bonsai.Let_syntax
include Vdom
include Composition_infix

include struct
  open Js_of_ocaml
  module Js = Js
  module N = Vdom.Node
  module A = Vdom.Attr
end
