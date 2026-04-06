open! Core

let size_2xs = `Px 10
let size_xs = `Px 12
let size_sm = `Px 14
let size_base = `Px 16
let size_lg = `Px 18
let size_xl = `Px 20
let size_2xl = `Px 24
let size_3xl = `Px 30
let size_4xl = `Px 36
let size_5xl = `Px 48
let _size8xl = `Px 64
let line_height_2xs = `Px 12
let line_height_xs = `Px 16
let line_height_sm = `Px 20
let line_height_base = `Px 24
let line_height_lg = `Px 28
let line_height_xl = `Px 28
let line_height_2xl = `Px 32
let line_height_3xl = `Px 36
let line_height_4xl = `Px 40
let line_height_5xl = `Px 48

module Family = struct
  type t = string list

  let sans = [ "Inter"; "sans-serif" ]
  let monospace = [ "Consolas"; "Roboto Mono"; "monospace" ]
  let to_string_css t = String.concat ~sep:", " t
end

module Weight = struct
  type t = int

  let light = 300
  let normal = 400
  let medium = 500
  let semibold = 600
  let bold = 700
  let to_string_css t = Int.to_string t
end
