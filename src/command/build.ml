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
      | "make" :: args ->
        let command = P.run "make" (["SATYSFI_RUNTIME=" ^ satysfi_runtime] @ args) in
        ProcessUtil.redirect_to_stdout ~prefix:"make" command
      | "satysfi" :: args ->
        RunSatysfi.run_satysfi ~satysfi_runtime args
      | cmd -> failwithf "command %s is not yet supported" ([%sexp_of: string list] cmd |> Sexp.to_string) ()

let run_build_commands ~outf ~verbose ~libraries ~workingDir ~env ~system_font_prefix ~autogen_libraries buildCommands =
  let setup ~satysfi_dist =
    Install.install satysfi_dist ~outf ~system_font_prefix ~autogen_libraries ~libraries ~verbose ~safe:true ~copy:false ~env ()
  in
  let commands satysfi_runtime = P.List.iter buildCommands ~f:(parse_build_command ~satysfi_runtime) in
  P.(chdir workingDir (RunSatysfi.with_env ~outf ~setup commands))

let build ~outf ~verbose ~build_module ~buildscript_path ~system_font_prefix ~autogen_libraries ~env =
  let src_dir, p = read_module ~outf ~verbose ~build_module ~buildscript_path in

  let build workingDirectory build_commands =
    let context = P.Context.create() in
    let workingDir = Filename.concat src_dir workingDirectory in
    let libraries = Library.Dependency.to_list p.dependencies |> Some in
    let _, trace =
      run_build_commands ~outf ~verbose ~workingDir ~libraries ~system_font_prefix ~autogen_libraries ~env build_commands
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
  Map.to_alist buildscript
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
          P.run "opam" ["pin"; "add"; "--yes"; opam_name; "file://" ^ workdir cwd]
        )
    )


let build_command ~outf ~buildscript_path ~name ~verbose ~env =
  let f ~buildscript~build_module =
    let system_font_prefix = None in
    let autogen_libraries = [] in
    opam_pin_project ~buildscript ~buildscript_path
    |> P.eval ;
    build ~outf ~verbose ~build_module ~buildscript_path ~system_font_prefix ~autogen_libraries ~env
  in
  let buildscript = BuildScript.load buildscript_path in
  match name with
  | None -> begin
      if Map.length buildscript = 1
      then let build_module = Map.nth_exn buildscript 0 |> snd in
        f ~buildscript ~build_module
      else failwith "Please specify module name"
    end
  | Some name ->
    match Map.find buildscript name with
    | Some build_module ->
      f ~buildscript ~build_module
    | _ ->
      failwithf "Build file does not contains library %s" name ()
