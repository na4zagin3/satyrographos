open Satyrographos
open Core


module StringMap = Map.Make(String)

let package_dir prefix buildscript =
  let libdir = Filename.concat prefix "share/satysfi" in
  Filename.concat libdir buildscript.BuildScript.name

let install_opam ~verbose ~prefix ~build_module ~buildscript_path =
  let src_dir = Filename.dirname buildscript_path in
  let p = BuildScript.read_package ~src_dir build_module in
  if verbose then [%sexp_of: Package.t] p |> Sexp.to_string_hum |> Printf.printf "Read package:\n%s\n";
  let dir = package_dir prefix build_module in
  Package.write_dir ~verbose ~symlink:false dir p

let uninstall_opam ~verbose:_ ~prefix ~build_module ~buildscript_path:_ =
  let dir = package_dir prefix build_module in
  FileUtil.(rm ~force:Force ~recurse:true [dir])

let default_script_path () =
  Filename.concat (FileUtil.pwd ()) "Satyristes"

let opam_with_build_module_command f =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Install module into OPAM registory (experimental)"
    [%map_open
      let prefix = flag "prefix" (required string) ~doc:"PREFIX Install destination"
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
          then f ~verbose ~prefix ~build_module:(StringMap.nth_exn builsscript 0 |> snd) ~buildscript_path
          else failwith "Please specify module name with -name option"
        end
        | Some name ->
          StringMap.find builsscript name
          |> Option.value_exn ~message:"Build file does not contains modules with the given name"
          |> (fun build_module -> f ~verbose ~prefix ~build_module ~buildscript_path)
    ]

let opam_install_command =
  opam_with_build_module_command install_opam

let opam_uninstall_command =
  opam_with_build_module_command uninstall_opam

let buildfile f () =
  Compatibility.optin ();
  let s = BuildScript.from_file f in
  s |> [%sexp_of: BuildScript.t] |> Sexp.to_string_hum
  |> Printf.printf "Build file: %s\n"

let opam_buildfile_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Inspect build file (experimental)"
    [%map_open
      let f = anon ("BUILD_FILE" %: string) (* ToDo: Remove this *)
      in
      fun () ->
        buildfile f ()
    ]

let export f () =
  Compatibility.optin ();
  let s = BuildScript.from_file f in
  s |> BuildScript.export_opam

let opam_export_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Export build file (experimental)"
    [%map_open
      let f = anon ("BUILD_FILE" %: string) (* ToDo: Remove this *)
      in
      fun () ->
        export f ()
    ]

let opam_command =
  Command.group ~summary:"OPAM related functionalities (experimental)"
    [ "install", opam_install_command;
      "uninstall", opam_uninstall_command;
      "buildfile", opam_buildfile_command;
      "export", opam_export_command;
    ]
