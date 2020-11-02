open Core
open Satyrographos
open Lint_prim


let lint_opam_file ~opam ~opam_path:_ ~locs =
  OpamFileTools.lint opam
  |> List.map ~f:(fun (error_no, level, msg) ->
      {locs; level; problem = OpamProblem (error_no, msg);})

module StringSet = Set.Make(String)

let extract_opam_package_names ~opam =
  let rec sub =
    let open OpamTypes in
    function
    | Empty -> StringSet.empty
    | Atom (n, _) ->
      OpamPackage.Name.to_string n
      |> StringSet.singleton
    | Block b -> sub b
    | And (x, y) -> StringSet.union (sub x) (sub y)
    | Or (x, y) -> StringSet.union (sub x) (sub y)
  in
  OpamFile.OPAM.depends opam |> sub

let read_opam ~basedir opam_path =
  let opam_file =
    OpamFilename.create (OpamFilename.Dir.of_string basedir) (OpamFilename.Base.of_string opam_path)
    |> OpamFile.make
  in
  let open OpamFile in
  OPAM.read opam_file

let test_name ~locs ~opam ~opam_path m =
  let module_name = BuildScript.get_name m in
  let opam_name = get_opam_name ~opam ~opam_path in
  if String.equal ("satysfi-" ^ module_name) opam_name |> not
  then [{locs; level = `Error; problem = OpamPackageNamePrefix {opam_name; module_name}}]
  else []

let test_version ~locs ~opam m =
  let open OpamFile in
  let module_name = BuildScript.get_name m in
  let module_version =
    BuildScript.get_version_opt m
    |> Option.value_exn
      ~message:(sprintf "BUG: Module %s lacks a version" module_name)
  in
  let opam_version = OPAM.version_opt opam |> Option.map ~f:OpamPackage.Version.to_string in
  match opam_version with
  | _ when String.is_empty module_version ->
    [{
      locs;
      level = `Error;
      problem = LibraryVersionShouldNotBeEmpty;
    }]
  | Some opam_version when String.equal module_version opam_version ->
    []
  | Some opam_version when String.is_prefix ~prefix:module_version opam_version ->
    let module_version_length = String.length module_version in
    let last_module_version_char = String.get module_version (module_version_length - 1) in
    let first_opam_version_char = String.get opam_version module_version_length in
    begin match
        Char.is_digit last_module_version_char,
        Char.is_alpha last_module_version_char,
        Char.is_digit first_opam_version_char,
        Char.is_alpha first_opam_version_char
      with
      | false, false, _, _ ->
        [{locs; level = `Error; problem = LibraryVersionShouldEndWithAnAlphanum module_version;}]
      | _, true, _, true
      | true, _, true, _ ->
        [{locs; level = `Error; problem = OpamPackageVersionShouldBePrefixedWithLibraryVersion {opam_version; module_version;}}]
      | _, _, _, _ -> []
    end
  | Some opam_version ->
    [{locs; level = `Error; problem = OpamPackageVersionShouldBePrefixedWithLibraryVersion {opam_version; module_version;}}]
  | None ->
    [{locs; level = `Error; problem = OpamPackageShouldHaveVersion; }]

let lint_module_opam ~locs ~basedir (m : BuildScript.m) opam_path =
  let locs = OpamLoc opam_path :: locs in
  let opam = read_opam ~basedir opam_path in
  let module_name = BuildScript.get_name m in
  let test_dependencies =
    let module_dependencies =
      BuildScript.get_dependencies_opt m
      |> Option.value_exn
        ~message:(sprintf "BUG: Module %s lacks dependencies" module_name)
      |> Library.Dependency.to_array
      |> StringSet.of_array
    in
    let opam_dependencies =
      extract_opam_package_names ~opam
      |> StringSet.filter_map ~f:(String.chop_prefix ~prefix:"satysfi-")
    in
    let missing_dependencies =
      StringSet.diff module_dependencies opam_dependencies
    in
    if StringSet.is_empty missing_dependencies |> not
    then
      [{
        locs;
        level = `Warning;
        problem = OpamPackageShouldHaveSatysfiDependencies (StringSet.to_list missing_dependencies);
      }]
    else []
  in
  List.concat
    [ test_name ~locs ~opam ~opam_path m;
      test_version ~locs ~opam m;
      test_dependencies;
      lint_opam_file ~opam ~opam_path ~locs;
    ]
