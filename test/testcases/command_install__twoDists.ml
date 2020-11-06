module StdList = List

open Satyrographos_testlib
open TestLib

open Shexp_process

let env ~dest_dir:_ ~temp_dir : Satyrographos.Environment.t t =
  let open Shexp_process.Infix in
  let empty_dist = FilePath.concat temp_dir "empty_dist" in
  let opam_reg = FilePath.concat temp_dir "opam_reg" in
  PrepareDist.simple empty_dist
  >> mkdir opam_reg
  (* empty dist in opam reg must override the simple dist in system *)
  >> PrepareDist.empty (FilePath.concat opam_reg "dist")
  >>| read_env ~opam_reg ~dist_library_dir:empty_dist

let () =
  let system_font_prefix = None in
  let persistent_autogen = [] in
  let libraries = None in
  let verbose = false in
  let copy = false in
  let main env ~dest_dir ~temp_dir:_ =
    let dest_dir = FilePath.concat dest_dir "dest" in
    Satyrographos_command.Install.install dest_dir ~system_font_prefix ~persistent_autogen ~libraries ~verbose ~copy ~env () in
  eval (test_install env main)
