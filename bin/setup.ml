open Satyrographos
open Core

let scheme_version = 1

let home_dir = match SatysfiDirs.home_dir () with
  | Some(d) -> d
  | None -> failwith "Cannot find home directory"

let root_dir = Sys.getenv "SATYROGRAPHOS_DIR"
  |> Option.value ~default:(Filename.concat home_dir ".satyrographos")
let repository_dir = SatyrographosDirs.repository_dir root_dir
let library_dir = SatyrographosDirs.library_dir root_dir
let metadata_file = SatyrographosDirs.metadata_file root_dir

let current_scheme_version = SatyrographosDirs.get_scheme_version root_dir

(* TODO Move this to a new module *)
let repo_initialized = ref false
let repository_exists () =
  match current_scheme_version with
  | None -> false
  | Some 0 -> Printf.sprintf "Semantics of `pin add` has been changed.\nPlease remove %s to continue." root_dir |> failwith
  | Some 1 -> false
  | Some v -> Printf.sprintf "Unknown scheme version %d" v |> failwith

let initialize () =
  if !repo_initialized || repository_exists ()
  then ()
  else begin
    repo_initialized := true;
    Repository.initialize repository_dir metadata_file;
    Registry.initialize library_dir metadata_file;
    SatyrographosDirs.mark_scheme_version root_dir scheme_version
  end

type repo = {
  repo: Repository.t;
  reg: Registry.t;
}

let reg_opam =
  SatysfiDirs.opam_share_dir ()
  |> Option.map ~f:(fun opam_share_dir ->
      OpamSatysfiRegistry.read (Filename.concat opam_share_dir "satysfi"))

let try_read_repo () =
  if repository_exists () |> not
  then None
  else begin
    initialize ();
    (* Source repository *)
    let repo = Repository.read repository_dir metadata_file in
    (* Binary registry *)
    let reg = Registry.read library_dir repo metadata_file in
    Some { repo; reg }
  end

let read_repo () =
  if repository_exists () |> not
  then initialize ();
  match try_read_repo () with
  | None -> failwith "BUG: Something went wrong."
  | Some r -> r

let default_target_dir =
  Sys.getenv "SATYSFI_RUNTIME"
  |> Option.value ~default:(Filename.concat home_dir ".satysfi")
  |> (fun dir -> Filename.concat dir "dist")
