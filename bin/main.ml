open Satyrographos
open Batteries

let prefix = match SatysfiDirs.home_dir () with
  | Some(d) -> d
  | None -> failwith "Cannot find home directory"

let user_dir = Filename.concat prefix ".satysfi"
let root_dir = Filename.concat prefix ".satyrographos"
let package_dir = Filename.concat root_dir "packages"

let opam_share_dir =
  Unix.open_process_in "opam var share"
  |> IO.read_all
  |> String.trim

let reg = {Registory.package_dir=package_dir}
let reg_opam =
  Printf.printf "opam dir: %s\n" opam_share_dir;
  {Registory.package_dir=Filename.concat opam_share_dir "satysfi"}


let initialize () =
  Registory.initialize reg

let () =
  initialize ()

let status () =
  [%derive.show: string list] (Registory.list reg) |> print_endline;
  [%derive.show: string list] (SatysfiDirs.runtime_dirs ()) |> print_endline;
  [%derive.show: string option] (SatysfiDirs.user_dir ()) |> print_endline

let () = match Array.to_list Sys.argv with
  | (name :: "pin" :: opts) -> begin match opts with
    | ["list"] -> [%derive.show: string list] (Registory.list reg) |> print_endline
    | ["dir"; p] -> Registory.directory reg p |> print_endline
    | ["add"; p; dir] -> Registory.add_dir reg p dir;
      Printf.printf "Added %s (%s)\n" p dir
    | ["remove"; p] -> Registory.remove reg p;
      Printf.printf "Removed %s\n" p
    | _ -> List.iter (Printf.printf "%s pin %s\n" name) [
        "list";
        "dir <package-name>";
        "add <package-name> <dir>";
        "remove <package-name>";
      ]
    end
  | (name :: "package" :: opts) -> begin match opts with
    | ["list"] -> [%derive.show: string list] (Registory.list reg) |> print_endline
    | ["show"; p] -> Registory.directory reg p
      |> Package.read_dir
      |> [%derive.show: Package.t]
      |> print_endline
    | _ -> List.iter (Printf.printf "%s package %s\n" name) [
        "list";
        "show <package-name>";
      ]
    end
  (* TODO: Merge with the previous clause *)
  | (name :: "package-opam" :: opts) -> begin match opts with
    | ["list"] -> [%derive.show: string list] (Registory.list reg_opam) |> print_endline
    | ["show"; p] -> Registory.directory reg_opam p
      |> Package.read_dir
      |> [%derive.show: Package.t]
      |> print_endline
    | _ -> List.iter (Printf.printf "%s package-opam %s\n" name) [
        "list";
        "show <package-name>";
      ]
    end
  | (name :: "install" :: opts) -> begin
    let install_to d =
      let read_packages r = Registory.list r
        |> List.map (Registory.directory r)
      in
      let packages = [reg; reg_opam]
        |> List.map read_packages
        |> List.concat
        |> List.map Package.read_dir
      in
      let merged = packages
        |> List.fold_left Package.union Package.empty
      in
      match FileUtil.test FileUtil.Is_dir d, Package.is_managed_dir d with
      | true, false ->
        Printf.printf "Directory %s is not managed by Satyrographos.\n" d;
        Printf.printf "Please remove %s first.\n" d
      | _, _ ->
        Printf.printf "Loaded packages\n";
        [%derive.show: Package.t list] packages |> print_endline;
        Printf.printf "Installing to %s\n" d;
        [%derive.show: Package.t] merged |> print_endline;
        Package.write_dir d merged
    in
    match opts with
    | [] -> install_to (Filename.concat user_dir "dist")
    | [d] -> install_to d
    | _ -> List.iter (Printf.printf "%s pin %s\n" name) [
        "install [<path-to-install>]";
      ]
    end
  | (_ :: "status" :: _) -> status ()
  | (name :: _) -> List.iter (Printf.printf "%s %s\n" name) [
      "pin";
      "package";
      "install";
    ]
  | args -> [%derive.show: string list] args |> print_endline
