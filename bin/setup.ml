open Satyrographos
open Core

module SatysfiDirs = Satyrographos_satysfi.SatysfiDirs

(** Home directory. TODO Remove this. *)
let home_dir = match SatysfiDirs.home_dir () with
  | Some(d) -> d
  | None -> failwith "Cannot find home directory"

let default_target_dir =
  Sys.getenv "SATYSFI_RUNTIME"
  |> Option.value ~default:(Filename.concat home_dir ".satysfi")
  |> (fun dir -> Filename.concat dir "dist")

let read_environment ?opam_switch () =
  let outf = Format.std_formatter in
  let opam_switch = match opam_switch with
    | Some _ -> opam_switch
    | None ->
      let dir = OpamFilename.cwd () in
      (* TODO Read switch relative to Satyristes *)
      Option.some_if (OpamWrapper.exists_switch_at_dir dir) (OpamSwitch.of_dirname dir)
  in
  let env = EnvironmentStatus.read_opam_environment ~outf ?opam_switch () in
  SatysfiDirs.read_satysfi_env ~outf env

