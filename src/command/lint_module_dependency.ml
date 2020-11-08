open Core
open Satyrographos
open Lint_prim


module StringSet = Set.Make(String)

let dummy_formatter =
  Format.make_formatter (fun _ _ _ -> ()) ignore

type missing_dependency = {
  locs : location list;
  directive : Satyrographos_satysfi.Dependency.directive;
  suggested_dependency : string option;
  modes : Satyrographos_satysfi.Mode.t list;
}

let render_missing_dependency level (md : missing_dependency) =
    {
      locs = md.locs;
      level;
      problem = SatysfiFileMissingDependency {
        directive = md.directive;
        suggested_dependency = md.suggested_dependency;
        modes = md.modes;
      };
    }

let get_libraries ~locs ~env ~library_override m =
  let libraries =
    BuildScript.get_dependencies_opt m
    |> Option.map ~f:(fun d -> Library.Dependency.elements d)
    |> Option.value ~default:[]
  in
  let autogen_libraries =
    BuildScript.get_autogen_opt m
    |> Option.map ~f:Library.Dependency.elements
    |> Option.value ~default:[]
  in
  let combine ~key:_ _v1 v2 = v2 in
  Result.try_with (fun () ->
      Install.get_library_map
        ~outf:dummy_formatter
        ~system_font_prefix:None
        ~libraries:(Some libraries)
        ~autogen_libraries
        ~persistent_autogen:[] 
        ~env
        ()
      |> (fun m -> Map.merge_skewed ~combine m library_override)
      |> Map.data
    )
  |> Result.map_error ~f:(fun exn ->
      let problem = ExceptionDuringSettingUpEnv exn in
      [{locs; level = `Error; problem; }]
    )

let detect_cyclic_dependencies ~dep_graph_mode ~mode =
  let open Satyrographos_satysfi in
  let error =
    DependencyGraph.cyclic_directives dep_graph_mode
    |> List.map ~f:(fun ds ->
        let locs =
          List.map ds ~f:(fun (loc, _) ->
              FileLoc loc
            )
        in
        let problem = SatysfiFileCyclicDependency mode in
        {locs; level = `Error; problem; }
      )
  in
  Result.ok_if_true ~error (List.is_empty error)

let check_dependency ~loaded_library_names ~mode ~dep_graph_mode ~packages =
  let open Satyrographos_satysfi in
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
    DependencyGraph.reachable_sinks dep_graph_mode sources
    |> List.filter ~f:(function
        | DependencyGraph.Vertex.File _ -> false
        | _ -> true
      )
  in
  let get_suggested_dependency = function
    | Dependency.Require r ->
      begin match String.split r ~on:'/' with
        | l :: _ :: _ when StringSet.mem loaded_library_names l |> not ->
          Some l
        | _ -> None
      end
    | _ -> None
  in
  List.concat_map problematic_sinks ~f:(fun sink ->
      DependencyGraph.revese_lookup_directive dep_graph_mode sink
      |> List.map ~f:(fun ((loc, directive), _path) ->
          {
            locs = [FileLoc loc];
            directive;
            suggested_dependency = get_suggested_dependency directive;
            modes = [mode];
          }
        )
    )

let lint_module_dependency ~outf ~locs ~satysfi_version ~basedir ~(env : Environment.t) (m : BuildScript.m) =
  let target_library =
    BuildScript.read_module ~src_dir:basedir m
  in
  let library_name =
    BuildScript.get_name m
  in
  let library_override =
    Map.singleton (module StringSet.Elt) library_name target_library
  in
  let verification d libraries : diagnosis list Shexp_process.t =
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
        (* Satyrographos install does not create directory symlinks *)
        FilePath.reduce ~no_symlink:true path
        |> FilePath.make_relative d
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
        path
    in
    let decode_loc = function
      | FileLoc loc ->
        let path = decode_path loc.path in
        FileLoc {loc with path}
      | loc -> loc
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
              let floc = Location.{path; range=None;} in
              let problem = LibraryMissingFile in
              {locs = FileLoc floc :: locs; level =  `Error; problem;}
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
          |> Result.map_error ~f:(fun exn ->
              let stacktrace =
                Printexc.get_backtrace ()
              in
              let problem = InternalException (exn, stacktrace) in
              (* TODO Show errors only caused by this library. *)
              [{locs; level = `Error; problem;}])
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
                let dep_graph_mode = DependencyGraph.subgraph_with_mode ~mode dep_graph in
                let%bind.Result () = (detect_cyclic_dependencies ~mode ~dep_graph_mode) in
                Result.try_with (fun () ->
                    check_dependency
                      ~mode
                      ~dep_graph_mode
                      ~loaded_library_names:library_names
                      ~packages
                  )
                |> Result.map_error ~f:(fun exn ->
                    let stacktrace =
                      Printexc.get_backtrace ()
                    in
                    let problem = InternalException (exn, stacktrace) in
                    (* TODO Show errors only caused by this library. *)
                    [{locs; level = `Error; problem;}]
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
    >>| List.map ~f:(fun {locs; level; problem;} ->
        let locs = List.map ~f:decode_loc locs in
        {locs; level; problem;}
      )
  in
  let cmd =
    Shexp_process.with_temp_dir ~prefix:"Satyrographos" ~suffix:"lint" (fun temp_dir ->
        get_libraries ~locs ~env ~library_override m
        |> Result.map ~f:(verification temp_dir)
        |> (function
            | Ok e -> e
            | Error e -> Shexp_process.return e
          )
      )
  in
  Shexp_process.eval cmd
