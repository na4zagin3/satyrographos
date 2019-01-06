open Core

type package_name = string
exception RegisteredAlready of package_name

module StringSet = Set.Make(String)

type t = {
  cache: Store.store;
  metadata: Metadata.store;
}

(* Basic operations *)
let list reg = Metadata.list reg.metadata
(* TODO get data from metadata *)
let directory reg name = Store.directory reg.cache name
let mem reg name = Metadata.mem reg.metadata name
(* TODO lock *)
let remove_multiple reg names =
  Metadata.remove_multiple reg.metadata names;
  Store.remove_multiple reg.cache names
let remove reg name =
  remove_multiple reg [name]

let add_dir reg name dir =
  let abs_dir = Filename.realpath dir in
  let uri = Uri.make ~scheme:"file" ~path:abs_dir () in
  (* Store.add_dir reg.cache name dir;  *)
  Metadata.add reg.metadata name {
    url = uri;
  }

let update reg name =
  match Metadata.find reg.metadata name with
  | None -> failwith (Printf.sprintf "Package %s is not found" name)
  | Some metadata -> begin match Uri.scheme metadata.url with
    | Some "file" ->
      let dir = Uri.path metadata.url in
      let package = Package.read_dir dir in
      Package.to_string package |> print_endline;
      Store.remove reg.cache name;
      Store.add_package reg.cache name package
    | None ->
      failwith (Printf.sprintf "BUG: URL scheme of package %s is unknown." name)
    | Some s ->
      failwith (Printf.sprintf "Unknown scheme %s." s)
  end

(* TODO build only obsoleted packages *)
let update_all reg =
  let updated_packages = list reg in
  List.iter ~f:(update reg) updated_packages;
  Some updated_packages

(* Advanced operations *)
(* TODO Implement lock *)
let add reg name uri =
  if Metadata.mem reg.metadata name
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
  let valid_packages = Metadata.list reg.metadata |> StringSet.of_list in
  let broken_packages = StringSet.diff current_packages valid_packages in
  StringSet.to_list broken_packages
  |> remove_multiple reg

let initialize packages_dir metadata_file =
  Store.initialize packages_dir;
  Metadata.initialize metadata_file

let read package_dir metadata_file = {
    cache = Store.read package_dir;
    metadata = metadata_file;
  }

(* Tests *)
