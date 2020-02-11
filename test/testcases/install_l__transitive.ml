module StdList = List

open TestLib

open Shexp_process

let env ~dest_dir:_ ~temp_dir : Satyrographos.Environment.t t =
  let open Shexp_process.Infix in
  let empty_dist = FilePath.concat temp_dir "empty_dist" in
  let opam_reg = FilePath.concat temp_dir "opam_reg" in
  PrepareDist.empty empty_dist
  >> PrepareOpamReg.(prepare opam_reg theanoFiles)
  >> PrepareOpamReg.(prepare opam_reg grcnumFiles)
  >> PrepareOpamReg.(prepare opam_reg classGreekFiles)
  >> PrepareOpamReg.(prepare opam_reg baseFiles)
  >> return Satyrographos.Environment.{
    repo = None;
    opam_reg = Some (Satyrographos.OpamSatysfiRegistry.read opam_reg);
    dist_library_dir = Some empty_dist;
  }

let () =
  let system_font_prefix = None in
  let libraries = Some ["grcnum"; "base"] in
  let verbose = true in
  let copy = false in
  let main env ~dest_dir ~temp_dir:_ =
    let dest_dir = FilePath.concat dest_dir "dest" in
    Satyrographos.CommandInstall.install dest_dir ~system_font_prefix ~libraries ~verbose ~copy ~env () in
  eval (test_install env main)