open Core

module StringMap = Map.Make(String)

let outf = Format.std_formatter

let default_script_path () =
  Filename.concat (FileUtil.pwd ()) "Satyristes"

let lockdown_file_path ~buildscript_path =
  FilePath.concat
    (FilePath.dirname buildscript_path)
    "lockdown.yaml"

let lockdown_save_command =
  let open Command.Let_syntax in
  let open RenameOption in
  let _outf = Format.std_formatter in
  Command.basic
    ~summary:"Save the current environment to the lockdown file (experimental)"
    [%map_open
      let script = flag "--script" (optional string) ~doc:"SCRIPT Install script"
      and verbose = flag  "--verbose" no_arg ~doc:"Make verbose"
      in
      Compatibility.optin ();
      let buildscript_path = Option.value ~default:(default_script_path ()) script in
      let _build_dir =
        FilePath.concat
          (FilePath.dirname buildscript_path)
          "_build"
        |> Option.some
      in
      let env = Setup.read_environment () in
      (fun () ->
         Satyrographos_command.Lockdown.save_lockdown
           ~verbose
           ~env
           ~buildscript_path;
         reprint_err_warn ())
    ]

let lockdown_restore_command =
  let open Command.Let_syntax in
  let open RenameOption in
  let _outf = Format.std_formatter in
  Command.basic
    ~summary:"Restore the environment from the lockdown file (experimental)"
    [%map_open
      let script = flag "--script" (optional string) ~doc:"SCRIPT Install script"
      and verbose = flag  "--verbose" no_arg ~doc:"Make verbose"
      in
      Compatibility.optin ();
      let buildscript_path = Option.value ~default:(default_script_path ()) script in
      let env = Setup.read_environment () in
      (fun () ->
         Satyrographos_command.Lockdown.restore_lockdown
           ~verbose
           ~env
           ~buildscript_path;
         reprint_err_warn ())
    ]

let lockdown_command =
  Command.group ~summary:"Manage the lockdown file (experimental)"
    [ "save", lockdown_save_command;
      "restore", lockdown_restore_command;
    ]
