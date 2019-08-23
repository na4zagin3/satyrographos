open Satyrographos
open Core

open Setup

let pin_list () =
  Compatibility.optin ();
  [%derive.show: string list] (Repository.list repo) |> print_endline
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
  Compatibility.optin ();
  Repository.directory repo p |> print_endline
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

let pin_add p url () =
  Compatibility.optin ();
  Printf.printf "Compatibility warning: Although currently Satyrographos simply copies the given directory,\n";
  Printf.printf "it will have a build script to control package installation, which is a breaking change.";
  Uri.of_string url
  |> Repository.add repo p
  |> ignore;
  Printf.printf "Added %s (%s)\n" p url;
  Registry.update_all reg
  |> [%derive.show: string list option]
  |> Printf.printf "Built packages: %s\n"
let pin_add_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Add package with name PACKAGE copying from URL (experimental)"
    [%map_open
      let p = anon ("PACKAGE" %: string)
      and url = anon ("URL" %: string) (* TODO define Url.t Arg_type.t *)
      in
      fun () ->
        pin_add p url ()
    ]

let pin_remove p () =
  Compatibility.optin ();
  (* TODO remove the package *)
  Repository.remove repo p;
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
