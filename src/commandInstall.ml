open Core

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
let get_libraries ~outf ~maybe_reg ~opam_reg ~libraries =
  let dist_library_dir = SatysfiDirs.satysfi_dist_dir ~outf in
  Format.fprintf outf "Reading runtime dist: %s\n" dist_library_dir;
  let dist_library = Library.read_dir dist_library_dir in
  let user_libraries = Option.map maybe_reg ~f:(fun reg -> Registry.list reg
    |> StringSet.of_list
    |> StringSet.to_map ~f:(Registry.directory reg))
  in
  Format.fprintf outf "Read user libraries: %s\n"
    (Option.value_map ~default:[] ~f:Map.keys user_libraries
    |> [%sexp_of: string list] |> Sexp.to_string_hum);
  let opam_libraries = match opam_reg with
    | None -> StringSet.to_map StringSet.empty ~f:ident
    | Some reg_opam ->
        OpamSatysfiRegistry.list reg_opam
        |> StringSet.of_list
        |> StringSet.to_map ~f:(OpamSatysfiRegistry.directory reg_opam)
  in
  Format.fprintf outf "Reading opam libraries: %s\n" (opam_libraries |> Map.keys |> [%sexp_of: string list] |> Sexp.to_string_hum);
  let all_libraries =
    Option.value ~default:(Map.empty (module StringSet.Elt)) user_libraries
    |> Map.merge opam_libraries ~f:(fun ~key -> function
      | `Left x -> Library.read_dir x |> Some
      | `Right x -> Library.read_dir x |> Some
      | `Both (_, x) ->
        Format.fprintf outf "Library %s is provided by both the user local and opam repositories\n" key;
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
      Format.fprintf outf "Overriding dist with user installed one\n";
      required_libraries

let show_compatibility_warnings ~outf ~libraries =
  Map.iteri libraries ~f:(fun ~key:library_name ~data:(library: Library.t) ->
    let open Library in
    let compatibility = library.compatibility in
    if Compatibility.is_empty compatibility |> not
    then begin
      let print_rename t renames =
        if RenameSet.is_empty renames |> not
        then begin
          Format.fprintf outf "@[<v 2>@,%s have been renamed.@,@[<v 2>" t;
          RenameSet.iter renames ~f:(fun { old_name; new_name } ->
            Format.fprintf outf "@,%s -> %s" old_name new_name;
          );
          Format.fprintf outf "@]@]@,";
        end
      in
      Format.fprintf outf "\n\027[1;33mCompatibility notice\027[0m for library %s:" library_name;
      print_rename "Packages" compatibility.rename_packages;
      print_rename "Fonts" compatibility.rename_fonts;
      Format.fprintf outf "@.";
    end
  )

let install_libraries d ~outf ~library_map  ~verbose ~copy () =
  let libraries = library_map |> Map.data in
  Map.keys library_map |> [%sexp_of: string list] |> Sexp.to_string_hum
  |> Format.fprintf outf "Installing libraries: %s@,";
  let merged = libraries
    |> List.fold_left ~f:Library.union ~init:Library.empty
  in
  begin match FileUtil.test FileUtil.Is_dir d, Library.is_managed_dir d with
  | true, false ->
    Format.fprintf outf "Directory %s is not managed by Satyrographos.\n" d;
    Format.fprintf outf "Please remove %s first.\n" d
  | _, _ ->
    Format.fprintf outf "Removing destination %s\n" d;
    FileUtil.(rm ~force:Force ~recurse:true [d]);
    Library.mark_managed_dir d;
    if verbose
    then begin
      [%sexp_of: Library.t list] libraries
      |> Sexp.to_string_hum
      |> Format.fprintf outf "Loaded libraries@,%s";
      [%sexp_of: Library.t] merged
      |> Sexp.to_string_hum
      |> Format.fprintf outf "Installing %s@,";
    end;
    Library.write_dir ~outf ~symlink:(not copy) d merged;
    List.iter ~f:(Format.fprintf outf "WARNING: %s") (Library.validate merged);
    Format.fprintf outf "Installation completed!\n";
    show_compatibility_warnings ~outf ~libraries:library_map;
  end


let install d ~outf ~system_font_prefix ~libraries ~verbose ~copy ~(env: Environment.t) () =
  (* TODO build all *)
  Format.open_vbox 0;
  let maybe_repo = env.repo in
  Option.iter maybe_repo ~f:(fun {repo; reg} ->
    Format.fprintf outf "Updating libraries@,";
    begin match Repository.update_all ~outf repo with
    | Some updated_libraries -> begin
      [%derive.show: string list] updated_libraries
      |> Format.fprintf outf "Updated libraries: %s@,";
    end
    | None ->
      Format.fprintf outf "No libraries updated@,"
    end;
    Format.fprintf outf "Building updated libraries@,";
    begin match Registry.update_all ~outf reg with
    | Some updated_libraries -> begin
      [%derive.show: string list] updated_libraries
      |> Format.fprintf outf "Built libraries: %s@,";
    end
    | None ->
      Format.fprintf outf "No libraries built@,"
    end);
  let maybe_reg = Option.map maybe_repo ~f:(fun p -> p.reg) in
  let library_map = get_libraries ~outf ~maybe_reg ~opam_reg:env.opam_reg ~libraries in
  let library_map = match system_font_prefix with
    | None -> Format.fprintf outf "Not gathering system fonts\n"; library_map
    | Some(prefix) ->
      Format.fprintf outf "Gathering system fonts with prefix %s\n" prefix;
      let systemFontLibrary = SystemFontLibrary.get_library prefix ~outf () in
      Map.add_exn ~key:"%fonts-system" ~data:systemFontLibrary library_map
  in
  install_libraries d ~verbose ~outf ~library_map ~copy ();
  Format.close_box ()
