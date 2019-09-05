open Satyrographos
open Core

open Setup

module StringSet = Set.Make(String)

(* TODO Abstract this *)
module StringMap = Map.Make(String)

let transitive_closure map =
  let rec f visited queue = match StringSet.choose queue with
    | None -> visited
    | Some cur ->
      match Map.find map cur with
      | None -> failwithf "Packages %s is not found\n" cur ();
      | Some nexts ->
        let visited = StringSet.add visited cur in
        let queue =  StringSet.union (StringSet.remove queue cur) (StringSet.diff nexts visited) in
        f visited queue in
  f StringSet.empty


(* TODO Install transitive dependencies *)
let get_packages ~reg ~reg_opam ~packages =
  let dist_package_dir = SatysfiDirs.satysfi_dist_dir () in
  Printf.printf "Reading runtime dist: %s\n" dist_package_dir;
  let dist_package = Package.read_dir dist_package_dir in
  let user_packages = Registry.list reg
    |> StringSet.of_list
    |> StringSet.to_map ~f:(Registry.directory reg)
  in
  Printf.printf "Read user packages: %s\n" (user_packages |> Map.keys |> [%sexp_of: string list] |> Sexp.to_string_hum);
  let opam_packages = match reg_opam with
    | None -> StringSet.to_map StringSet.empty ~f:ident
    | Some reg_opam ->
        SatysfiRegistry.list reg_opam
        |> StringSet.of_list
        |> StringSet.to_map ~f:(SatysfiRegistry.directory reg_opam)
  in
  Printf.printf "Reading opam packages: %s\n" (opam_packages |> Map.keys |> [%sexp_of: string list] |> Sexp.to_string_hum);
  let all_packages =
    Map.merge opam_packages user_packages ~f:(fun ~key -> function
      | `Left x -> Package.read_dir x |> Some
      | `Right x -> Package.read_dir x |> Some
      | `Both (_, x) ->
        Printf.printf "Package %s is provided by both the user local and opam repositories\n" key;
        Package.read_dir x |> Some) in
  let required_packages = match packages with
    | None -> all_packages
    | Some packages -> let package_dependency =
          Map.map all_packages ~f:(fun p -> p.Package.dependencies) in
        let packages_to_install = transitive_closure package_dependency (StringSet.of_list packages) in
        Map.filter_keys all_packages ~f:(StringSet.mem packages_to_install)
  in
  match Map.add required_packages ~key:"dist" ~data:dist_package with
    | `Ok result -> result
    | `Duplicate ->
      Printf.printf "Overriding dist with user installed one";
      required_packages

let install d ~system_font_prefix ~packages ~verbose ~copy () =
  (* TODO build all *)
  Printf.printf "Updating packages\n";
  begin match Repository.update_all repo with
  | Some updated_packages -> begin
    Printf.printf "Updated packages: ";
    [%derive.show: string list] updated_packages |> print_endline
  end
  | None ->
    Printf.printf "No packages updated\n"
  end;
  Printf.printf "Building updated packages\n";
  begin match Registry.update_all reg with
  | Some updated_packages -> begin
    Printf.printf "Built packages: ";
    [%derive.show: string list] updated_packages |> print_endline
  end
  | None ->
    Printf.printf "No packages built\n"
  end;
  let package_map = get_packages ~reg ~reg_opam ~packages in
  let packages = package_map |> Map.data in
  Printf.printf "Installing packages: ";
  Map.keys package_map |> [%sexp_of: string list] |> Sexp.to_string_hum |> print_endline;
  let packages = match system_font_prefix with
    | None -> Printf.printf "Not gathering system fonts\n"; packages
    | Some(prefix) ->
      Printf.printf "Gathering system fonts with prefix %s\n" prefix;
      let systemFontPackage = SystemFontPackage.get_package prefix () in
      List.cons systemFontPackage packages
  in
  let merged = packages
    |> List.fold_left ~f:Package.union ~init:Package.empty
  in
  match FileUtil.test FileUtil.Is_dir d, Package.is_managed_dir d with
  | true, false ->
    Printf.printf "Directory %s is not managed by Satyrographos.\n" d;
    Printf.printf "Please remove %s first.\n" d
  | _, _ ->
    Printf.printf "Removing destination %s\n" d;
    FileUtil.(rm ~force:Force ~recurse:true [d]);
    Package.mark_managed_dir d;
    if verbose
    then begin
      Printf.printf "Loaded packages\n";
      [%sexp_of: Package.t list] packages
      |> Sexp.to_string_hum
      |> print_endline;
      Printf.printf "Installing %s\n" d;
      [%sexp_of: Package.t] merged
      |> Sexp.to_string_hum
      |> print_endline
    end;
    Package.write_dir ~symlink:(not copy) d merged;
    List.iter ~f:(Printf.printf "WARNING: %s") (Package.validate merged);
    Printf.printf "Installation completed!\n"

let install_command =
  let open Command.Let_syntax in
  let readme () =
    sprintf "Install SATySFi Libraries to a directory environmental variable SATYSFI_RUNTIME has or %s. Currently it accepts an argument DIR, but this is experimental." default_target_dir
  in
  Command.basic
    ~summary:"Install SATySFi runtime"
    ~readme
    [%map_open
      let system_font_prefix = flag "system-font-prefix" (optional string) ~doc:"FONT_NAME_PREFIX Installing system fonts with names with the given prefix"
      and package_list = flag "package" (listed string) ~doc:"PACKAGE Package"
      and target_dir = anon (maybe_with_default default_target_dir ("DIR" %: string))
      and verbose = flag "verbose" no_arg ~doc:"Make verbose"
      and copy = flag "copy" no_arg ~doc:"Copy files instead of making symlinks"
      in
      fun () ->
        let packages = match package_list with
          | [] -> None
          | xs -> Some xs in
        install target_dir ~system_font_prefix ~packages ~verbose ~copy ()
    ]
