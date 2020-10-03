open Core

let lint_command =
  let open Command.Let_syntax in
  let open RenameOption in
  let readme () =
    sprintf {|Check validity of the library.|}
  in
  Command.basic
    ~summary:"Check validity of the library"
    ~readme
    [%map_open
      let verbose = flag "--verbose" no_arg ~aliases:["v"] ~doc:"Verbose"
      and buildscript_path = flag "--script" (optional string) ~doc:"SCRIPT Install script"
      in
      fun () ->
        Compatibility.optin ();
        Satyrographos_command.Lint.lint
          ~outf:Format.std_formatter
          ~buildscript_path
          ~verbose;
        reprint_err_warn ()
    ]
