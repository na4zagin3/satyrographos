open Core
open Satyrographos

type location =
  | SatyristesModLoc of (string * string)
  | OpamLoc of string

let show_location ~outf ~basedir =
  let concat_with_basedir = FilePath.concat basedir in
  function
  | SatyristesModLoc (buildscript_path, module_name) ->
    Format.fprintf outf "%s (module %s):@." (concat_with_basedir buildscript_path) module_name
  | OpamLoc (opam_path) ->
    Format.fprintf outf "%s:@." (concat_with_basedir opam_path)

let show_locations ~outf ~basedir locs =
  List.rev locs
  |> List.iter ~f:(show_location ~outf ~basedir)

let show_problem ~outf ~basedir (locs, level, msg) =
  show_locations ~outf ~basedir locs;
  match level with
  | `Error->
    Format.fprintf outf "@[<2>Error:@ %s@]@.@." msg
  | `Warning ->
    Format.fprintf outf "@[<2>Warning:@ %s@]@.@." msg

let show_problems ~outf ~basedir =
  List.iter ~f:(show_problem ~outf ~basedir)

let get_opam_name ~opam ~opam_path =
  OpamFile.OPAM.name_opt opam
  |> Option.map ~f:OpamPackage.Name.to_string
  |> Option.value ~default:(FilePath.basename opam_path |> FilePath.chop_extension)

let lint_module_opam ~loc ~basedir ~buildscript_basename:_ (m : BuildScript.m) opam_path =
  let loc = OpamLoc opam_path :: loc in
  let opam_file =
    OpamFilename.create (OpamFilename.Dir.of_string basedir) (OpamFilename.Base.of_string opam_path)
      |> OpamFile.make
  in
  let open OpamFile in
  let opam = OPAM.read opam_file in
  let module_name = BuildScript.get_name m in
  let test_name =
    let opam_name = get_opam_name ~opam ~opam_path in
    if String.equal ("satysfi-" ^ module_name) opam_name |> not
    then [loc, `Error, (sprintf "OPAM package name “%s” should be “satysfi-%s”." opam_name module_name)]
    else []
  in
  List.concat
    [ test_name;
    ]

let lint_module ~basedir ~buildscript_basename (m : BuildScript.m) =
  let loc = [SatyristesModLoc (buildscript_basename, BuildScript.get_name m)] in
  let opam_problems =
    BuildScript.get_opam_opt m
    |> Option.map ~f:(lint_module_opam ~loc ~basedir ~buildscript_basename m)
    |> Option.value ~default:[]
  in
  opam_problems

let lint ~outf ~verbose:_ ~buildscript_path =
  let buildscript_path = Option.value ~default:"Satyristes" buildscript_path in
  let buildscript_path =
    let cwd = FileUtil.pwd () in
    FilePath.make_absolute cwd buildscript_path
  in
  let basedir = FilePath.dirname buildscript_path in
  let buildscript_basename = FilePath.basename buildscript_path in
  let buildscript = BuildScript.from_file buildscript_path in
  let problems =
    Map.to_alist buildscript
    |> List.concat_map ~f:(fun (_, m) ->
        lint_module ~basedir ~buildscript_basename m)
  in
  show_problems ~outf ~basedir problems;
  List.length problems
  |> Format.fprintf outf "%d problem(s) found.@."
