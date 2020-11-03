open Core

let satysfi_command =
  let open Command.Let_syntax in
  let readme () =
    sprintf "Run SATySFi with installed or specified SATySFi Libraries. (EXPERIMENTAL)"
  in
  Command.basic
    ~summary:"Run SATySFi"
    ~readme
    [%map_open
      let use_system_fonts = flag "--use-system-fonts" no_arg ~doc:"Installing system fonts with names with prefix “system:”"
      and autogen_library_list = flag "--autogen" (listed string) ~aliases:["a"] ~doc:"AUTOGEN Enable non-default autogen libraries (e.g., %libraries) (EXPERIMENTAL)"
      and library_list = flag "--library" (listed string) ~aliases:["l"] ~doc:"LIBRARY Library"
      and verbose = flag "--verbose" no_arg ~doc:"Make verbose"
      and satysfi_args = flag "--" escape ~doc:"ARGS... Satysfi arguments"
      in
      fun () ->
        Compatibility.optin ();
        if not (List.is_empty autogen_library_list)
        then Compatibility.optin ();
        let libraries = match library_list with
          | [] -> None
          | xs -> Some xs in
        let env = Setup.read_environment () in
        let outf = Format.std_formatter in
        match satysfi_args with
        | Some args ->
          let project_env = Satyrographos.Environment.get_project_env () in
          let cmd =
            Satyrographos_command.RunSatysfi.satysfi_command
              ~outf
              ~project_env
              ~system_font_prefix:(Option.some_if use_system_fonts Satyrographos_autogen.FontsSystem.system_font_prefix)
              ~autogen_libraries:autogen_library_list
              ~libraries
              ~verbose
              ~env
              args
          in
          let context = Shexp_process.Context.create() in
          let result, trace =
            Shexp_process.Traced.eval_exn ~context cmd
          in
          if verbose
          then begin Format.fprintf outf "Executed commands:@.";
            Sexp.pp_hum_indent 2 Format.std_formatter trace;
            Format.fprintf outf "@."
          end;
          exit result
        | None ->
          Format.fprintf outf "Specify arguments for SATySFi after “--”@."
    ]
