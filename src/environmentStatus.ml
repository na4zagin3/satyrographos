(*
open Core

let satysfi_opam_registry () =
  OpamWrapper.get_satysfi_opam_registry None
  |> Option.map ~f:OpamFilename.Dir.to_string
*)

let read_opam_environment ?opam_switch () =
  OpamWrapper.read_opam_environment ?opam_switch Environment.empty
