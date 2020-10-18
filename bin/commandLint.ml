open Core

let lint_command =
  let open Command.Let_syntax in
  let open RenameOption in
  let readme () =
    sprintf {|Check validity of the library.|}
  in
  let env = Setup.read_environment () in
  Command.basic
    ~summary:"Check validity of the library"
    ~readme
    [%map_open
      let verbose = flag "--verbose" no_arg ~aliases:["v"] ~doc:"Verbose"
      and buildscript_path = flag "--script" (optional string) ~doc:"SCRIPT Install script"
      and satysfi_version = Satyrographos_satysfi.Version.flag
      in
      fun () ->
        Compatibility.optin ();
        let exit_code =
          Satyrographos_command.Lint.lint
            ~env
            ~satysfi_version
            ~outf:Format.std_formatter
            ~buildscript_path
            ~verbose
        in
        reprint_err_warn ();
        exit exit_code
    ]
