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

let read_environment () =
  let outf = Format.std_formatter in
  let env = EnvironmentStatus.read_opam_environment () in
  Format.(fprintf std_formatter !"env: %{sexp: Environment.t}\n" env);
  SatysfiDirs.read_satysfi_env ~outf env

