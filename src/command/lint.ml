open Core
open Satyrographos

module Location = Satyrographos.Location

type location =
  | SatyristesModLoc of (string * string * (int * int) option)
  | FileLoc of Location.t
  | OpamLoc of string

let show_location ~outf ~basedir =
  let concat_with_basedir = FilePath.make_absolute basedir in
  function
  | SatyristesModLoc (buildscript_path, module_name, None) ->
    Format.fprintf outf "%s: (module %s):@." (concat_with_basedir buildscript_path) module_name
  | SatyristesModLoc (buildscript_path, module_name, Some (line, col)) ->
    Format.fprintf outf "%s:%d:%d: (module %s):@." (concat_with_basedir buildscript_path) line col module_name
  | FileLoc loc ->
    Format.fprintf outf "%s:@." (Location.display loc)
  | OpamLoc (opam_path) ->
    Format.fprintf outf "%s:@." (concat_with_basedir opam_path)

let show_locations ~outf ~basedir locs =
  List.rev locs
  |> List.iter ~f:(show_location ~outf ~basedir)

let show_problem ~outf ~basedir (locs, level, msg) =
  show_locations ~outf ~basedir locs;
  match level with
  | `Error->
    Format.fprintf outf "@[<2>Error:@ %s@]@.@." msg
  | `Warning ->
    Format.fprintf outf "@[<2>Warning:@ %s@]@.@." msg

let show_problems ~outf ~basedir =
  List.iter ~f:(show_problem ~outf ~basedir)

let lint_opam_file ~opam ~opam_path:_ ~loc =
  OpamFileTools.lint opam
  |> List.map ~f:(fun (error_no, level, msg) ->
      loc, level, sprintf "(%d) %s" error_no msg)

let get_opam_name ~opam ~opam_path =
  OpamFile.OPAM.name_opt opam
  |> Option.map ~f:OpamPackage.Name.to_string
  |> Option.value ~default:(FilePath.basename opam_path |> FilePath.chop_extension)

module StringSet = Set.Make(String)

let extract_opam_package_names ~opam =
  let rec sub =
    let open OpamTypes in
    function
    | Empty -> StringSet.empty
    | Atom (n, _) ->
      OpamPackage.Name.to_string n
      |> StringSet.singleton
    | Block b -> sub b
    | And (x, y) -> StringSet.union (sub x) (sub y)
    | Or (x, y) -> StringSet.union (sub x) (sub y)
  in
  OpamFile.OPAM.depends opam |> sub

