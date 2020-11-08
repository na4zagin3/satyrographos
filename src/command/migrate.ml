open Core

open Satyrographos

let migrate_0_0_2 ~outf ~buildscript_path  =
  Format.fprintf outf "Reading %s.@." buildscript_path;
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
  Format.fprintf outf "Writing %s.@." buildscript_path;
  BuildScript_0_0_3.save_sections
    buildscript_path
    sections3;
  let basedir =
    FilePath.dirname buildscript_path
  in
  let bs = BuildScript.load buildscript_path in
  let migrate_opam name opam_path =
    Format.fprintf outf "Reading %s@." opam_path;
    let file =
      OpamFilename.create (OpamFilename.Dir.of_string basedir) (OpamFilename.Base.of_string opam_path)
    in
    let opam = OpamFile.OPAM.read (OpamFile.make file) in
    let build =
      match OpamFile.OPAM.build opam with
      | [[], None]
      | [] ->
        Format.fprintf outf "Fixing build section in %s.@." opam_path;
        let cmd =
          ["satyrographos"; "opam"; "install";
           "--name"; "satysfi-" ^ name;
           "--prefix"; "%{prefix}%";
           "--script"; "%{build}%/Satyristes"]
        in
        Some [
          (cmd |> List.map ~f:(fun s -> OpamTypes.CString s, None)), None
        ]
      | _ ->
        Format.fprintf outf {|Please be sure %s has the following build section.@.
build:
  ["satyrographos" "opam" "install"
   "--name" "satysfi-%s"
   "--prefix" "%%{prefix}%%"
   "--script" "%%{build}%%/Satyristes"]
|} opam_path name;
        None
    in
    match build with
    | None -> ()
    | Some build ->
      let opam =
        OpamFile.OPAM.with_build build opam
      in
      Format.fprintf outf "Writing %s@." opam_path;
      OpamFile.OPAM.write (OpamFile.make file) opam
  in
  BuildScript.get_module_map bs
  |> BuildScript.StringMap.iter ~f:(fun m ->
      let name = BuildScript.get_name m in
      BuildScript.get_opam_opt m
      |> Option.iter ~f:(migrate_opam name)
    )


let migrate ~outf ~buildscript_path =
  let buildscript_path = Option.value ~default:"Satyristes" buildscript_path in
  let buildscript_path =
    let cwd = FileUtil.pwd () in
    FilePath.make_absolute cwd buildscript_path
  in
  let buildscript = BuildScript.load buildscript_path in
  match buildscript with
  | BuildScript.Script_0_0_3 _ ->
    Format.fprintf outf "Nothing to migrate.@."
  | BuildScript.Script_0_0_2 _ ->
    migrate_0_0_2 ~outf ~buildscript_path;
    Format.fprintf outf "Done.@."
