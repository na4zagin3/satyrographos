open Satyrographos
open Core

let prefix = match SatysfiDirs.home_dir () with
  | Some(d) -> d
  | None -> failwith "Cannot find home directory"

let user_dir = Filename.concat prefix ".satysfi"
let root_dir = Filename.concat prefix ".satyrographos"
let package_dir = Filename.concat root_dir "packages"

let opam_share_dir =
  Unix.open_process_in "opam var share"
  |> In_channel.input_all
  |> String.strip

let reg = {Registory.package_dir=package_dir}
let reg_opam =
  Printf.printf "opam dir: %s\n" opam_share_dir;
  {SatysfiRegistory.package_dir=Filename.concat opam_share_dir "satysfi"}


let initialize () =
  Registory.initialize reg

let () =
  initialize ()

let status () =
  [%derive.show: string list] (Registory.list reg) |> print_endline;
  [%derive.show: string list] (SatysfiDirs.runtime_dirs ()) |> print_endline;
  [%derive.show: string option] (SatysfiDirs.user_dir ()) |> print_endline

let pin_list () =
  [%derive.show: string list] (Registory.list reg) |> print_endline
let pin_list_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"List installed packages (experimental)"
    [%map_open
      let _ = args (* ToDo: Remove this *)
      in
      fun () ->
        pin_list ()
    ]

let pin_dir p () =
  Registory.directory reg p |> print_endline
let pin_dir_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Get directory where package PACKAGE is stored (experimental)"
    [%map_open
      let p = anon ("PACKAGE" %: string)
      in
      fun () ->
        pin_dir p ()
    ]

let pin_add p dir () =
  Registory.add_dir reg p dir;
  Printf.printf "Added %s (%s)\n" p dir
let pin_add_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Add package with name PACKAGE copying from DIR (experimental)"
    [%map_open
      let p = anon ("PACKAGE" %: string)
      and dir = anon ("DIR" %: file)
      in
      fun () ->
        pin_add p dir ()
    ]

let pin_remove p () =
  Registory.remove reg p;
  Printf.printf "Removed %s\n" p
let pin_remove_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Remove package (experimental)"
    [%map_open
      let p = anon ("PACKAGE" %: string) (* ToDo: Remove this *)
      in
      fun () ->
        pin_remove p ()
    ]

let pin_command =
  Command.group ~summary:"Manipulate packages (experimental)"
    [ "list", pin_list_command; (* ToDo: use this default*)
      "dir", pin_dir_command;
      "add", pin_add_command;
      "remove", pin_remove_command;
    ]


let package_show_command_g p_show =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Show package information (experimental)"
    [%map_open
      let p = anon ("PACKAGE" %: string)
      in
      fun () ->
        p_show p ()
    ]
let package_list_command_g p_list =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Show list of packages installed (experimental)"
    [%map_open
      let _ = args (* ToDo: Remove this *)
      in
      fun () ->
        p_list ()
    ]

let package_list () =
  [%derive.show: string list] (Registory.list reg) |> print_endline
let package_list_command =
  package_list_command_g package_list

let package_show p () =
  Registory.directory reg p
    |> Package.read_dir
    |> [%derive.show: Package.t]
    |> print_endline
let package_show_command =
  package_show_command_g package_show

let package_command =
  Command.group ~summary:"Install packages (experimental)"
    [ "list", package_list_command; (* ToDo: use this default*)
      "show", package_show_command;
    ]


let package_opam_list () =
  [%derive.show: string list] (SatysfiRegistory.list reg_opam) |> print_endline
let package_opam_list_command =
  package_list_command_g package_opam_list

let package_opam_show p () =
  SatysfiRegistory.directory reg_opam p
    |> Package.read_dir
    |> [%derive.show: Package.t]
    |> print_endline
let package_opam_show_command =
  package_show_command_g package_opam_show

let package_opam_command =
  Command.group ~summary:"Inspect packages installed with OPAM (experimental)"
    [ "list", package_opam_list_command; (* ToDo: use this default*)
      "show", package_opam_show_command;
    ]


let install d () =
  let user_packages = Registory.list reg
    |> List.map ~f:(Registory.directory reg)
  in
  let dist_packages = SatysfiRegistory.list reg_opam
    |> List.map ~f:(SatysfiRegistory.directory reg_opam)
  in
  let packages = List.append user_packages dist_packages
    |> List.map ~f:Package.read_dir
  in
  let merged = packages
    |> List.fold_left ~f:Package.union ~init:Package.empty
  in
  match FileUtil.test FileUtil.Is_dir d, Package.is_managed_dir d with
  | true, false ->
    Printf.printf "Directory %s is not managed by Satyrographos.\n" d;
    Printf.printf "Please remove %s first.\n" d
  | _, _ ->
    Printf.printf "Remove destination %s \n" d;
    FileUtil.(rm ~force:Force ~recurse:true [d]);
    Package.mark_managed_dir d;
    Printf.printf "Loaded packages\n";
    [%derive.show: Package.t list] packages |> print_endline;
    Printf.printf "Installing to %s\n" d;
    [%derive.show: Package.t] merged |> print_endline;
    Package.write_dir d merged;
    Printf.printf "Installation completed!\n";
    List.iter ~f:(Printf.printf "(WARNING) %s") (Package.validate merged)

let install_command =
  let open Command.Let_syntax in
  let default_target_dir =
    Sys.getenv "SATYSFI_RUNTIME"
    |> Option.value ~default:(Filename.concat user_dir "dist") in
  let readme () =
    sprintf "Install SATySFi Libraries to a directory environmental variable SATYSFI_RUNTIME has or %s. Currently it accepts an argument DIR, but this is experimental." default_target_dir
  in
  Command.basic
    ~summary:"Install SATySFi runtime"
    ~readme
    [%map_open
      let target_dir = anon (maybe_with_default default_target_dir ("DIR" %: file))
      in
      fun () ->
        install target_dir ()
    ]

let status_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Show status (experimental)"
    [%map_open
      let _ = args (* ToDo: Remove this *)
      in
      fun () ->
        status ()
    ]

let total_command =
  Command.group ~summary:"Simple SATySFi Package Manager"
    [
      "package", package_command;
      "package-opam", package_opam_command;
      "status", status_command;
      "pin", package_command;
      "install", install_command;
    ]

let () =
  Command.run ~version:"0.0.1.1" ~build_info:"RWO" total_command
