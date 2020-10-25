open Core

open Satyrographos_satysfi


let depgraph_command =
  let open Command.Let_syntax in
  let readme () =
    sprintf "Output dependency graph (EXPERIMENTAL)"
  in
  Command.basic
    ~summary:"Output dependency graph"
    ~readme
    [%map_open
      let runtime_dirs = flag "--satysfi-root-dirs" (optional string) ~aliases:["C"] ~doc:"DIRs Colon-separated list of SATySFi root directories"
      and _verbose = flag "--verbose" no_arg ~doc:"Make verbose"
      and mode = flag "--mode" (optional string) ~doc:"SATySFi typesetting mode (e.g., .satyh, .satyh-md, .satyg)"
      and follow_required = flag "--follow-required" no_arg ~aliases:["r"] ~doc:"Follow required package files"
      and satysfi_version = Version.flag
      and satysfi_files = anon (non_empty_sequence_as_list ("FILE" %: string))
      in
      fun () ->
        Compatibility.optin ();
        let runtime_dirs = match runtime_dirs with
          | Some runtime_dirs ->
            String.split ~on:':' runtime_dirs
          | None ->
            let open SatysfiDirs in
            Option.to_list (user_dir ()) @ runtime_dirs ()
        in
        let outf = Format.err_formatter in
        let mode = Option.map ~f:Mode.of_string_exn mode in
        let g =
          CommandUtil.dependency_graph ~outf ~runtime_dirs ~mode ~follow_required ~satysfi_version ~satysfi_files
        in
        DependencyGraph.Dot.fprint_graph Format.std_formatter g
    ]

let status_project_env =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Show project envirnment (experimental)"
    [%map_open
      let _ = args (* ToDo: Remove this *)
      in
      fun () ->
        let open Satyrographos.Environment in
        let project_env = get_project_env () in
        printf !"%{sexp: project_env option}" project_env
    ]

let debug_command =
  Command.group ~summary:"SATySFi related utilities for debugging Satyrographos (experimental)"
    [ "depgraph", depgraph_command;
      "project-env", status_project_env;
    ]
