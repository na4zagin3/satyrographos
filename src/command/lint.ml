open Core
open Satyrographos

let show_problem ~outf ~buildscript_path =
  function
  | module_name, `E msg ->
    Format.fprintf outf "@[<2>%s (module %s) Error:@,%s@]@." buildscript_path module_name msg
  | module_name, `W msg ->
    Format.fprintf outf "@[<2>%s (module %s) Warning:@,%s@]@." buildscript_path module_name msg

let show_problems ~outf ~buildscript_path =
  List.iter ~f:(show_problem ~outf ~buildscript_path)

let lint_module_opam ~basedir ~buildscript_basename:_ (m : BuildScript.m) opam_path =
  let opam_file =
    OpamFilename.create (OpamFilename.Dir.of_string basedir) (OpamFilename.Base.of_string opam_path)
      |> OpamFile.make
  in
  let open OpamFile in
  let opam = OPAM.read opam_file in
  let opam_name =
    OPAM.name_opt opam
    |> Option.map ~f:OpamPackage.Name.to_string
    |> Option.value ~default:(FilePath.basename opam_path |> FilePath.chop_extension)
  in
  let test_name module_name opam_name =
    if String.equal ("satysfi-" ^ module_name) opam_name |> not
    then (module_name, `E (sprintf "OPAM package name “%s” should be “satysfi-%s”." opam_name module_name))
         |> Option.some
    else None
  in
  List.filter_opt
    [ test_name (BuildScript.get_name m) opam_name
    ]

let lint_module ~basedir ~buildscript_basename (m : BuildScript.m) =
  let opam_problems =
    BuildScript.get_opam m
    |> Option.map ~f:(lint_module_opam ~basedir ~buildscript_basename m)
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
  show_problems ~outf ~buildscript_path problems;
  List.length problems
  |> Format.fprintf outf "%d problem(s) found.@."
