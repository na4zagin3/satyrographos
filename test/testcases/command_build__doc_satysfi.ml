module StdList = List

open Satyrographos_testlib
open TestLib

open Shexp_process

let satyristes =
{|
(lang "0.0.3")
(doc
  (name "example-doc")
  (build
    ((satysfi "doc-example.saty" "-o" "doc-example-ja.pdf")
     (make "build-doc")))
  (dependencies (grcnum fonts-theano)))
|}

let makefile =
{|
PHONY: build-doc
build-doc:
	@echo "Target: build-doc"
|}

let env ~dest_dir:_ ~temp_dir : Satyrographos.Environment.t t =
  let open Shexp_process.Infix in
  let pkg_dir = FilePath.concat temp_dir "pkg" in
  let prepare_pkg =
    PrepareDist.empty pkg_dir
    >> stdout_to (FilePath.concat pkg_dir "Satyristes") (echo satyristes)
    >> stdout_to (FilePath.concat pkg_dir "README.md") (echo "@@README.md@@")
    >> stdout_to (FilePath.concat pkg_dir "doc-example.saty") (echo "@@doc-example.saty@@")
    >> stdout_to (FilePath.concat pkg_dir "Makefile") (echo makefile)
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
  let main env ~dest_dir:_ ~temp_dir ~outf =
    let name = Some "example-doc" in
    (* let dest_dir = FilePath.concat dest_dir "dest" in *)
    Satyrographos_command.Build.build_command
      ~outf
      ~verbose
      ~buildscript_path:(FilePath.concat temp_dir "pkg/Satyristes")
      ~build_dir:(FilePath.concat temp_dir "pkg/_build" |> Option.some)
      ~env
      ~name
  in
  eval (test_install env main)
