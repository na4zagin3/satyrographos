open Satyrographos
open Core

module SatysfiDirs = Satyrographos_satysfi.SatysfiDirs

(** Home directory. TODO Remove this. *)
let home_dir = match SatysfiDirs.home_dir () with
  | Some(d) -> d
  | None -> failwith "Cannot find home directory"

let reg_opam =
  SatysfiDirs.opam_share_dir ~outf:Format.std_formatter
  |> Option.bind ~f:(fun opam_share_dir ->
      OpamSatysfiRegistry.read (Filename.concat opam_share_dir "satysfi"))

let default_target_dir =
  Sys.getenv "SATYSFI_RUNTIME"
  |> Option.value ~default:(Filename.concat home_dir ".satysfi")
  |> (fun dir -> Filename.concat dir "dist")

let read_environment () =
  let dist_library_dir = SatysfiDirs.satysfi_dist_dir ~outf:Format.std_formatter in
  Environment.{ opam_reg = reg_opam; dist_library_dir }

