open Core
open Satyrographos
module Autogen = Satyrographos_autogen

module StringSet = Set.Make(String)

(* TODO Abstract this *)
module StringMap = Map.Make(String)

(** Returns transitively-required libraries from the given OPAM registry, Satyrographos registry, and SATySFi dist directory.

Registry has the following priority:
- Satyrographos local registry
- OPAM registry
- SATySFi dist directory

It fails when some of transitively-required libraries are missing.
 *)
let get_libraries ~outf ~maybe_reg ~(env: Environment.t) ~libraries =
  let dist_library_dir = Option.value_exn ~message:"SATySFi dist directory is not found. Please run opam install satysfi-dist" env.dist_library_dir in
  let opam_reg = env.opam_reg in
  Format.fprintf outf "Reading runtime dist: %s\n" dist_library_dir;
  let dist_library = Library.read_dir ~outf dist_library_dir in
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
      | `Left x -> Library.read_dir ~outf x |> Some
      | `Right x -> Library.read_dir ~outf x |> Some
      | `Both (_, x) ->
        Format.fprintf outf "Library %s is provided by both the user local and opam repositories\n" key;
        Library.read_dir ~outf x |> Some) in
  let all_libraries = match Map.add all_libraries ~key:"dist" ~data:dist_library with
    | `Ok result -> result
    | `Duplicate ->
      Format.fprintf outf "Overriding dist with user installed one\n";
      all_libraries in
  (* A dirty hack to set library metadata of dist library *)
  (* TODO (gh-123) Add library version too *)
  let all_libraries = Map.change all_libraries "dist" ~f:(Option.map ~f:(fun l -> {l with Library.name = Some "dist"})) in
  let required_library_names =
    "dist" :: Option.value ~default:(Map.keys all_libraries) libraries in
  let library_dependency_map =
    Map.map all_libraries ~f:(fun p -> p.Library.dependencies) in
  let library_name_set_to_install =
    LibraryMap.transitive_closure library_dependency_map (Library.Dependency.of_list required_library_names) in
  let all_library_name_set =
    Map.keys all_libraries |> Library.Dependency.of_list in
  let missing_dependencies = Set.diff library_name_set_to_install all_library_name_set in
  begin if not (Set.is_empty missing_dependencies)
    then failwithf !"Missing dependencies: %{sexp:Library.Dependency.t}" missing_dependencies () end;
  Map.filter_keys all_libraries ~f:(Set.mem library_name_set_to_install)

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
      Format.fprintf outf "\n\027[1;33mCompatibility notice\027[0m for library %s:@," library_name;
      print_rename "Packages" compatibility.rename_packages;
      print_rename "Fonts" compatibility.rename_fonts;
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
      |> Format.fprintf outf "Loaded libraries@,%s@,";
      [%sexp_of: Library.t] merged
      |> Sexp.to_string_hum
      |> Format.fprintf outf "Installing %s@,";
    end;
    Library.write_dir ~outf ~symlink:(not copy) d merged;
    List.iter ~f:(Format.fprintf outf "WARNING: %s") (Library.validate merged);
    Format.fprintf outf "Installation completed!\n";
    show_compatibility_warnings ~outf ~libraries:library_map;
  end


let add_autogen_libraries ~outf ~libraries ~env:(_ : Environment.t) library_map =
  Format.fprintf outf "Generating autogen libraries@.";
  let add_library name f m =
    if Set.mem libraries name
    then begin
      Format.fprintf outf "Generating autogen library %s@." name;
      let l : Library.t = f ~outf m in
      match Map.add m ~key:(Option.value ~default:"" l.name) ~data:l with
      | `Ok m -> m
      | `Duplicate -> failwithf "Autogen Library %s is duplicated:@." (Option.value ~default:"(no name)" l.name) ()
    end else m
  in
  library_map
  |> add_library Autogen.Fonts.name Autogen.Fonts.generate
  |> add_library Autogen.Libraries.name Autogen.Libraries.generate

let get_library_map ~outf ~system_font_prefix ?(autogen_libraries=[]) ~libraries ~(env: Environment.t) () =
  let maybe_depot = env.depot in
  let maybe_reg = Option.map maybe_depot ~f:(fun p -> p.reg) in
  let library_map = get_libraries ~outf ~maybe_reg ~env ~libraries in
  let library_map = match system_font_prefix with
    | None -> Format.fprintf outf "Not gathering system fonts\n"; library_map
    | Some(prefix) ->
      Format.fprintf outf "Gathering system fonts with prefix %s\n" prefix;
      let systemFontLibrary = SystemFontLibrary.get_library prefix ~outf () in
      Map.add_exn ~key:"%fonts-system" ~data:systemFontLibrary library_map
  in
  let autogen_libraries =
    autogen_libraries
    |> Set.of_list (module String)
  in
  if Set.is_empty autogen_libraries
  then library_map
  else add_autogen_libraries ~outf ~libraries:autogen_libraries ~env library_map

let install d ~outf ~system_font_prefix ?(autogen_libraries=[]) ~libraries ~verbose ?(safe=false) ~copy ~(env: Environment.t) () =
  (* TODO build all *)
  Format.open_vbox 0;
  let maybe_depot = env.depot in
  begin if safe
    then Option.iter maybe_depot ~f:(fun {repo; reg} ->
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
      end)
  end;
  let library_map =
    get_library_map ~outf ~system_font_prefix ~autogen_libraries ~libraries ~env ()
  in
  install_libraries d ~verbose ~outf ~library_map ~copy ();
  Format.close_box ()