let lint_module_opam ~loc ~basedir ~buildscript_basename:_ (m : BuildScript.m) opam_path =
  let loc = OpamLoc opam_path :: loc in
  let opam_file =
    OpamFilename.create (OpamFilename.Dir.of_string basedir) (OpamFilename.Base.of_string opam_path)
      |> OpamFile.make
  in
  let open OpamFile in
  let opam = OPAM.read opam_file in
  let module_name = BuildScript.get_name m in
  let test_name =
    let opam_name = get_opam_name ~opam ~opam_path in
    if String.equal ("satysfi-" ^ module_name) opam_name |> not
    then [loc, `Error, (sprintf "OPAM package name “%s” should be “satysfi-%s”." opam_name module_name)]
    else []
  in
  let test_version =
    let module_version =
      BuildScript.get_version_opt m
      |> Option.value_exn
        ~message:(sprintf "BUG: Module %s lacks a version" module_name)
    in
    let opam_version = OPAM.version_opt opam |> Option.map ~f:OpamPackage.Version.to_string in
    match opam_version with
    | _ when String.is_empty module_version ->
        [loc, `Error, (sprintf "Version should not be empty.")]
    | Some opam_version when String.equal module_version opam_version ->
      []
    | Some opam_version when String.is_prefix ~prefix:module_version opam_version ->
      let module_version_length = String.length module_version in
      let last_module_version_char = String.get module_version (module_version_length - 1) in
      let first_opam_version_char = String.get opam_version module_version_length in
      begin match
          Char.is_digit last_module_version_char,
          Char.is_alpha last_module_version_char,
          Char.is_digit first_opam_version_char,
          Char.is_alpha first_opam_version_char
        with
        | false, false, _, _ ->
          [loc, `Error, (sprintf "Library version “%s” should end with an alphabet or a digit." module_version)]
        | _, true, _, true
        | true, _, true, _ ->
          [loc, `Error, (sprintf "OPAM package version “%s” should be prefixed with “%s”." opam_version module_version)]
        | _, _, _, _ -> []
      end
    | Some opam_version ->
      [loc, `Error, (sprintf "OPAM package version “%s” should be prefixed with “%s”." opam_version module_version)]
    | None ->
      [loc, `Error, (sprintf "OPAM file lacks the version field")]
  in
  let test_dependencies =
    let module_dependencies =
      BuildScript.get_dependencies_opt m
      |> Option.value_exn
        ~message:(sprintf "BUG: Module %s lacks dependencies" module_name)
      |> Library.Dependency.to_array
      |> StringSet.of_array
    in
    let opam_dependencies =
      extract_opam_package_names ~opam
      |> StringSet.filter_map ~f:(String.chop_prefix ~prefix:"satysfi-")
    in
    let missing_dependencies =
      StringSet.diff module_dependencies opam_dependencies
    in
    if StringSet.is_empty missing_dependencies |> not
    then
      [loc, `Warning, (sprintf !"The OPAM file lacks dependencies on specified SATySFi libraries: %{sexp:StringSet.t}." missing_dependencies)]
    else []
  in
  List.concat
    [ test_name;
      test_version;
      test_dependencies;
      lint_opam_file ~opam ~opam_path ~loc;
    ]

let dummy_formatter =
  Format.make_formatter (fun _ _ _ -> ()) ignore

type hint =
  | MissingDependency of string

type missing_dependency = {
  loc : location list;
  directive : Satyrographos_satysfi.Dependency.directive;
  hint : hint option;
  modes : Satyrographos_satysfi.Mode.t list;
}

let render_missing_dependency level (md : missing_dependency) =
    let open Satyrographos_satysfi in
    let hint = match md.hint with
      | Some (MissingDependency l) ->
        Some (
          sprintf "You may need to add dependency on “%s” to Satyristes." l
        )
      | _ -> None
    in
    (* TODO Add hint to the message line type. *)
    let hint =
      Option.map hint ~f:(sprintf "\n\n  Hint: %s\n")
      |> Option.value ~default:""
    in
    md.loc, level, sprintf !"Missing dependency for “%s” (mode %{sexp:Mode.t list})%s"
      (Dependency.render_directive md.directive)
      (List.sort ~compare:Mode.compare md.modes)
      hint

let lint_module_dependency ~outf ~loc ~satysfi_version ~basedir ~buildscript_basename:_ ~(env : Environment.t) (m : BuildScript.m) =
  let target_library =
    BuildScript.read_module ~src_dir:basedir m
  in
  let library_name =
    BuildScript.get_name m
  in
  let get_libraries () =
    let libraries =
      BuildScript.get_dependencies_opt m
      |> Option.map ~f:(fun d -> Library.Dependency.elements d)
      |> Option.value ~default:[]
    in
    Result.try_with (fun () ->
        Install.get_library_map ~outf:dummy_formatter ~system_font_prefix:None ~libraries:(Some libraries) ~env ()
        |> (fun m -> Map.remove m library_name)
        |> Map.add_exn ~key:library_name ~data:target_library
        |> Map.data
      )
    |> Result.map_error ~f:(fun exn ->
        [loc, `Error, (sprintf !"Exception during setting up the env. Install dependent libraries by `opam pin add \"file://$PWD\"`.\n%{sexp:Exn.t}" exn)]
      )
  in
  let verification d libraries : (location list * [> `Error] * string) list Shexp_process.t =
    let library_names =
      List.filter_map libraries ~f:(fun l -> l.Library.name)
      |> StringSet.of_list
    in
    let merged =
      libraries
      |> List.fold_left ~f:Library.union ~init:Library.empty
    in
    let decode_path path =
      let package_relative_path =
        FilePath.make_relative d path
      in
      let content = Library.LibraryFiles.find
        merged.files
        package_relative_path
      in
      match content with
      | Some (`Filename fn) -> fn
      | Some (`Content _) ->
        (* TODO Handle this case. *)
        sprintf "(autogen-file)"
      | None ->
        failwithf "BUG: decode_path: File %S is not found." path ()
    in
    let module P = Shexp_process in
    let open Shexp_process.Infix in
    P.return ()
    >>| (fun () -> Library.write_dir ~outf ~symlink:true d merged)
    >>| (fun () ->
        let open Satyrographos_satysfi in
        let packages =
          target_library.files
          |> Library.LibraryFiles.keys
          |> List.filter ~f:(String.is_prefix ~prefix:"packages/")
          |> List.map ~f:(FilePath.concat d)
        in
        let missing_file_errors =
          List.filter packages ~f:FileUtil.(test (Not Is_file))
          |> List.map ~f:(function path ->
              let path = decode_path path in
              let floc = Location.{path; range=None;} in
              FileLoc floc :: loc, `Error, "Missing file"
            )
        in
        let dep_graph =
          Result.try_with (fun () ->
              DependencyGraph.dependency_graph
                ~outf:dummy_formatter
                ~follow_required:true
                ~package_root_dirs:[FilePath.concat d "packages"]
                ~satysfi_version
                packages
            )
          |> Result.map_error ~f:(fun exc ->
              let msg =
                sprintf "Exception:\n%s\n%s\n"
                  (Exn.to_string exc)
                  (Printexc.get_backtrace ())
              in
              (* TODO Show errors only caused by this library. *)
              [loc, `Error, msg])
        in
        let check_dependency mode dep_graph =
          (* TODO Share subgraphs *)
          let dep_graph = DependencyGraph.subgraph_with_mode ~mode dep_graph in
          let sources =
            List.map packages ~f:(fun f -> DependencyGraph.vertex_of_file_path f)
            |> List.filter ~f:(function
                | DependencyGraph.Vertex.File p
                | DependencyGraph.Vertex.MissingFile p
                  ->
                  Mode.of_basename_opt p
                  |> [%equal: Mode.t option] (Some mode)
                | _ -> true
              )
          in
          let problematic_sinks =
            DependencyGraph.reachable_sinks dep_graph sources
            |> List.filter ~f:(function
                | DependencyGraph.Vertex.File _ -> false
                | _ -> true
              )
          in
          List.concat_map problematic_sinks ~f:(fun sink ->
              DependencyGraph.revese_lookup_directive dep_graph sink
              |> List.map ~f:(fun ((loc, d), _path) ->
                  let path = decode_path loc.path in
                  let loc = {loc with path} in
                  let hint = match d with
                    | Dependency.Require r ->
                      begin match String.split r ~on:'/' with
                      | l :: _ :: _ when StringSet.mem library_names l |> not ->
                        Some (MissingDependency l)
                      | _ -> None
                      end
                    | _ -> None
                  in
                  {
                    loc = [FileLoc loc];
                    directive = d;
                    hint;
                    modes = [mode];
                  }
                )
            )
        in
        let detect_cyclic_dependencies dep_graph mode =
          (* TODO Share subgraphs *)
          let dep_graph = DependencyGraph.subgraph_with_mode ~mode dep_graph in
          let error =
            DependencyGraph.cyclic_directives dep_graph
            |> List.map ~f:(fun ds ->
                let locs =
                  List.map ds ~f:(fun (loc, _) ->
                      FileLoc {loc with path = decode_path loc.path;}
                    )
                in
                (locs, `Error, (sprintf !"Cyclic dependency found for mode %{sexp:Mode.t}" mode))
              )
          in
          Result.ok_if_true ~error (List.is_empty error)
        in
        let modes =
          (* TODO Optimize *)
          target_library.files
          |> Library.LibraryFiles.keys
          |> List.filter_map ~f:(fun path ->
              FilePath.basename path
              |> Mode.of_basename_opt)
          |> List.dedup_and_sort ~compare:Mode.compare
        in
        Result.bind dep_graph ~f:(fun dep_graph ->
            List.map modes ~f:(fun mode ->
                Result.bind
                  (detect_cyclic_dependencies dep_graph mode)
                  ~f:(fun () ->
                     Result.try_with (fun () -> check_dependency mode dep_graph)
                     |> Result.map_error ~f:(fun exn ->
                         [loc, `Error, (sprintf !"Something went wrong during working on dependency graphs.\n%{sexp:Exn.t}\n%s" exn (Printexc.get_backtrace ()))]
                       )
                  )
              )
            |> Result.combine_errors
            |> Result.map ~f:(List.concat)
            |> Result.map_error ~f:(List.concat)
            |> Result.map ~f:(List.map ~f:(render_missing_dependency `Error))
          )
        |> (function
            | Ok e -> e
            | Error e -> e
          )
        |> List.append missing_file_errors
      )
  in
  let cmd =
    Shexp_process.with_temp_dir ~prefix:"Satyrographos" ~suffix:"lint" (fun temp_dir ->
        get_libraries ()
        |> Result.map ~f:(verification temp_dir)
        |> (function
            | Ok e -> e
            | Error e -> Shexp_process.return e
          )
      )
  in
  Shexp_process.eval cmd

let lint_module ~outf ~verbose:_ ~satysfi_version ~basedir ~buildscript_basename ~(env: Environment.t) (m : BuildScript.m) =
  let loc = [SatyristesModLoc BuildScript.(buildscript_basename, get_name m, get_position_opt m)] in
  let opam_problems =
    BuildScript.get_opam_opt m
    |> Option.map ~f:(lint_module_opam ~loc ~basedir ~buildscript_basename m)
    |> Option.value ~default:[]
  in
  let dependency_problems =
    lint_module_dependency ~outf ~loc ~satysfi_version ~basedir ~buildscript_basename ~env m
  in
  opam_problems
  @ dependency_problems

let lint ~outf ~satysfi_version ~verbose ~buildscript_path ~(env : Environment.t) =
  let buildscript_path = Option.value ~default:"Satyristes" buildscript_path in
  let buildscript_path =
    let cwd = FileUtil.pwd () in
    FilePath.make_absolute cwd buildscript_path
  in
  let basedir = FilePath.dirname buildscript_path in
  let buildscript_basename = FilePath.basename buildscript_path in
  let buildscript = BuildScript.load buildscript_path in
  let problems =
    Map.to_alist buildscript
    |> List.concat_map ~f:(fun (_, m) ->
        lint_module ~outf ~verbose ~satysfi_version ~basedir ~buildscript_basename ~env m)
  in
  show_problems ~outf ~basedir problems;
  List.length problems
  |> Format.fprintf outf "%d problem(s) found.@.";
  List.find problems ~f:(function _, `Error, _ -> true | _ -> false)
  |> Option.value_map ~default:0 ~f:(const 1)
