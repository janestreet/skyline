open! Core
open! Bonsai_web
open! Bonsai.Let_syntax

let by_extension filename =
  match Filename.split_extension filename with
  | _, Some extension -> Map.find Seti_icons.by_file_extension ("." ^ extension)
  | _, None -> None
;;

let by_basename filename =
  Map.find Seti_icons.by_file_extension (Filename.basename filename)
;;

let by_filename filename =
  match by_extension filename with
  | Some _ as icon -> icon
  | None -> by_basename filename
;;

let component ?(size = `Px 24) filename =
  match by_filename filename with
  | Some (icon, color) -> Seti_icons.svg ~color ~size icon
  | None -> Seti_icons.svg ~color:(`Name "currentColor") ~size Default
;;
