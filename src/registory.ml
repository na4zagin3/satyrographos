open Core

type package_name = string
exception RegisteredAlready of package_name

module StringSet = Set.Make(String)

type t = {
  registory: Store.store;
  repository: Repository.t;
  metadata: Metadata.store;
}

(* Basic operations *)
(* TODO get from metadata*)
let list reg = Store.list reg.registory
let directory reg name = Store.directory reg.registory name
let mem reg name = Store.mem reg.registory name
(* TODO lock *)
let remove_multiple reg names =
  (* TODO remove from metadata *)
  Store.remove_multiple reg.registory names
let remove reg name =
  remove_multiple reg [name]

let build_package reg name =
  match Metadata.mem reg.metadata name with
  | false -> failwith (Printf.sprintf "Package %s is not found" name)
  | true ->
    (* TODO properly build the package *)
    let dir = Repository.directory reg.repository name in
    let package = Package.read_dir dir in
    Package.to_string package |> print_endline;
    Store.remove reg.registory name;
    Store.add_package reg.registory name package

(* TODO build only obsoleted packages *)
let update_all reg =
  let updated_packages = list reg in
  List.iter ~f:(build_package reg) updated_packages;
  Some updated_packages

(* Advanced operations *)
let gc reg =
  let current_packages = list reg |> StringSet.of_list in
  let valid_packages = Metadata.list reg.metadata |> StringSet.of_list in
  let broken_packages = StringSet.diff current_packages valid_packages in
  StringSet.to_list broken_packages
  |> remove_multiple reg

let initialize packages_dir metadata_file =
  Store.initialize packages_dir;
  Metadata.initialize metadata_file

let read package_dir repository metadata_file = {
    registory = Store.read package_dir;
    repository = repository;
    metadata = metadata_file;
  }

(* Tests *)
