open Core
open Satyrographos
open Lint_prim


let get_opam_name = get_opam_name

let lint_compatibility ~locs (m : BuildScript.m) =
  let f = function
    | Satyrographos.BuildScript.Compatibility.Satyrographos "0.0.1" ->
      [{
        locs;
        level = `Warning;
        problem = SatyrographosCompatibliltyNoticeIneffective "0.0.1"
      }]
    | _ ->
      []
  in
  match Satyrographos.BuildScript.get_compatibility_opt m with
  | None -> []
  | Some compatibility ->
    compatibility
    |> Satyrographos.BuildScript.CompatibilitySet.to_list
    |> List.concat_map ~f

let lint_module ~outf ~verbose:_ ~satysfi_version ~basedir ~buildscript_basename ~(env: Environment.t) (m : BuildScript.m) =
  let locs = [SatyristesModLoc BuildScript.(buildscript_basename, get_name m, get_position_opt m)] in
  let opam_problems =
    BuildScript.get_opam_opt m
    |> Option.map ~f:(Lint_module_opam.lint_module_opam ~locs ~basedir m)
    |> Option.value ~default:[]
  in
  let dependency_problems =
    Lint_module_dependency.lint_module_dependency ~outf ~locs ~satysfi_version ~basedir ~env m
  in
  opam_problems
  @ dependency_problems
  @ lint_compatibility ~locs m

let lint ~outf ~satysfi_version ~verbose ~buildscript_path ~(env : Environment.t) =
  let buildscript_path = Option.value ~default:"Satyristes" buildscript_path in
  let buildscript_path =
    let cwd = FileUtil.pwd () in
    FilePath.make_absolute cwd buildscript_path
  in
  let basedir = FilePath.dirname buildscript_path in
  let buildscript_basename = FilePath.basename buildscript_path in
  let buildscript = BuildScript.load buildscript_path in
  let problems =
    match buildscript with
    | BuildScript.Lang_0_0_2 module_map
    | BuildScript.Lang_0_0_3 module_map ->
      Map.to_alist module_map
      |> List.concat_map ~f:(fun (_, m) ->
          lint_module ~outf ~verbose ~satysfi_version ~basedir ~buildscript_basename ~env m)
  in
  show_problems ~outf ~basedir problems;
  List.length problems
  |> Format.fprintf outf "%d problem(s) found.@.";
  List.find problems ~f:(function {level=`Error; _} -> true | _ -> false)
  |> Option.value_map ~default:0 ~f:(const 1)
