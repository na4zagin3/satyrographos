open Core
open Satyrographos

module P = Shexp_process

let read_module ~outf ~verbose ~build_module ~buildscript_path =
  let src_dir = Filename.dirname buildscript_path in
  let p = BuildScript.read_module ~src_dir build_module in
  if verbose
  then begin Format.fprintf outf "Read library:@.";
    [%sexp_of: Library.t] p |> Sexp.pp_hum outf;
    Format.fprintf outf "@."
  end;
  (src_dir, p)

let parse_build_command ~satysfi_runtime = function
  | BuildScript.Run (cmd, args) ->
    P.run cmd args
  | BuildScript.Make args ->
    P.run "make" args
  | BuildScript.MakeWithEnvVar args ->
    P.run "make" (["SATYSFI_RUNTIME=" ^ satysfi_runtime] @ args)
  | BuildScript.Satysfi args ->
    RunSatysfi.run_satysfi_command ~satysfi_runtime args
  | BuildScript.OMake args ->
    P.run "omake" args

let run_build_commands ~workingDir ~project_env buildCommands =
  let commands satysfi_runtime = P.List.iter buildCommands ~f:(parse_build_command ~satysfi_runtime) in
  Satyrographos.Environment.get_satysfi_runtime_dir project_env
  |> commands
  |> Satyrographos.Environment.set_project_env_cmd project_env
  |> P.chdir workingDir

let setup_project_env ~buildscript_path ~satysfi_runtime_dir ~outf ~verbose ~libraries ~env ~system_font_prefix ~autogen_libraries =
  let project_env =
    Satyrographos.Environment.{
      buildscript_path;
      satysfi_runtime_dir;
    }
  in
  let satysfi_dist =
    Satyrographos.Environment.get_satysfi_dist_dir project_env
  in
  let persistent_autogen =
    Lockdown.load_lockdown_file ~buildscript_path
    |> Option.value_map ~default:[] ~f:(fun lockdown -> lockdown.Satyrographos_lockdown.LockdownFile.autogen)
  in
  Library.mark_managed_dir satysfi_dist;
  Install.install satysfi_dist ~outf ~system_font_prefix ~persistent_autogen ~autogen_libraries ~libraries ~verbose ~safe:true ~copy:false ~env ();
  project_env

let build ~outf ~build_dir ~verbose ~build_module ~buildscript_path ~system_font_prefix ~env =
  let src_dir, p = read_module ~outf ~verbose ~build_module ~buildscript_path in
  let libraries = Library.Dependency.to_list p.dependencies |> Some in
  let autogen_libraries = Library.Dependency.to_list p.autogen in
  let with_build_dir build_dir c =
    let satysfi_runtime_dir = FilePath.concat build_dir "satysfi" in
    let project_env =
      setup_project_env ~satysfi_runtime_dir ~buildscript_path ~outf ~verbose ~libraries ~env ~system_font_prefix ~autogen_libraries
    in
    c project_env
  in
  let with_project_env c =
    match build_dir with
    | None ->
      Shexp_process.with_temp_dir ~prefix:"Satyrographos" ~suffix:"build" (fun build_dir ->
          with_build_dir build_dir c
        )
    | Some build_dir ->
      with_build_dir build_dir c
  in

  let build workingDirectory build_commands =
    let context = P.Context.create() in
    let workingDir = Filename.concat src_dir workingDirectory in
    let _, trace =
      with_project_env (fun project_env ->
          run_build_commands ~workingDir ~project_env build_commands)
      |> P.Traced.eval_exn ~context in
    if verbose
    then begin Format.fprintf outf "Executed commands:@.";
      Sexp.pp_hum_indent 2 Format.std_formatter trace;
      Format.fprintf outf "@."
    end
  in

  match build_module with
  | BuildScript.Doc build_module ->
    build build_module.workingDirectory build_module.build
  | BuildScript.LibraryDoc build_module ->
    build build_module.workingDirectory build_module.build
  | BuildScript.Library _ ->
    ()


let opam_pin_project ~(buildscript: BuildScript.t) ~buildscript_path =
  let open P.Infix in
  let workdir cwd =
    FilePath.make_absolute cwd buildscript_path
    |> FilePath.dirname
  in
  P.cwd_logical >>= fun cwd ->
  let module_map =
    BuildScript.get_module_map buildscript
  in
  Map.to_alist module_map
  |> P.List.iter ~f:(fun (_, l) ->
      BuildScript.get_opam_opt l
      |> Option.value_map ~default:(P.return ()) ~f:(fun opam_path ->
          let basedir = workdir cwd in
          let opam =
            OpamFilename.create (OpamFilename.Dir.of_string basedir) (OpamFilename.Base.of_string opam_path)
            |> OpamFile.make
            |> OpamFile.OPAM.read
          in
          let opam_name =
            Lint.get_opam_name ~opam ~opam_path
          in
          P.run "opam" ["pin"; "add"; "--no-action"; "--yes"; opam_name; "file://" ^ workdir cwd]
          >> P.run "opam" ["reinstall"; workdir cwd]
        )
    )


let build_command ~outf ~buildscript_path ~name ~verbose ~env =
  let f ~buildscript ~build_module ~build_dir =
    let system_font_prefix = None in
    opam_pin_project ~buildscript ~buildscript_path
    |> P.eval ;
    Format.fprintf outf "@.================@.";
    build ~outf ~verbose ~build_module ~buildscript_path ~system_font_prefix ~env ~build_dir;
    Format.fprintf outf "@.================@."
  in
  let buildscript = BuildScript.load buildscript_path in
  let module_map = BuildScript.get_module_map buildscript in
  match name with
  | None -> begin
      if Map.length module_map = 1
      then let build_module = Map.nth_exn module_map 0 |> snd in
        f ~buildscript ~build_module
      else failwith "Please specify module name"
    end
  | Some name ->
    match Map.find module_map name with
    | Some build_module ->
      f ~buildscript ~build_module
    | _ ->
      failwithf "Build file does not contains library %s" name ()
