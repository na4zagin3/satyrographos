open Core

module StringMap = Map.Make(String)

let outf = Format.std_formatter

let default_script_path () =
  Filename.concat (FileUtil.pwd ()) "Satyristes"

let build_command =
  let open Command.Let_syntax in
  let open RenameOption in
  let outf = Format.std_formatter in
  Command.basic
    ~summary:"Build modules (experimental)"
    [%map_open
      let script = flag "--script" (optional string) ~doc:"SCRIPT Install script"
      and name = anon (maybe ("MODULE_NAME" %: string))
      and verbose = flag  "--verbose" no_arg ~doc:"Make verbose"
      in
      Compatibility.optin ();
      let buildscript_path = Option.value ~default:(default_script_path ()) script in
      let build_dir =
        FilePath.concat
          (FilePath.dirname buildscript_path)
          "_build"
        |> Option.some
      in
      let env = Setup.read_environment () in
      (fun () ->
         Satyrographos_command.Build.build_command ~outf ~build_dir ~buildscript_path ~name ~verbose ~env;
         reprint_err_warn ())
    ]
