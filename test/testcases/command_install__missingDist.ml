module StdList = List

open Satyrographos_testlib
open TestLib

open Shexp_process

let env ~dest_dir:_ ~temp_dir:_ : Satyrographos.Environment.t t =
  return (read_env ())

let () =
  let system_font_prefix = None in
  let libraries = None in
  let verbose = true in
  let copy = false in
  let main env ~dest_dir ~temp_dir:_ =
    let dest_dir = FilePath.concat dest_dir "dest" in
    Satyrographos_command.Install.install dest_dir ~system_font_prefix ~libraries ~verbose ~copy ~env () in
  eval (test_install env main)
