module StdList = List

open Satyrographos_testlib
open TestLib

open Shexp_process

let files =
  Command_lockdown_save__opam.files

let opam_response = {
  PrepareBin.list_result = {|***,invalid,response,!!!|}
}

let env ~dest_dir:_ ~temp_dir : Satyrographos.Environment.t t =
  let open Shexp_process.Infix in
  let pkg_dir = FilePath.concat temp_dir "pkg" in
  let prepare_pkg =
    PrepareDist.empty pkg_dir
    >> prepare_files pkg_dir files
  in
  let empty_dist = FilePath.concat temp_dir "empty_dist" in
  let prepare_dist = PrepareDist.empty empty_dist in
  let opam_reg = FilePath.concat temp_dir "opam_reg" in
  let log_file = exec_log_file_path temp_dir in
  let prepare_opam_reg =
    PrepareOpamReg.(prepare opam_reg theanoFiles)
    >> PrepareOpamReg.(prepare opam_reg grcnumFiles)
    >> PrepareOpamReg.(prepare opam_reg classGreekFiles)
    >> PrepareOpamReg.(prepare opam_reg baseFiles)
  in
  let bin = FilePath.concat temp_dir "bin" in
  prepare_pkg
  >> prepare_dist
  >> prepare_opam_reg
  >> PrepareBin.prepare_bin ~opam_response bin log_file
  >>| read_env ~opam_reg ~dist_library_dir:empty_dist

let () =
  let verbose = false in
  let main env ~dest_dir:_ ~temp_dir ~outf:_ =
    let _name = Some "example-doc" in
    (* let dest_dir = FilePath.concat dest_dir "dest" in *)
    Satyrographos_command.Lockdown.save_lockdown
      ~verbose
      ~env
      ~buildscript_path:(FilePath.concat temp_dir "pkg/Satyristes")
  in
  let post_dump_dirs ~dest_dir:_ ~temp_dir =
    let pkg_dir = FilePath.concat temp_dir "pkg" in
    [pkg_dir]
  in
  eval (test_install ~post_dump_dirs env main)
