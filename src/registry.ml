open Core

type library_name = string
exception RegisteredAlready of library_name

module StringSet = Set.Make(String)

type t = {
  registry: Store.store; (* Stores compiled blob *)
  repository: Repository.t; (* Stores sources *)
  metadata: Metadata.store;
}

(* Basic operations *)
(* TODO get from metadata*)
let list reg = Store.list reg.registry
let directory reg name = Store.directory reg.registry name
let mem reg name = Store.mem reg.registry name
(* TODO lock *)
let remove_multiple reg names =
  (* TODO remove from metadata *)
  Store.remove_multiple reg.registry names
let remove reg name =
  remove_multiple reg [name]

let build_library ~outf reg name =
  match Metadata.mem reg.metadata name with
  | false -> failwith (Printf.sprintf "Library %s is not found" name)
  | true ->
    (* TODO properly build the library *)
    let dir = Repository.directory reg.repository name in
    let library = Library.read_dir ~outf dir in
    Library.to_string library |> print_endline;
    Store.remove reg.registry name;
    Store.add_library ~outf reg.registry name library

(* TODO build only obsoleted libraries *)
let update_all ~outf reg =
  let updated_libraries = list reg in
  List.iter ~f:(build_library ~outf reg) updated_libraries;
  Some updated_libraries

(* Advanced operations *)
let gc reg =
  let current_libraries = list reg |> StringSet.of_list in
  let valid_libraries = Metadata.list reg.metadata |> StringSet.of_list in
  let broken_libraries = StringSet.diff current_libraries valid_libraries in
  StringSet.to_list broken_libraries
  |> remove_multiple reg

let initialize libraries_dir metadata_file =
  Store.initialize libraries_dir;
  Metadata.initialize metadata_file

let read library_dir repository metadata_file = {
    registry = Store.read library_dir;
    repository = repository;
    metadata = metadata_file;
  }

(* Tests *)
