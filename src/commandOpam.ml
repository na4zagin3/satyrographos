open Core

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

let test_satysfi_option options =
  let open P in
  run_exit_code "satysfi" (options @ ["--version"])
  |> map ~f:(fun code -> code = 0)

let assert_satysfi_option ~message options =
  let open P in
  test_satysfi_option options
  |> map ~f:(function
    | true -> ()
    | false -> failwith message)

let assert_satysfi_option_C dir =
  assert_satysfi_option ~message:"satysfi.0.0.3+dev2019.02.27 and newer is required in order to build library docs."
    ["-C"; dir]

let run_build_commands ~outf ~verbose ~libraries ~workingDir ~env buildCommands =
  let open P in
  let open P.Infix in
  let commands satysfi_runtime = P.List.iter buildCommands ~f:(function
    | "make" :: args -> P.run "make" (["SATYSFI_RUNTIME=" ^ satysfi_runtime] @ args)
    | "satysfi" :: args ->
      assert_satysfi_option_C satysfi_runtime
      >> P.run "satysfi" (["-C"; satysfi_runtime] @ args)
    | cmd -> failwithf "command %s is not yet supported" ([%sexp_of: string list] cmd |> Sexp.to_string) ()
  ) in
  let with_env c =
    let c satysfi_runtime =
      return (Format.fprintf outf "Setting up SATySFi env at %s @." satysfi_runtime;) >>
      let satysfi_dist = Filename.concat satysfi_runtime "dist" in
      return (Library.mark_managed_dir satysfi_dist;) >>
      return (
        let library_map = CommandInstall.get_libraries ~outf ~maybe_reg:None ~env ~libraries in
        CommandInstall.install_libraries satysfi_dist ~outf ~library_map ~verbose ~copy:false ()) >>
      c satysfi_runtime
    in
    with_temp_dir ~prefix:"Satyrographos" ~suffix:"build_opam" c
  in
  P.(chdir workingDir (with_env commands))

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
  let s = BuildScript.from_file f in
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
  let s = BuildScript.from_file f in
  s |> BuildScript.export_opam

let with_build_script f ~outf ~prefix ~buildscript_path ~name ~verbose ~env () =
  let builsscript = BuildScript.from_file buildscript_path in
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

