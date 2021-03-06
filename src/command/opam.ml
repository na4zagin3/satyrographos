open Core
open Satyrographos

module StringMap = Map.Make(String)

let library_dir prefix (buildscript: BuildScript.m) =
  let libdir = Filename.concat prefix "share/satysfi" in
  Filename.concat libdir (BuildScript.get_name buildscript)

let build_opam ~outf ~verbose ~prefix:_ ~satysfi_version:_ ~script_version:_ ~build_module ~buildscript_path ~env =
  let system_font_prefix = None in
  Build.build
    ~outf
    ~verbose
    ~build_module
    ~buildscript_path
    ~build_dir:None
    ~system_font_prefix
    ~env

let install_opam ~outf ~verbose ~prefix ~satysfi_version ~script_version ~build_module ~buildscript_path ~env:_ =
  let _, p = Build.read_module ~outf ~verbose ~build_module ~buildscript_path in
  let dir = library_dir prefix build_module in
  let migrate build_module =
    Satyrographos_satysfi.Migration.migrate ~outf
      script_version
      satysfi_version
      build_module
  in
  p
  |> migrate
  |> Library.write_dir ~outf ~verbose ~symlink:false dir

let uninstall_opam ~outf:_ ~verbose:_ ~prefix ~build_module ~buildscript_path:_ ~env:_ =
  let dir = library_dir prefix build_module in
  FileUtil.(rm ~force:Force ~recurse:true [dir])

let buildfile ~outf ~process f () =
  let s = BuildScript.load f in
  Format.fprintf outf "Build file:@.";
  s |> [%sexp_of: BuildScript.t] |> Sexp.pp_hum outf;
  Format.fprintf outf "@.";
  if process
  then
    let src_dir = Filename.dirname f in
    BuildScript.get_module_map s
    |> Map.iteri  ~f:(fun ~key ~data ->
      Format.fprintf outf "Library %s:@." key;
      BuildScript.read_module ~src_dir data
      |> [%sexp_of: Library.t] |> Sexp.pp_hum outf;
      Format.fprintf outf "@.";)


let export f () =
  let s = BuildScript.load f in
  BuildScript.get_module_map s
  |> BuildScript.export_opam

let with_build_script f ~outf ~prefix ?(satysfi_version=Satyrographos_satysfi.Version.latest_version) ~buildscript_path ~name ~verbose ~env () =
  let buildscript = BuildScript.load buildscript_path in
  let script_version = BuildScript.buildscript_version buildscript in
  let module_map = BuildScript.get_module_map buildscript in
  match name with
  | None -> begin
    if StringMap.length module_map = 1
    then let build_module = StringMap.nth_exn module_map 0 |> snd in
      f ~outf ~verbose ~prefix ~satysfi_version ~script_version ~build_module ~buildscript_path ~env
    else failwith "Please specify module name with -name option"
  end
  | Some name ->
    match StringMap.find module_map name with
      | Some build_module ->
        f ~outf ~verbose ~prefix ~satysfi_version ~script_version ~build_module ~buildscript_path ~env
      | _ ->
        failwithf "Build file does not contains library %s" name ()
