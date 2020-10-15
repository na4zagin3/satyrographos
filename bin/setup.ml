open Satyrographos
open Core

module SatysfiDirs = Satyrographos_satysfi.SatysfiDirs

let scheme_version = 1

(** Home directory. TODO Remove this. *)
let home_dir = match SatysfiDirs.home_dir () with
  | Some(d) -> d
  | None -> failwith "Cannot find home directory"

(** Satyrographos depot directory path. *)
let root_dir = Sys.getenv "SATYROGRAPHOS_DIR"
  |> Option.value ~default:(Filename.concat home_dir ".satyrographos")

(** Satyrographos source repository directory path. *)
let repository_dir = SatyrographosDirs.repository_dir root_dir

(** Satyrographos binary registry directory path. *)
let registry_dir = SatyrographosDirs.registry_dir root_dir
let metadata_file = SatyrographosDirs.metadata_file root_dir

let current_scheme_version = SatyrographosDirs.get_scheme_version root_dir

(* TODO Move this to a new module *)
let depot_initialized = ref false
let depot_exists () =
  match current_scheme_version with
  | None -> false
  | Some 0 -> Printf.sprintf "Semantics of `pin add` has been changed.\nPlease remove %s to continue." root_dir |> failwith
  | Some 1 -> false (* TODO This needs to be true *)
  | Some v -> Printf.sprintf "Unknown scheme version %d" v |> failwith

let initialize () =
  if !depot_initialized || depot_exists ()
  then ()
  else begin
    depot_initialized := true;
    Repository.initialize repository_dir metadata_file;
    Registry.initialize registry_dir metadata_file;
    SatyrographosDirs.mark_scheme_version root_dir scheme_version
  end

let reg_opam =
  SatysfiDirs.opam_share_dir ~outf:Format.std_formatter
  |> Option.bind ~f:(fun opam_share_dir ->
      OpamSatysfiRegistry.read (Filename.concat opam_share_dir "satysfi"))

let try_read_depot () =
  if depot_exists () |> not
  then None
  else begin
    initialize ();
    (* Source repository *)
    let repo = Repository.read repository_dir metadata_file in
    (* Binary registry *)
    let reg = Registry.read registry_dir repo metadata_file in
    Some (Environment.{ repo; reg })
  end

let default_target_dir =
  Sys.getenv "SATYSFI_RUNTIME"
  |> Option.value ~default:(Filename.concat home_dir ".satysfi")
  |> (fun dir -> Filename.concat dir "dist")

let read_environment () =
  let depot = try_read_depot () in
  let dist_library_dir = SatysfiDirs.satysfi_dist_dir ~outf:Format.std_formatter in
  Environment.{ depot; opam_reg = reg_opam; dist_library_dir }

let read_depot_exn () =
  let env = read_environment () in
  env.Environment.depot
  |> Option.value_exn ~message:"Satyrographos directory (e.g., ~/.satyrographs) does not exist."
