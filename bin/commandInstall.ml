open Satyrographos
open Core

open Setup

module StringSet = Set.Make(String)

(* TODO Abstract this *)
module StringMap = Map.Make(String)

let transitive_closure map =
  let rec f visited queue = match StringSet.choose queue with
    | None -> visited
    | Some cur ->
      match Map.find map cur with
      | None -> failwithf "Library %s is not found\n" cur ();
      | Some nexts ->
        let visited = StringSet.add visited cur in
        let queue =  StringSet.union (StringSet.remove queue cur) (StringSet.diff nexts visited) in
        f visited queue in
  f StringSet.empty


(* TODO Install transitive dependencies *)
let get_libraries ~reg ~reg_opam ~libraries =
  let dist_library_dir = SatysfiDirs.satysfi_dist_dir () in
  Printf.printf "Reading runtime dist: %s\n" dist_library_dir;
  let dist_library = Library.read_dir dist_library_dir in
  let user_libraries = Registry.list reg
    |> StringSet.of_list
    |> StringSet.to_map ~f:(Registry.directory reg)
  in
  Printf.printf "Read user libraries: %s\n" (user_libraries |> Map.keys |> [%sexp_of: string list] |> Sexp.to_string_hum);
  let opam_libraries = match reg_opam with
    | None -> StringSet.to_map StringSet.empty ~f:ident
    | Some reg_opam ->
        SatysfiRegistry.list reg_opam
        |> StringSet.of_list
        |> StringSet.to_map ~f:(SatysfiRegistry.directory reg_opam)
  in
  Printf.printf "Reading opam libraries: %s\n" (opam_libraries |> Map.keys |> [%sexp_of: string list] |> Sexp.to_string_hum);
  let all_libraries =
    Map.merge opam_libraries user_libraries ~f:(fun ~key -> function
      | `Left x -> Library.read_dir x |> Some
      | `Right x -> Library.read_dir x |> Some
      | `Both (_, x) ->
        Printf.printf "Library %s is provided by both the user local and opam repositories\n" key;
        Library.read_dir x |> Some) in
  let required_libraries = match libraries with
    | None -> all_libraries
    | Some libraries -> let library_dependency =
          Map.map all_libraries ~f:(fun p -> p.Library.dependencies) in
        let libraries_to_install = transitive_closure library_dependency (StringSet.of_list libraries) in
        Map.filter_keys all_libraries ~f:(StringSet.mem libraries_to_install)
  in
  match Map.add required_libraries ~key:"dist" ~data:dist_library with
    | `Ok result -> result
    | `Duplicate ->
      Printf.printf "Overriding dist with user installed one";
      required_libraries

let install d ~system_font_prefix ~libraries ~verbose ~copy () =
  (* TODO build all *)
  Printf.printf "Updating libraries\n";
  begin match Repository.update_all repo with
  | Some updated_libraries -> begin
    Printf.printf "Updated libraries: ";
    [%derive.show: string list] updated_libraries |> print_endline
  end
  | None ->
    Printf.printf "No libraries updated\n"
  end;
  Printf.printf "Building updated libraries\n";
  begin match Registry.update_all reg with
  | Some updated_libraries -> begin
    Printf.printf "Built libraries: ";
    [%derive.show: string list] updated_libraries |> print_endline
  end
  | None ->
    Printf.printf "No libraries built\n"
  end;
  let library_map = get_libraries ~reg ~reg_opam ~libraries in
  let libraries = library_map |> Map.data in
  Printf.printf "Installing libraries: ";
  Map.keys library_map |> [%sexp_of: string list] |> Sexp.to_string_hum |> print_endline;
  let libraries = match system_font_prefix with
    | None -> Printf.printf "Not gathering system fonts\n"; libraries
    | Some(prefix) ->
      Printf.printf "Gathering system fonts with prefix %s\n" prefix;
      let systemFontLibrary = SystemFontLibrary.get_library prefix () in
      List.cons systemFontLibrary libraries
  in
  let merged = libraries
    |> List.fold_left ~f:Library.union ~init:Library.empty
  in
  match FileUtil.test FileUtil.Is_dir d, Library.is_managed_dir d with
  | true, false ->
    Printf.printf "Directory %s is not managed by Satyrographos.\n" d;
    Printf.printf "Please remove %s first.\n" d
  | _, _ ->
    Printf.printf "Removing destination %s\n" d;
    FileUtil.(rm ~force:Force ~recurse:true [d]);
    Library.mark_managed_dir d;
    if verbose
    then begin
      Printf.printf "Loaded libraries\n";
      [%sexp_of: Library.t list] libraries
      |> Sexp.to_string_hum
      |> print_endline;
      Printf.printf "Installing %s\n" d;
      [%sexp_of: Library.t] merged
      |> Sexp.to_string_hum
      |> print_endline
    end;
    Library.write_dir ~symlink:(not copy) d merged;
    List.iter ~f:(Printf.printf "WARNING: %s") (Library.validate merged);
    Printf.printf "Installation completed!\n"

let install_command =
  let open Command.Let_syntax in
  let readme () =
    sprintf "Install SATySFi Libraries to a directory environmental variable SATYSFI_RUNTIME has or %s. Currently it accepts an argument DIR, but this is experimental." default_target_dir
  in
  Command.basic
    ~summary:"Install SATySFi runtime"
    ~readme
    [%map_open
      let system_font_prefix = flag "system-font-prefix" (optional string) ~doc:"FONT_NAME_PREFIX Installing system fonts with names with the given prefix"
      and library_list = flag "library" (listed string) ~doc:"LIBRARY Library"
      and target_dir = anon (maybe_with_default default_target_dir ("DIR" %: string))
      and verbose = flag "verbose" no_arg ~doc:"Make verbose"
      and copy = flag "copy" no_arg ~doc:"Copy files instead of making symlinks"
      in
      fun () ->
        let libraries = match library_list with
          | [] -> None
          | xs -> Some xs in
        install target_dir ~system_font_prefix ~libraries ~verbose ~copy ()
    ]
