open Core
open Satyrographos

module Process = Shexp_process
module P = Process

module StringMap = Map.Make(String)

let library_dir prefix (buildscript: BuildScript.m) =
  let libdir = Filename.concat prefix "share/satysfi" in
  Filename.concat libdir (BuildScript.get_name buildscript)

let read_module ~outf ~verbose ~build_module ~buildscript_path =
  let src_dir = Filename.dirname buildscript_path in
  let p = BuildScript.read_module ~src_dir build_module in
  if verbose
  then begin Format.fprintf outf "Read library:@.";
    [%sexp_of: Library.t] p |> Sexp.pp_hum outf;
    Format.fprintf outf "@."
  end;
  (src_dir, p)

let run_build_commands ~outf ~verbose ~libraries ~workingDir ~env buildCommands =
  let setup ~satysfi_dist =
    Install.install satysfi_dist ~outf ~system_font_prefix:None ~autogen_libraries:[] ~libraries ~verbose ~safe:true ~copy:false ~env ()
  in
  let commands satysfi_runtime = P.List.iter buildCommands ~f:(function
    | "make" :: args ->
      let command = P.run "make" (["SATYSFI_RUNTIME=" ^ satysfi_runtime] @ args) in
      ProcessUtil.redirect_to_stdout ~prefix:"make" command
    | "satysfi" :: args ->
      RunSatysfi.run_satysfi ~satysfi_runtime args
    | cmd -> failwithf "command %s is not yet supported" ([%sexp_of: string list] cmd |> Sexp.to_string) ()
  ) in
  P.(chdir workingDir (RunSatysfi.with_env ~outf ~setup commands))

let build_opam ~outf ~verbose ~prefix:_ ~build_module ~buildscript_path ~env =
  let src_dir, p = read_module ~outf ~verbose ~build_module ~buildscript_path in

  match build_module with
  | BuildScript.LibraryDoc build_module ->
    let context = Process.Context.create() in
    let workingDir = Filename.concat src_dir build_module.workingDirectory in
    let libraries = Library.Dependency.to_list p.dependencies |> Some in
    let _, trace =
      run_build_commands ~outf ~verbose ~workingDir ~libraries ~env build_module.build
      |> P.Traced.eval_exn ~context in
    if verbose
    then begin Format.fprintf outf "Executed commands:@.";
      Sexp.pp_hum_indent 2 Format.std_formatter trace;
      Format.fprintf outf "@."
    end
  | BuildScript.Library _ ->
    Format.fprintf outf "Building modules is not yet supported"

let install_opam ~outf ~verbose ~prefix ~build_module ~buildscript_path ~env:_ =
  let _, p = read_module ~outf ~verbose ~build_module ~buildscript_path in
  let dir = library_dir prefix build_module in
  Library.write_dir ~outf ~verbose ~symlink:false dir p

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
    Map.iteri s ~f:(fun ~key ~data ->
      Format.fprintf outf "Library %s:@." key;
      BuildScript.read_module ~src_dir data
      |> [%sexp_of: Library.t] |> Sexp.pp_hum outf;
      Format.fprintf outf "@.";)


let export f () =
  let s = BuildScript.load f in
  s |> BuildScript.export_opam

let with_build_script f ~outf ~prefix ~buildscript_path ~name ~verbose ~env () =
  let builsscript = BuildScript.load buildscript_path in
  match name with
  | None -> begin
    if StringMap.length builsscript = 1
    then let build_module = StringMap.nth_exn builsscript 0 |> snd in
      f ~outf ~verbose ~prefix ~build_module ~buildscript_path ~env
    else failwith "Please specify module name with -name option"
  end
  | Some name ->
    match StringMap.find builsscript name with
      | Some build_module ->
        f ~outf ~verbose ~prefix ~build_module ~buildscript_path ~env
      | _ ->
        failwithf "Build file does not contains library %s" name ()

