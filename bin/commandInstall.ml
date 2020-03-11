open Core


let install_command =
  let open Command.Let_syntax in
  let default_target_dir = Setup.default_target_dir in
  let readme () =
    sprintf "Install SATySFi Libraries to a directory environmental variable SATYSFI_RUNTIME has or %s. Currently it accepts an argument DIR, but this is experimental." default_target_dir
  in
  Command.basic
    ~summary:"Install SATySFi runtime"
    ~readme
    [%map_open
      let system_font_prefix = flag "system-font-prefix" (optional string) ~doc:"FONT_NAME_PREFIX Installing system fonts with names with the given prefix"
      and library_list = flag "library" (listed string) ~aliases:["l"] ~doc:"LIBRARY Library"
      and target_dir = anon (maybe_with_default default_target_dir ("DIR" %: string))
      and verbose = flag "verbose" no_arg ~doc:"Make verbose"
      and copy = flag "copy" no_arg ~doc:"Copy files instead of making symlinks"
      in
      fun () ->
        let libraries = match library_list with
          | [] -> None
          | xs -> Some xs in
        let env = Setup.read_environment () in
        Satyrographos_command.Install.install target_dir ~outf:Format.std_formatter ~system_font_prefix ~libraries ~verbose ~copy ~env ()
    ]
