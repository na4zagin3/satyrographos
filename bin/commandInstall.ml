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
let get_libraries ~maybe_reg ~reg_opam ~libraries =
  let dist_library_dir = SatysfiDirs.satysfi_dist_dir () in
  Format.printf "Reading runtime dist: %s\n" dist_library_dir;
  let dist_library = Library.read_dir dist_library_dir in
  let user_libraries = Option.map maybe_reg ~f:(fun reg -> Registry.list reg
    |> StringSet.of_list
    |> StringSet.to_map ~f:(Registry.directory reg))
  in
  Format.printf "Read user libraries: %s\n"
    (Option.value_map ~default:[] ~f:Map.keys user_libraries
    |> [%sexp_of: string list] |> Sexp.to_string_hum);
  let opam_libraries = match reg_opam with
    | None -> StringSet.to_map StringSet.empty ~f:ident
    | Some reg_opam ->
        OpamSatysfiRegistry.list reg_opam
        |> StringSet.of_list
        |> StringSet.to_map ~f:(OpamSatysfiRegistry.directory reg_opam)
  in
  Format.printf "Reading opam libraries: %s\n" (opam_libraries |> Map.keys |> [%sexp_of: string list] |> Sexp.to_string_hum);
  let all_libraries =
    Option.value ~default:(Map.empty (module StringSet.Elt)) user_libraries
    |> Map.merge opam_libraries ~f:(fun ~key -> function
      | `Left x -> Library.read_dir x |> Some
      | `Right x -> Library.read_dir x |> Some
      | `Both (_, x) ->
        Format.printf "Library %s is provided by both the user local and opam repositories\n" key;
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
      Format.printf "Overriding dist with user installed one";
      required_libraries

let show_compatibility_warnings ~libraries =
  Map.iteri libraries ~f:(fun ~key:library_name ~data:(library: Library.t) ->
    let open Library in
    let compatibility = library.compatibility in
    if Compatibility.is_empty compatibility |> not
    then begin
      let print_rename t renames =
        if RenameSet.is_empty renames |> not
        then begin
          Format.printf "@[<v 2>@,%s have been renamed.@,@[<v 2>" t;
          RenameSet.iter renames ~f:(fun { old_name; new_name } ->
            Format.printf "@,%s -> %s" old_name new_name;
          );
          Format.printf "@]@]@,";
        end
      in
      Format.printf "\n\027[1;33mCompatibility notice\027[0m for library %s:" library_name;
      print_rename "Packages" compatibility.rename_packages;
      print_rename "Fonts" compatibility.rename_fonts;
      Format.print_newline ();
    end
  )

let install_libraries d ~library_map  ~verbose ~copy () =
  let libraries = library_map |> Map.data in
  Map.keys library_map |> [%sexp_of: string list] |> Sexp.to_string_hum
  |> Format.printf "Installing libraries: %s@,";
  let merged = libraries
    |> List.fold_left ~f:Library.union ~init:Library.empty
  in
  begin match FileUtil.test FileUtil.Is_dir d, Library.is_managed_dir d with
  | true, false ->
    Format.printf "Directory %s is not managed by Satyrographos.\n" d;
    Format.printf "Please remove %s first.\n" d
  | _, _ ->
    Format.printf "Removing destination %s\n" d;
    FileUtil.(rm ~force:Force ~recurse:true [d]);
    Library.mark_managed_dir d;
    if verbose
    then begin
      [%sexp_of: Library.t list] libraries
      |> Sexp.to_string_hum
      |> Format.printf "Loaded libraries@,%s";
      [%sexp_of: Library.t] merged
      |> Sexp.to_string_hum
      |> Format.printf "Installing %s@,";
    end;
    Library.write_dir ~symlink:(not copy) d merged;
    List.iter ~f:(Format.printf "WARNING: %s") (Library.validate merged);
    Format.printf "Installation completed!\n";
    show_compatibility_warnings ~libraries:library_map;
  end


let install d ~system_font_prefix ~libraries ~verbose ~copy () =
  (* TODO build all *)
  Format.open_vbox 0;
  let maybe_repo = try_read_repo () in
  Option.iter maybe_repo ~f:(fun {repo; reg} ->
    Format.printf "Updating libraries@,";
    begin match Repository.update_all repo with
    | Some updated_libraries -> begin
      [%derive.show: string list] updated_libraries
      |> Format.printf "Updated libraries: %s@,";
    end
    | None ->
      Format.printf "No libraries updated@,"
    end;
    Format.printf "Building updated libraries@,";
    begin match Registry.update_all reg with
    | Some updated_libraries -> begin
      [%derive.show: string list] updated_libraries
      |> Format.printf "Built libraries: %s@,";
    end
    | None ->
      Format.printf "No libraries built@,"
    end);
  let maybe_reg = Option.map maybe_repo ~f:(fun p -> p.reg) in
  let library_map = get_libraries ~maybe_reg ~reg_opam ~libraries in
  let library_map = match system_font_prefix with
    | None -> Format.printf "Not gathering system fonts\n"; library_map
    | Some(prefix) ->
      Format.printf "Gathering system fonts with prefix %s\n" prefix;
      let systemFontLibrary = SystemFontLibrary.get_library prefix () in
      Map.add_exn ~key:"%fonts-system" ~data:systemFontLibrary library_map
  in
  install_libraries d ~verbose  ~library_map ~copy ();
  Format.close_box ()

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
