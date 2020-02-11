open Core

module StringSet = Set.Make(String)

(* TODO Abstract this *)
module StringMap = Map.Make(String)

(** Calculate a transitive closure. *)
let transitive_closure map =
  let rec f visited queue = match StringSet.choose queue with
    | None -> visited
    | Some cur ->
      let visited = StringSet.add visited cur in
      match Map.find map cur with
      | None -> visited;
      | Some nexts ->
        let queue =  StringSet.union (StringSet.remove queue cur) (StringSet.diff nexts visited) in
        f visited queue in
  f StringSet.empty

(* TODO property-based testing *)
let%expect_test "transitive_closure: empty" =
  let map = [ "a", ["b"; "c"; "f"]; "b", ["d"]; "c", []; "d", ["e"; "f"]; "f", [] ]
    |> List.map ~f:(fun (x, y) -> x, StringSet.of_list y)
    |> StringMap.of_alist_exn in
  let init = StringSet.empty in
  transitive_closure map init
  |> [%sexp_of: StringSet.t] |> Sexp.to_string_hum |> print_endline;
  [%expect{| () |}]
let%expect_test "transitive_closure: transitive" =
  let map = [ "a", ["b"; "c"; "f"]; "b", ["d"]; "c", []; "d", ["e"; "f"]; "e", []; "f", [] ]
    |> List.map ~f:(fun (x, y) -> x, StringSet.of_list y)
    |> StringMap.of_alist_exn in
  let init = StringSet.of_list [ "a" ] in
  transitive_closure map init
  |> [%sexp_of: StringSet.t] |> Sexp.to_string_hum |> print_endline;
  [%expect{| (a b c d e f) |}]
let%expect_test "transitive_closure: loop" =
  let map = [ "a", ["b"]; "b", ["a"] ]
    |> List.map ~f:(fun (x, y) -> x, StringSet.of_list y)
    |> StringMap.of_alist_exn in
  let init = StringSet.of_list [ "a" ] in
  transitive_closure map init
  |> [%sexp_of: StringSet.t] |> Sexp.to_string_hum |> print_endline;
  [%expect{| (a b) |}]
let%expect_test "transitive_closure: non-closed" =
  let map = [ "a", ["b"] ]
    |> List.map ~f:(fun (x, y) -> x, StringSet.of_list y)
    |> StringMap.of_alist_exn in
  let init = StringSet.of_list [ "a" ] in
  transitive_closure map init
  |> [%sexp_of: StringSet.t] |> Sexp.to_string_hum |> print_endline;
  [%expect{| (a b) |}]
let%expect_test "transitive_closure: non-closed" =
  let map = [ "a", ["b"] ]
    |> List.map ~f:(fun (x, y) -> x, StringSet.of_list y)
    |> StringMap.of_alist_exn in
  let init = StringSet.of_list [ "c" ] in
  transitive_closure map init
  |> [%sexp_of: StringSet.t] |> Sexp.to_string_hum |> print_endline;
  [%expect{| (c) |}]


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
  let all_libraries = match Map.add all_libraries ~key:"dist" ~data:dist_library with
    | `Ok result -> result
    | `Duplicate ->
      Format.fprintf outf "Overriding dist with user installed one\n";
      all_libraries in
  let required_library_names =
    "dist" :: Option.value ~default:(Map.keys all_libraries) libraries in
  let library_dependency_map =
    Map.map all_libraries ~f:(fun p -> p.Library.dependencies) in
  let library_name_set_to_install =
    transitive_closure library_dependency_map (StringSet.of_list required_library_names) in
  let all_library_name_set =
    Map.keys all_libraries |> StringSet.of_list in
  let missing_dependencies = StringSet.diff library_name_set_to_install all_library_name_set in
  begin if not (Set.is_empty missing_dependencies)
  then failwithf !"Missing dependencies: %{sexp:StringSet.t}" missing_dependencies () end;
  Map.filter_keys all_libraries ~f:(StringSet.mem library_name_set_to_install)

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
  let library_map = get_libraries ~outf ~maybe_reg ~env ~libraries in
  let library_map = match system_font_prefix with
    | None -> Format.fprintf outf "Not gathering system fonts\n"; library_map
    | Some(prefix) ->
      Format.fprintf outf "Gathering system fonts with prefix %s\n" prefix;
      let systemFontLibrary = SystemFontLibrary.get_library prefix ~outf () in
      Map.add_exn ~key:"%fonts-system" ~data:systemFontLibrary library_map
  in
  install_libraries d ~verbose ~outf ~library_map ~copy ();
  Format.close_box ()
