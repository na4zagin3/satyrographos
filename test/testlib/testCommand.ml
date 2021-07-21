let test_lint_command ?(f=fun cwd -> cwd, None) ?(satysfi_files=[]) ?(satysfi_version=Satyrographos_satysfi.Version.Satysfi_0_0_5) ?warning_expr ?opam_libs files =
  let outf = Format.std_formatter in
  let open Shexp_process in
  let open Shexp_process.Infix in
  let test_cmd env =
    Shexp_process.cwd_logical
    >>= fun cwd ->
    TestLib.run_function (fun ~outf ->
        let cwd, path = f cwd in
        Unix.chdir cwd;
        let (_: int) =
          Satyrographos_command.Lint.lint ~env ~outf ~warning_expr ~satysfi_version ~verbose:false ~buildscript_path:path
        in ()
      )
in
  let test_cmd work_dir reg_dir =
    let open Satyrographos in
    let opam_dir = FilePath.concat reg_dir "opam-satysfi" in
    let bin_dir = FilePath.concat reg_dir "bin" in
    let dist_library_dir = FilePath.concat reg_dir "satysfi/dist" in
    let create_opam_reg libs =
      mkdir opam_dir
      >> return libs
      >>= List.iter ~f:(fun (lib: Library.t) ->
          match lib.name with
          | None -> return ()
          | Some name ->
            let lib_dir = FilePath.concat opam_dir name in
            Library.write_dir ~outf lib_dir lib
            |> return
        )
    in
    let env () =
      Environment.{
        opam_switch = None;
        opam_reg = OpamSatysfiRegistry.read opam_dir;
        dist_library_dir=Some dist_library_dir
      }
    in
    mkdir ~p:() dist_library_dir
    >> (Option.map create_opam_reg opam_libs |> Option.value ~default:(return ()))
    >> TestLib.prepare_files work_dir files
    >> TestLib.prepare_files reg_dir satysfi_files
    >>| env
    >>= (fun env ->
        Shexp_process.chdir work_dir (test_cmd env)
        |> TestLib.with_bin_dir bin_dir)
  in
  with_temp_dir ~prefix:"Satyrographos" ~suffix:"test_library" (fun test_dir ->
      with_temp_dir ~prefix:"Satyrographos" ~suffix:"test_library_regs" (test_cmd test_dir)
    )
  |> Shexp_process.eval
