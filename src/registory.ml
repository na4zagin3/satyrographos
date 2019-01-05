open Core

type package_name = string
exception RegisteredAlready of package_name

module StringSet = Set.Make(String)

type t = {
  registory: RegistoryStore.store;
  metadata: RegistoryMetadata.store;
}

(* Basic operations *)
let list reg = RegistoryMetadata.list reg.metadata
(* TODO get data from metadata *)
let directory reg name = RegistoryStore.directory reg.registory name
let mem reg name = RegistoryMetadata.mem reg.metadata name
(* TODO lock *)
let remove_multiple reg names =
  RegistoryMetadata.remove_multiple reg.metadata names;
  RegistoryStore.remove_multiple reg.registory names
let remove reg name =
  remove_multiple reg [name]

let add_dir reg name dir =
  let abs_dir = Filename.realpath dir in
  let uri = Uri.make ~scheme:"file" ~path:abs_dir () in
  (* RegistoryStore.add_dir reg.registory name dir;  *)
  RegistoryMetadata.add reg.metadata name {
    url = uri;
  }

let build_package reg name =
  match RegistoryMetadata.find reg.metadata name with
  | None -> failwith (Printf.sprintf "Package %s is not found" name)
  | Some metadata ->
    let dir = Uri.path metadata.url in
    let package = Package.read_dir dir in
    [%derive.show: Package.t] package |> print_endline;
    RegistoryStore.remove reg.registory name;
    RegistoryStore.add_package reg.registory name package

(* TODO build only obsoleted packages *)
let update_all reg =
  let updated_packages = list reg in
  List.iter ~f:(build_package reg) updated_packages;
  Some updated_packages

(* Advanced operations *)
(* TODO Implement lock *)
let add reg name uri =
  if RegistoryMetadata.mem reg.metadata name
  then failwith (Printf.sprintf "%s is already registered." name)
  else begin match Uri.scheme uri with
    | None | Some "file" ->
      let path = Uri.path uri in
      Printf.printf "Installing %s.\n" path;
      add_dir reg name path
    | Some s ->
      failwith (Printf.sprintf "Unknown scheme %s." s)
  end;
  update_all reg

let gc reg =
  let current_packages = list reg |> StringSet.of_list in
  let valid_packages = RegistoryMetadata.list reg.metadata |> StringSet.of_list in
  let broken_packages = StringSet.diff current_packages valid_packages in
  StringSet.to_list broken_packages
  |> remove_multiple reg

let initialize packages_dir metadata_file =
  RegistoryStore.initialize packages_dir;
  RegistoryMetadata.initialize metadata_file

let read package_dir metadata_file = {
    registory = RegistoryStore.read package_dir;
    metadata = metadata_file;
  }

(* Tests *)
