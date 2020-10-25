open Core

open Satyrographos_satysfi


let get_runtime_dirs ~runtime_dirs ~project_env =
  match runtime_dirs, project_env with
  | Some runtime_dirs, _ ->
    String.split ~on:':' runtime_dirs
  | _, Some project_env ->
    [Satyrographos.Environment.get_satysfi_runtime_dir project_env]
  | None, None ->
    let open SatysfiDirs in
    Option.to_list (user_dir ()) @ runtime_dirs ()

let dependency_graph ~outf ~runtime_dirs ~mode ~follow_required ~satysfi_version ~satysfi_files =
  let package_root_dirs = SatysfiDirs.expand_package_root_dirs ~satysfi_version runtime_dirs in
  let g = DependencyGraph.dependency_graph ~outf ~package_root_dirs ~satysfi_version ~follow_required satysfi_files in
  Option.value_map mode ~default:g ~f:(fun mode -> DependencyGraph.subgraph_with_mode ~mode g)

let deps_make_command =
  let open Command.Let_syntax in
  let readme () =
    sprintf "Output dependencies of SATySFi files in Makefile format. (EXPERIMENTAL)"
  in
  Command.basic
    ~summary:"Output dependencies"
    ~readme
    [%map_open
      let runtime_dirs = flag "--satysfi-root-dirs" (optional string) ~aliases:["C"] ~doc:"DIRs Colon-separated list of SATySFi root directories"
      and depfile = flag "--depfile" (optional string) ~aliases:["f"] ~doc:"FILE Filename of output Makefile depfile like gcc -MF.  Additionally, the depfile will also added as an target."
      and _verbose = flag "--verbose" no_arg ~doc:"Make verbose"
      and mode = flag "--mode" (optional string) ~doc:"SATySFi typesetting mode (e.g., .satyh, .satyh-md, .satyg)"
      and target_filename = flag "--target" (optional string) ~aliases:["o"] ~doc:"SATySFi typesetting output filename"
      and phony_targets = flag "--phony-targets" no_arg ~aliases:["p"] ~doc:"Add phony targets like gcc -MP"
      and follow_required = flag "--follow-required" no_arg ~aliases:["r"] ~doc:"Follow required package files"
      and satysfi_version = Version.flag
      and satysfi_files = anon (non_empty_sequence_as_list ("FILE" %: string))
      in
      fun () ->
        Compatibility.optin ();
        let project_env = Satyrographos.Environment.get_project_env () in
        let runtime_dirs =
          get_runtime_dirs ~runtime_dirs ~project_env
        in
        let outf = Format.err_formatter in
        let mode =
          Option.map ~f:Mode.of_string_exn mode
          |> Option.value ~default:Mode.Pdf
        in
        let g =
          dependency_graph ~outf ~runtime_dirs ~mode:(Some mode) ~follow_required ~satysfi_version ~satysfi_files
        in
        let expand_sources (source, deps) =
          let saty_extension = Mode.to_extension mode in
          let basename =
            Option.first_some
              (String.chop_suffix source ~suffix:saty_extension)
              (String.chop_suffix source ~suffix:".saty")
            |> Option.value_exn ~message:(sprintf "Extention of %s should be either %s or .saty" source saty_extension)
          in
          let target =
            match target_filename, Mode.to_output_extension_opt mode with
            | Some target_filename, _ -> target_filename
            | None, Some output_extension ->
              basename ^ output_extension
            | None, None ->
              failwithf "Please specify SATySFi output filename (-o <filename>)" ()
          in
          (target, source :: deps)
          :: Option.value_map depfile ~default:[] ~f:(fun depfile ->
              [depfile, source :: deps;]
            )
        in
        let data =
          DependencyGraph.reachable_files g satysfi_files
          |> List.concat_map ~f:expand_sources
        in
        let data =
          if phony_targets
          then DependencyGraph.Makefile.expand_deps data
          else data
        in
        let data =
          DependencyGraph.Makefile.to_string data
        in
        match depfile with
        | Some depfile ->
          Out_channel.write_all depfile ~data
        | None ->
          print_string data
    ]

let util_command =
  Command.group ~summary:"SATySFi related utilities for debugging Satyrographos (experimental)"
    [ "deps-make", deps_make_command;
    ]
