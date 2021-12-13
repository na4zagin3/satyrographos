module StdList = List

open Satyrographos_testlib
open TestLib

open Shexp_process

let satyristes =
{|
(lang "0.0.3")
(library
  (name "grcnum")
  (version "0.2")
  (sources
    ((package "grcnum.satyh" "./grcnum.satyh")
     (font "grcnum-font.ttf" "./font.ttf" ())
     (hash "fonts.satysfi-hash" "./fonts.satysfi-hash")
     ; (file "doc/grcnum.md" "README.md")
    ))
  (opam "satysfi-grcnum.opam")
  (dependencies (fonts-theano)))

(doc
  (name "example-doc")
  (build
    ((satysfi "doc-example.saty" "-o" "doc-example-ja.pdf")
     (make "build-doc")))
  (dependencies (grcnum fonts-theano)))
|}

let satysfi_grcnum_opam =
  "satysfi-grcnum.opam", TestLib.opam_file_for_test
    ~name:"satysfi-grcnum"
    ~version:"0.1"
    ()

let fontHash =
{|{
  "grcnum:grcnum-font":<"Single":{"src-dist":"grcnum/grcnum-font.ttf"}>
}|}

let makefile =
{|
PHONY: build-doc
build-doc:
	@echo "Target: build-doc"
	@echo 'Files under $$SATYSFI_RUNTIME'
	@echo "=============================="
	@cd "$(SATYSFI_RUNTIME)" ; find . | LC_ALL=C sort
	@echo "=============================="
|}

let files =
  [
    satysfi_grcnum_opam;
    "Satyristes", satyristes;
    "README.md", "@@README.md@@";
    "fonts.satysfi-hash", fontHash;
    "grcnum.satyh", "@@grcnum.satyh@@";
    "font.ttf", "@@font.ttf@@";
    "doc-grcnum.saty", "@@doc-grcnum.saty@@";
    "doc-example.saty", "@@doc-example.saty@@";
    "Makefile", makefile;
  ]

let opam_response = {
  PrepareBin.list_result = {|# Packages matching: (installed | available) & (name-match(satyrographos) | name-match(satysfi) | name-match(ocaml))
# Name       ,# Repository    ,# Version
ocaml        ,default         ,4.09.0
satyrographos,satysfi-external,0.0.2.7
satysfi      ,satyrographos   ,0.0.5+dev2020.09.05|}
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
