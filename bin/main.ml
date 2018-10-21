open Satyrographos

let prefix = match SatysfiDirs.home_dir () with
  | Some(d) -> d
  | None -> failwith "Cannot find home directory"

let root_dir = Filename.concat prefix ".satyrographos"
let package_dir = Filename.concat root_dir "packages"

let reg = {Registory.package_dir=package_dir}

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
  | (_ :: "status" :: _) -> status ()
  | (name :: _) -> Printf.printf "%s pin ...\n" name
  | args -> [%derive.show: string list] args |> print_endline
