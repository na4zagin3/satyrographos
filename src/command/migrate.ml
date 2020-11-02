open Core

open Satyrographos

let migrate_0_0_2 ~outf:_ ~buildscript_path  =
  let sections2 =
    Sexp.load_sexps_conv_exn
      buildscript_path
      [%of_sexp: BuildScript_0_0_2.Section.t]
  in
  let sections3 =
    List.map
      sections2
      ~f:BuildScript_0_0_3.migrate_from_0_0_2
  in
  BuildScript_0_0_3.save_sections
    buildscript_path
    sections3

let migrate ~outf ~buildscript_path =
  let buildscript_path = Option.value ~default:"Satyristes" buildscript_path in
  let buildscript_path =
    let cwd = FileUtil.pwd () in
    FilePath.make_absolute cwd buildscript_path
  in
  let buildscript = BuildScript.load buildscript_path in
  match buildscript with
  | BuildScript.Lang_0_0_3 _ ->
    Format.fprintf outf "Nothing to migrate.@."
  | BuildScript.Lang_0_0_2 _ ->
    migrate_0_0_2 ~outf ~buildscript_path;
    Format.fprintf outf "Done.@."
