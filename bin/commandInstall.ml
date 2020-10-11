open Core


let install_command =
  let open Command.Let_syntax in
  let open RenameOption in
  let default_target_dir = Setup.default_target_dir in
  let readme () =
    sprintf "Install SATySFi Libraries to a directory environmental variable SATYSFI_RUNTIME has or %s. Currently it accepts an argument DIR, but this is experimental." default_target_dir
  in
  Command.basic
    ~summary:"Install SATySFi runtime"
    ~readme
    [%map_open
      let system_font_prefix = long_flag_optional "system-font-prefix" string ~doc_arg:"FONT_NAME_PREFIX" ~doc:"Installing system fonts with names with the given prefix."
      and autogen_library_list = long_flag_listed "autogen" string ~aliases:["a"] ~doc_arg:"AUTOGEN" ~doc:"Enable non-default autogen libraries (e.g., %libraries) (EXPERIMENTAL)"
      and library_list = long_flag_listed "library" string ~aliases:["l"] ~doc_arg:"LIBRARY" ~doc:"Library"
      and target_dir_old = anon (maybe ("DIR" %: string))
      and target_dir = long_flag_optional "output" string ~doc_arg:"DIR" ~doc:("Install files to (default: " ^ default_target_dir ^ ")")
      and verbose = long_flag_bool "verbose" no_arg ~doc:"Make verbose"
      and copy = long_flag_bool "copy" no_arg ~doc:"Copy files instead of making symlinks"
      in
      fun () ->
        let target_dir =
          let deprecation_warning () =
            print_err_warn
              "Anonymous argument DIR has been deprecated. Use “--output” instead."
          in
          match target_dir_old, target_dir with
            | Some value, None ->
              deprecation_warning ();
              value
            | Some _, Some value ->
              deprecation_warning ();
              Printf.sprintf
                "Both Anonymous argument and “--output” option are specified. Deprecated one is ignored."
              |> print_err_warn;
              value
            | None, Some value ->
              value
            | None, None ->
              default_target_dir
        in
        if not (List.is_empty autogen_library_list)
        then Compatibility.optin ();
        let libraries = match library_list with
          | [] -> None
          | xs -> Some xs in
        let env = Setup.read_environment () in
        Satyrographos_command.Install.install
          target_dir
          ~outf:Format.std_formatter
          ~system_font_prefix
          ~autogen_libraries:autogen_library_list
          ~libraries
          ~verbose
          ~copy
          ~env
          ();
        reprint_err_warn ()
    ]
