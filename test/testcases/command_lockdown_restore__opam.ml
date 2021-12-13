module StdList = List

open Satyrographos_testlib
open TestLib

open Shexp_process

let lockdown_yaml =
{|satyrographos: 0.0.3
dependencies:
- Opam
- packages:
  - name: ocaml
    version: 4.09.0
  - name: satyrographos
    version: 0.0.2.7
  - name: satysfi
    version: 0.0.5+dev2020.09.05
  repos:
  - name: default
    url: https://opam.ocaml.org/
  - name: satysfi-external
    url: git+https://github.com/gfngfn/satysfi-external-repo.git
autogen:
  '$today':
    time: 2020-11-06T00:46:35.000000+09:00
    zone: Asia/Tokyo
|}


let files =
  Command_lockdown_save__opam.files @ [
    "lockdown.yaml", lockdown_yaml;
  ]

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
  >> PrepareBin.prepare_bin bin log_file
  >>| read_env ~opam_reg ~dist_library_dir:empty_dist

let () =
  let verbose = false in
  let main env ~dest_dir:_ ~temp_dir ~outf:_ =
    let _name = Some "example-doc" in
    (* let dest_dir = FilePath.concat dest_dir "dest" in *)
    Satyrographos_command.Lockdown.restore_lockdown
      ~verbose
      ~env
      ~buildscript_path:(FilePath.concat temp_dir "pkg/Satyristes")
  in
  let post_dump_dirs ~dest_dir:_ ~temp_dir:_ = [] in
  eval (test_install ~post_dump_dirs env main)
