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
    ((font "grcnum-font.ttf" "./font.ttf"
           ((Single "grcnum:grcnum-font")))
     (hash "fonts.satysfi-hash" "./fonts.satysfi-hash")
     (file "doc/grcnum.md" "README.md")
    ))
  (opam "satysfi-grcnum.opam")
  (dependencies (fonts-theano)))
|}

let fontHash =
{|{
  "grcnum:grcnum-font":<"Single":{"src-dist":"grcnum/grcnum-font.ttf"}>
}|}

let env ~dest_dir:_ ~temp_dir : Satyrographos.Environment.t t =
  let open Shexp_process.Infix in
  let pkg_dir = FilePath.concat temp_dir "pkg" in
  let prepare_pkg =
    PrepareDist.empty pkg_dir
    >> stdout_to (FilePath.concat pkg_dir "Satyristes") (echo satyristes)
    >> stdout_to (FilePath.concat pkg_dir "README.md") (echo "@@README.md@@")
    >> stdout_to (FilePath.concat pkg_dir "fonts.satysfi-hash") (echo fontHash)
    >> stdout_to (FilePath.concat pkg_dir "font.ttf") (echo "@@font.ttf@@")
  in
  let empty_dist = FilePath.concat temp_dir "empty_dist" in
  let prepare_dist = PrepareDist.empty empty_dist in
  let opam_reg = FilePath.concat temp_dir "opam_reg" in
  let prepare_opam_reg =
    PrepareOpamReg.(prepare opam_reg theanoFiles)
    >> PrepareOpamReg.(prepare opam_reg grcnumFiles)
    >> PrepareOpamReg.(prepare opam_reg classGreekFiles)
    >> PrepareOpamReg.(prepare opam_reg baseFiles)
  in
  prepare_pkg
  >> prepare_dist
  >> prepare_opam_reg
  >>| read_env ~opam_reg ~dist_library_dir:empty_dist

let () =
  let verbose = true in
  let main env ~dest_dir ~temp_dir =
    let name = Some "grcnum" in
    let dest_dir = FilePath.concat dest_dir "dest" in
    Satyrographos_command.Opam.(with_build_script install_opam ~verbose ~prefix:dest_dir ~buildscript_path:(FilePath.concat temp_dir "pkg/Satyristes") ~env ~name) () in
  eval (test_install env main)
