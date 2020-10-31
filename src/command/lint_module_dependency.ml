open Core
open Satyrographos
open Lint_prim


module StringSet = Set.Make(String)

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

let get_libraries ~loc ~env ~library_override m =
  let libraries =
    BuildScript.get_dependencies_opt m
    |> Option.map ~f:(fun d -> Library.Dependency.elements d)
    |> Option.value ~default:[]
  in
  let combine ~key:_ _v1 v2 = v2 in
  Result.try_with (fun () ->
      Install.get_library_map ~outf:dummy_formatter ~system_font_prefix:None ~libraries:(Some libraries) ~env ()
      |> (fun m -> Map.merge_skewed ~combine m library_override)
      |> Map.data
    )
  |> Result.map_error ~f:(fun exn ->
      [loc, `Error, (sprintf !"Exception during setting up the env. Install dependent libraries by `opam pin add \"file://$PWD\"`.\n%{sexp:Exn.t}" exn)]
    )

let lint_module_dependency ~outf ~loc ~satysfi_version ~basedir ~(env : Environment.t) (m : BuildScript.m) =
  let target_library =
    BuildScript.read_module ~src_dir:basedir m
  in
  let library_name =
    BuildScript.get_name m
  in
  let library_override =
    Map.singleton (module StringSet.Elt) library_name target_library
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
        let check_dependency ~mode ~dep_graph_mode =
          (* TODO Share subgraphs *)
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
          List.concat_map problematic_sinks ~f:(fun sink ->
              DependencyGraph.revese_lookup_directive dep_graph_mode sink
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
        let detect_cyclic_dependencies ~dep_graph_mode ~mode =
          let error =
            DependencyGraph.cyclic_directives dep_graph_mode
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
                let dep_graph_mode = DependencyGraph.subgraph_with_mode ~mode dep_graph in
                Result.bind
                  (detect_cyclic_dependencies ~mode ~dep_graph_mode)
                  ~f:(fun () ->
                     Result.try_with (fun () -> check_dependency ~mode ~dep_graph_mode)
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
        get_libraries ~loc ~env ~library_override m
        |> Result.map ~f:(verification temp_dir)
        |> (function
            | Ok e -> e
            | Error e -> Shexp_process.return e
          )
      )
  in
  Shexp_process.eval cmd
