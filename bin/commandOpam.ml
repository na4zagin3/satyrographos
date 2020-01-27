open Satyrographos
open Core

module Process = Shexp_process
module P = Process

module StringMap = Map.Make(String)

let default_script_path () =
  Filename.concat (FileUtil.pwd ()) "Satyristes"

let opam_with_build_module_command ~prefix_optionality f =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Install module into OPAM registory (experimental)"
    [%map_open
      let prefix = flag "prefix" (prefix_optionality string) ~doc:"PREFIX Install destination"
      and script = flag "script" (optional string) ~doc:"SCRIPT Install script"
      and name = flag "name" (optional string) ~doc:"MODULE_NAME Module name"
      and verbose = flag "verbose" no_arg ~doc:"Make verbose"
      in
      fun () ->
        let buildscript_path = Option.value ~default:(default_script_path ()) script in
        let builsscript = BuildScript.from_file buildscript_path in
        match name with
        | None -> begin
          if StringMap.length builsscript = 1
          then let build_module = StringMap.nth_exn builsscript 0 |> snd in
            f ~verbose ~prefix ~build_module ~buildscript_path ~opam_reg:Setup.reg_opam
          else failwith "Please specify module name with -name option"
        end
        | Some name ->
          match StringMap.find builsscript name with
            | Some build_module -> f ~verbose ~prefix ~build_module ~buildscript_path ~opam_reg:Setup.reg_opam
            | _ ->
              failwithf "Build file does not contains library %s" name ()
    ]

let opam_build_command =
  opam_with_build_module_command ~prefix_optionality:Command.Param.optional CommandOpam.build_opam

let opam_install_command =
  opam_with_build_module_command ~prefix_optionality:Command.Param.required CommandOpam.install_opam

let opam_uninstall_command =
  opam_with_build_module_command ~prefix_optionality:Command.Param.required CommandOpam.uninstall_opam

let opam_buildfile_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Inspect build file (experimental)"
    [%map_open
      let f = anon ("BUILD_FILE" %: string) (* ToDo: Remove this *)
      and process = flag "process" no_arg ~doc:"Process the script"
      in
      fun () ->
        Compatibility.optin ();
        CommandOpam.buildfile ~process f ()
    ]

let opam_export_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Export build file (experimental)"
    [%map_open
      let f = anon ("BUILD_FILE" %: string) (* ToDo: Remove this *)
      in
      fun () ->
        Compatibility.optin ();
        CommandOpam.export f ()
    ]

let opam_command =
  Command.group ~summary:"OPAM related functionalities (experimental)"
    [ "build", opam_build_command;
      "install", opam_install_command;
      "uninstall", opam_uninstall_command;
      "buildfile", opam_buildfile_command;
      "export", opam_export_command;
    ]
