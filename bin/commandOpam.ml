open Satyrographos
open Core


module StringMap = Map.Make(String)

let package_dir prefix buildscript =
  let libdir = Filename.concat prefix "share/satysfi" in
  Filename.concat libdir buildscript.BuildScript.name

let install_dir verbose dir files =
  FileUtil.(mkdir ~parent:true dir);
  List.iter files ~f:(fun (dst, src) ->
    if FileUtil.(test Exists src)
    then let dst = (Filename.concat dir dst) in
      if verbose then Printf.printf "Copying %s to %s\n" src dst;
      FileUtil.(cp ~follow:Follow ~recurse:true ~force:Force [src] dst)
    else failwithf "%s does not exist\n" src ()
  )

let install_dir_if_exists verbose dir files =
  if not (List.is_empty files)
  then install_dir verbose dir files

let install_opam verbose prefix buildscript =
  let dir = package_dir prefix buildscript in
  FileUtil.(rm ~force:Force ~recurse:true [dir]);
  install_dir_if_exists verbose (Filename.concat dir "fonts") buildscript.sources.fonts;
  install_dir_if_exists verbose (Filename.concat dir "hash") buildscript.sources.hashes;
  install_dir_if_exists verbose (Filename.concat dir "package") buildscript.sources.packages;
  install_dir_if_exists verbose (Filename.concat dir "files") buildscript.sources.files

let uninstall_opam _ prefix buildscript =
  let dir = package_dir prefix buildscript in
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
        let bs = Option.value ~default:(default_script_path ()) script
          |> BuildScript.from_file
        in
        match name with
        | None -> begin
          if StringMap.length bs = 1
          then f verbose prefix (StringMap.nth_exn bs 0 |> snd)
          else failwith "Please specify module name with -name option"
        end
        | Some name ->
          StringMap.find bs name
          |> Option.value_exn ~message:"Build file does not contains modules with the given name"
          |> f verbose prefix
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
