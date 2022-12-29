open Core
open Satyrographos
module Autogen = Satyrographos_autogen

module StringSet = Set.Make(String)

(* TODO Abstract this *)
module StringMap = Map.Make(String)

type persistent_autogen = Satyrographos_lockdown.LockdownFile.autogen

(** Returns transitively-required libraries from the given OPAM registry, Satyrographos registry, and SATySFi dist directory.

Registry has the following priority:
- Satyrographos local registry
- OPAM registry
- SATySFi dist directory

It fails when some of transitively-required libraries are missing.
 *)
let get_libraries ~outf ~(env: Environment.t) ~libraries =
  let dist_library_dir = Option.value_exn ~message:"SATySFi dist directory is not found. Please run opam install satysfi-dist" env.dist_library_dir in
  let opam_reg = env.opam_reg in
  Format.fprintf outf "Reading runtime dist: %s\n" dist_library_dir;
  let dist_library = Library.read_dir ~outf dist_library_dir in
  let opam_libraries = match opam_reg with
    | None -> StringSet.to_map StringSet.empty ~f:Fn.id
    | Some reg_opam ->
        OpamSatysfiRegistry.list reg_opam
        |> StringSet.of_list
        |> StringSet.to_map ~f:(OpamSatysfiRegistry.directory reg_opam)
  in
  Format.fprintf outf "Reading opam libraries: %s\n" (opam_libraries |> Map.keys |> [%sexp_of: string list] |> Sexp.to_string_hum);
  let all_libraries = Map.filter_mapi opam_libraries ~f:(fun ~key:name ~data:dir ->
      Library.read_dir_result ~outf dir
      |> Result.map_error ~f:(fun err ->
          Format.fprintf outf "Warning: Failed to read library %s at %s\nReason: %s\n" name dir err;
          ())
    |> Result.ok) in
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
  let library_dependency_rev_map =
    library_dependency_map
    |> Map.to_sequence
    |> Sequence.concat_map ~f:(fun (k, ds) ->
        Set.to_sequence ds
        |> Sequence.map ~f:(fun d -> (d, k)))
    |> Map.of_sequence_multi (module Library.StringMap.Key)
  in
  let library_name_set_to_install =
    LibraryMap.transitive_closure library_dependency_map (Library.Dependency.of_list required_library_names) in
  let all_library_name_set =
    Map.keys all_libraries |> Library.Dependency.of_list in
  let missing_dependencies = Set.diff library_name_set_to_install all_library_name_set in
  begin if not (Set.is_empty missing_dependencies)
    then
      failwithf
        !"Missing dependencies: %{sexp:Library.Dependency.t}. Revdeps: %{sexp:(string * string list) list}"
        missing_dependencies
        (Map.filter_keys ~f:(Set.mem missing_dependencies) library_dependency_rev_map
         |> Map.to_alist)
        ()
  end;
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


let add_autogen_libraries ~outf ~libraries ~env:(_ : Environment.t) ~(persistent_autogen: persistent_autogen) library_map =
  let available_libraries =
    Library.Dependency.of_list Autogen.Autogen.(
        List.map ~f:(fun a -> a.name) normal_libraries
        @ special_libraries
      )
  in
  let invalid_libraries =
    Set.diff libraries available_libraries
  in
  begin if Set.is_empty invalid_libraries |> not
    then failwithf
        !"Autogen libraries %{sexp: Library.Dependency.t} are not available."
        invalid_libraries
        ()
  end;
  Format.fprintf outf "Generating autogen libraries@.";
  let add_library name f m =
    if Set.mem libraries name
    then begin
      Format.fprintf outf "Generating autogen library %s@." name;
      let persistent_yojson =
        List.find ~f:(fun (l, _) -> String.equal l name) persistent_autogen
        |> Option.map ~f:snd
      in
      let l : Library.t = f ~outf ~persistent_yojson m in
      match Map.add m ~key:(Option.value ~default:"" l.name) ~data:l with
      | `Ok m -> m
      | `Duplicate -> failwithf "Autogen Library %s is duplicated:@." (Option.value ~default:"(no name)" l.name) ()
    end else m
  in
  let add_normal_libraries m =
    Autogen.Autogen.normal_libraries
    |> List.fold ~init:m ~f:(fun m (al: Autogen.Autogen.t) ->
        add_library al.name (fun ~outf ~persistent_yojson _library_map -> al.generate ~outf ~persistent_yojson) m)
  in
  library_map
  |> add_normal_libraries
  (* %fonts uses only the current data *)
  |> add_library Autogen.Fonts.name Autogen.Fonts.generate
  (* %libraries need to come last *)
  |> add_library Autogen.Libraries.name Autogen.Libraries.generate

let get_library_map ~outf ~system_font_prefix ~autogen_libraries ~libraries ~(env: Environment.t) ~persistent_autogen () =
  let library_map = get_libraries ~outf ~env ~libraries in
  let library_map = match system_font_prefix with
    | None -> Format.fprintf outf "Not gathering system fonts\n"; library_map
    | Some(prefix) ->
      Format.fprintf outf "Gathering system fonts with prefix %s\n" prefix;
      let systemFontLibrary = Autogen.FontsSystem.get_library prefix ~outf () in
      Map.add_exn ~key:"%fonts-system" ~data:systemFontLibrary library_map
  in
  let autogen_libraries =
    Map.data library_map
    |> List.map ~f:(fun l -> l.Library.autogen)
    |> List.cons (Library.Dependency.of_list autogen_libraries)
    |> Library.Dependency.union_list
  in
  if Set.is_empty autogen_libraries
  then library_map
  else add_autogen_libraries ~outf ~libraries:autogen_libraries ~env ~persistent_autogen library_map

let install d ~outf ~system_font_prefix ?(autogen_libraries=[]) ~libraries ~verbose ?safe:_ ~copy ~(env: Environment.t) ~persistent_autogen () =
  (* TODO build all *)
  Format.open_vbox 0;
  let library_map =
    get_library_map ~outf ~system_font_prefix ~autogen_libraries ~libraries ~env ~persistent_autogen ()
  in
  install_libraries d ~verbose ~outf ~library_map ~copy ();
  Format.close_box ()
