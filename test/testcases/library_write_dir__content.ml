module StdList = List

open Satyrographos_testlib
open TestLib

open Shexp_process

let env ~dest_dir:_ ~temp_dir =
  let open Shexp_process.Infix in
  let empty_dist = FilePath.concat temp_dir "empty_dist" in
  PrepareDist.simple empty_dist
  >> return empty_dist

let () =
  let verbose = false in
  let main dist ~dest_dir ~temp_dir:_ ~outf =
    let open Satyrographos in
    let dest_dir = FilePath.concat dest_dir "dest" in
    let l = Library.read_dir ~outf dist in
    let l = { l with files =
      Library.LibraryFiles.add_exn l.files ~key:"packages/test.satyg" ~data:(`Content "let x = 1")
    } in
    Library.write_dir ~outf ~verbose ~symlink:true dest_dir l in
  eval (test_install env main)
