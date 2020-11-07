open Core

let lint_command =
  let open Command.Let_syntax in
  let open RenameOption in
  let readme () =
    sprintf {|Check validity of the library.|}
  in
  let env = Setup.read_environment () in
  let warning_expr_flag_type =
    Command.Arg_type.create (fun expr ->
        Satyrographos.Glob.parse_as_tm_exn (Lexing.from_string expr)
      )
  in
  Command.basic
    ~summary:"Check validity of the library"
    ~readme
    [%map_open
      let verbose = flag "--verbose" no_arg ~aliases:["v"] ~doc:"Verbose"
      and buildscript_path = flag "--script" (optional string) ~doc:"SCRIPT Install script"
      and satysfi_version = Satyrographos_satysfi.Version.flag
      and warning_expr = flag "W" (optional warning_expr_flag_type) ~doc:"WARNING_EXPR Enable/disable warnings. (e.g., “-lib/dep,-opam-file/version” disables warnings related to library dependencies and OPAM package versions; “opam-file/lint/{-*,+3..5}” disables all the OPAM lint warnings except warnings 3 through 5)"
      in
      fun () ->
        let exit_code =
          Satyrographos_command.Lint.lint
            ~env
            ~satysfi_version
            ~outf:Format.std_formatter
            ~buildscript_path
            ~warning_expr
            ~verbose
        in
        reprint_err_warn ();
        exit exit_code
    ]
