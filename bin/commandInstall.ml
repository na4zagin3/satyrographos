open Satyrographos
open Core

open Setup


let install d ~system_font_prefix ~verbose ~copy () =
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
  let dist_package = SatysfiDirs.satysfi_dist_dir () in
  Printf.printf "Reading runtime dist: %s\n" dist_package;
  let user_packages = Registry.list reg
    |> List.map ~f:(Registry.directory reg)
  in
  let opam_packages = match reg_opam with
    | None -> []
    | Some reg_opam ->
      SatysfiRegistry.list reg_opam
        |> List.filter ~f:(fun name -> String.equal "dist" name |> not)
        |> List.map ~f:(SatysfiRegistry.directory reg_opam)
  in
  let packages = dist_package :: List.append user_packages opam_packages
    |> List.map ~f:Package.read_dir
  in
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
  let default_target_dir =
    Sys.getenv "SATYSFI_RUNTIME"
    |> Option.value ~default:target_dist_dir
    |> (fun dir -> Filename.concat dir "dist") in
  let readme () =
    sprintf "Install SATySFi Libraries to a directory environmental variable SATYSFI_RUNTIME has or %s. Currently it accepts an argument DIR, but this is experimental." default_target_dir
  in
  Command.basic
    ~summary:"Install SATySFi runtime"
    ~readme
    [%map_open
      let system_font_prefix = flag "system-font-prefix" (optional string) ~doc:"FONT_NAME_PREFIX Installing system fonts with names with the given prefix"
      and target_dir = anon (maybe_with_default default_target_dir ("DIR" %: string))
      and verbose = flag "verbose" no_arg ~doc:"Make verbose"
      and copy = flag "copy" no_arg ~doc:"Copy files instead of making symlinks"
      in
      fun () ->
        install target_dir ~system_font_prefix ~verbose ~copy ()
    ]
