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

let lint_build ~locs ~(buildscript_version : BuildScript.version) (m : BuildScript.m) =
  let contains_deprecated_make =
    BuildScript.get_build_opt m
    |> Option.value ~default:[]
    |> List.exists ~f:(function
        | BuildScript.MakeWithEnvVar _
          when
            [%equal: BuildScript.version] buildscript_version BuildScript.Lang_0_0_2
            |> not -> true
        | _ -> false
      )
  in
  if contains_deprecated_make
  then [{
      locs;
      level = `Warning;
      problem = LibraryBuildDeprecatedMakeCommand;
    }]
  else []

let lint_module ~outf ~verbose:_ ~satysfi_version ~basedir
    ~buildscript_basename ~buildscript_version
    ~(env: Environment.t) (m : BuildScript.m) =
  let locs = [SatyristesModLoc BuildScript.(buildscript_basename, get_name m, get_position_opt m)] in
  let opam_problems =
    BuildScript.get_opam_opt m
    |> Option.map ~f:(Lint_module_opam.lint_module_opam ~locs ~basedir m)
    |> Option.value ~default:[]
  in
  let dependency_problems =
    Lint_module_dependency.lint_module_dependency ~outf ~locs ~satysfi_version ~basedir ~env m
  in
  let hash_problems =
    Lint_module_hashes.lint_module_hashes ~outf ~locs ~satysfi_version ~basedir ~env m
  in
  opam_problems
  @ dependency_problems
  @ hash_problems
  @ lint_compatibility ~locs m
  @ lint_build ~locs ~buildscript_version m

let lint ~outf ~satysfi_version ~warning_expr ~verbose ~buildscript_path ~(env : Environment.t) =
  let warning_expr =
    Option.value ~default:Glob.TokenMatcher.empty warning_expr
  in
  let buildscript_path = Option.value ~default:"Satyristes" buildscript_path in
  let buildscript_path =
    let cwd = FileUtil.pwd () in
    FilePath.make_absolute cwd buildscript_path
  in
  let basedir = FilePath.dirname buildscript_path in
  let buildscript_basename = FilePath.basename buildscript_path in
  let buildscript = BuildScript.load buildscript_path in
  let buildscript_version = BuildScript.buildscript_version buildscript in
  let problems =
    match buildscript with
    | BuildScript.Script_0_0_2 module_map
    | BuildScript.Script_0_0_3 module_map ->
      Map.to_alist module_map
      |> List.concat_map ~f:(fun (_, m) ->
          lint_module
            ~outf
            ~verbose
            ~satysfi_version
            ~basedir
            ~buildscript_basename
            ~buildscript_version
            ~env
            m)
  in
  let is_matched_warning diag =
    Lint_problem.problem_class diag.problem
    |> Glob.split_on_slash
    |> Glob.TokenMatcher.exec warning_expr
    |> Option.value ~default:true
  in
  let problems =
    problems
    |> List.filter ~f:(fun diag ->
        (* TODO Error should not be ignored once lint subcommand gets stable enough.
           [%equal: level] diag.level `Error ||
        *)
        is_matched_warning diag
      )
  in
  show_problems ~outf ~basedir problems;
  List.length problems
  |> Format.fprintf outf "%d problem(s) found.@.";
  List.find problems ~f:(function {level=`Error; _} -> true | _ -> false)
  |> Option.value_map ~default:0 ~f:(const 1)
