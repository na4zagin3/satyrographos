let test_lint_command ?(f=fun cwd -> cwd, None) files =
  let open Shexp_process in
  let open Shexp_process.Infix in
  let test_cmd =
    Shexp_process.cwd_logical
    >>= fun cwd ->
    TestLib.run_function (fun ~outf ->
        let cwd, path = f cwd in
        Unix.chdir cwd;
        Satyrographos_command.Lint.lint ~outf ~verbose:false ~buildscript_path:path)
  in
  let test_cmd test_dir =
    TestLib.prepare_files test_dir files
    >> Shexp_process.chdir test_dir test_cmd
  in
  with_temp_dir ~prefix:"Satyrographos" ~suffix:"test_library" test_cmd
  |> Shexp_process.eval
