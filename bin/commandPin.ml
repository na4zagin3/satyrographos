open Satyrographos
open Core

open Setup

let pin_list () =
  Compatibility.optin ();
  let { repo; reg=_; } = read_repo () in
  [%derive.show: string list] (Repository.list repo) |> print_endline
let pin_list_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"List installed libraries (experimental)"
    [%map_open
      let _ = args (* ToDo: Remove this *)
      in
      fun () ->
        pin_list ()
    ]

let pin_dir p () =
  Compatibility.optin ();
  let { repo; reg=_; } = read_repo () in
  Repository.directory repo p |> print_endline
let pin_dir_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Get directory where library LIBRARY is stored (experimental)"
    [%map_open
      let p = anon ("LIBRARY" %: string)
      in
      fun () ->
        pin_dir p ()
    ]

let pin_add p url () =
  Compatibility.optin ();
  Printf.printf "Compatibility warning: Although currently Satyrographos simply copies the given directory,\n";
  Printf.printf "it will have a build script to control library installation, which is a breaking change.";
  let { repo; reg; } = read_repo () in
  Uri.of_string url
  |> Repository.add repo p
  |> ignore;
  Printf.printf "Added %s (%s)\n" p url;
  Registry.update_all reg
  |> [%derive.show: string list option]
  |> Printf.printf "Built libraries: %s\n"
let pin_add_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Add library with name LIBRARY copying from URL (experimental)"
    [%map_open
      let p = anon ("LIBRARY" %: string)
      and url = anon ("URL" %: string) (* TODO define Url.t Arg_type.t *)
      in
      fun () ->
        pin_add p url ()
    ]

let pin_remove p () =
  Compatibility.optin ();
  let { repo; reg=_; } = read_repo () in
  (* TODO remove the library *)
  Repository.remove repo p;
  Printf.printf "Removed %s\n" p
let pin_remove_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Remove library (experimental)"
    [%map_open
      let p = anon ("LIBRARY" %: string) (* ToDo: Remove this *)
      in
      fun () ->
        pin_remove p ()
    ]

let pin_command =
  Command.group ~summary:"Manipulate libraries (experimental)"
    [ "list", pin_list_command; (* ToDo: use this default*)
      "dir", pin_dir_command;
      "add", pin_add_command;
      "remove", pin_remove_command;
    ]
