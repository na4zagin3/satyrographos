module StdList = List

open Satyrographos_testlib
open TestLib

open Shexp_process

let env ~dest_dir:_ ~temp_dir : Satyrographos.Environment.t t =
  let open Shexp_process.Infix in
  let dist_dir = FilePath.concat temp_dir "simple_dist" in
  PrepareDist.simple dist_dir
  >> stdout_to (FilePath.concat dist_dir "hash/broken.satysfi-hash") (echo "abc")
  >>| read_env ~dist_library_dir:dist_dir

let () =
  let system_font_prefix = None in
  let persistent_autogen = [] in
  let libraries = None in
  let verbose = true in
  let copy = false in
  let replacements =
    [ (* YoJson 1.7.0 *)
      "bytes 0-4", "bytes <zero-or-one>-4";
      (* YoJson 1.4.1+satysfi *)
      "bytes 1-4", "bytes <zero-or-one>-4";
    ] in
  let main env ~dest_dir ~temp_dir:_ =
    let dest_dir = FilePath.concat dest_dir "dest" in
    Satyrographos_command.Install.install dest_dir ~system_font_prefix ~persistent_autogen ~libraries ~verbose ~copy ~env () in
  eval (test_install ~replacements env main)
