open Core
open Satyrographos

module P = Shexp_process
module OW = Satyrographos.OpamWrapper

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

let build_cmd ~outf ~build_dir ~verbose ~build_module ~buildscript_path ~system_font_prefix ~env =
  let src_dir, p = read_module ~outf ~verbose ~build_module ~buildscript_path in
  let libraries = Library.Dependency.to_list p.dependencies |> Some in
  let autogen_libraries = Library.Dependency.to_list p.autogen in
  let with_build_dir build_dir c =
    let satysfi_runtime_dir = FilePath.concat build_dir "satysfi" in
    let open P.Infix in
    P.return ()
    >>| (fun () ->
        setup_project_env ~satysfi_runtime_dir ~buildscript_path ~outf ~verbose ~libraries ~env ~system_font_prefix ~autogen_libraries)
    >>= c
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

  let with_working_dir workingDirectory build_commands =
    let workingDir = Filename.concat src_dir workingDirectory in
    with_project_env (fun project_env ->
        run_build_commands ~workingDir ~project_env build_commands)
  in

  match build_module with
  | BuildScript.Doc build_module ->
    with_working_dir build_module.workingDirectory build_module.build
  | BuildScript.LibraryDoc build_module ->
    with_working_dir build_module.workingDirectory build_module.build
  | BuildScript.Library _ ->
    P.return ()

let build ~outf ~build_dir ~verbose ~build_module ~buildscript_path ~system_font_prefix ~env =
  let context = P.Context.create() in
  let _, trace =
    build_cmd ~outf ~build_dir ~verbose ~build_module ~buildscript_path ~system_font_prefix ~env
    |> P.Traced.eval_exn ~context in
  if verbose
  then begin Format.fprintf outf "Executed commands:@.";
    Sexp.pp_hum_indent 2 Format.std_formatter trace;
    Format.fprintf outf "@."
  end


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
          >> P.set_env "OPAMSOLVERTIMEOUT" "0" (
            P.run "opam" ["reinstall"; "--verbose"; "--yes"; "--"; workdir cwd]
          )
        )
    )

let instal_dependencies_opam_cmd ~(build_module:BuildScript.m) =
  let opam_dependencies d =
    d
    |> Library.Dependency.to_list
    |> List.map ~f:(fun name -> "satysfi-" ^ name)
  in
  match BuildScript.get_dependencies_opt build_module with
  | Some dependencies ->
    let open P.Infix in
    P.echo (Printf.sprintf !"== Install dependencies: %{sexp: Library.Dependency.t}" dependencies)
    >> (["install"; "--yes"] @ opam_dependencies dependencies
        |> P.run "opam")
  | None ->
    P.return ()

let build_command ~outf ~buildscript_path ~names ~verbose ~env =
  let f ~buildscript ~build_modules ~build_dir =
    let system_font_prefix = None in
    let open P.Infix in
    let module_names =
      build_modules
    |> List.map ~f:BuildScript.get_name
    in
    P.echo ("= Pin projects")
    >> opam_pin_project ~buildscript ~buildscript_path
    >> P.echo (Printf.sprintf !"\n= Build modules: %{sexp: string list}" module_names)
    >> P.List.iter build_modules ~f:(fun build_module ->
        begin match build_module with
          | BuildScript.Doc _ ->
            P.echo ("\n== Build module " ^ BuildScript.get_name build_module)
            >> instal_dependencies_opam_cmd ~build_module
            >> P.echo ("=== Build docs")
            >> build_cmd ~outf ~verbose ~build_module ~buildscript_path ~system_font_prefix ~env ~build_dir
            >> P.echo "================"
          | _ ->
            P.return ()
        end
      )
    |> P.eval
  in
  let buildscript = BuildScript.load buildscript_path in
  let module_map = BuildScript.get_module_map buildscript in
  match names with
  | None -> begin
      let build_modules = Map.data module_map in
      f ~buildscript ~build_modules
    end
  | Some names ->
    match List.map names ~f:(Map.find_or_error module_map) |> Or_error.all with
    | Result.Ok build_modules ->
      f ~buildscript ~build_modules
    | Result.Error err ->
      failwithf "Build file does not contains library %s" (Error.to_string_hum err) ()
