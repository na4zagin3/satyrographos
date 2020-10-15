open Core

let outf = Format.std_formatter

let pin_list_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"List installed libraries (experimental)"
    [%map_open
      let _ = help
      in
      fun () ->
      Compatibility.optin ();
      let repo = (Setup.read_depot_exn ()).repo in
      Satyrographos_command.Pin.pin_list ~outf repo
    ]

let pin_dir_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Get directory where library LIBRARY is stored (experimental)"
    [%map_open
      let p = anon ("LIBRARY" %: string)
      in
      fun () ->
        Compatibility.optin ();
        let repo = (Setup.read_depot_exn ()).repo in
        Satyrographos_command.Pin.pin_dir ~outf repo p
    ]

let pin_add_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Add library with name LIBRARY copying from URL (experimental)"
    [%map_open
      let p = anon ("LIBRARY" %: string)
      and url = anon ("URL" %: string) (* TODO define Url.t Arg_type.t *)
      in
      fun () ->
        Compatibility.optin ();
        Printf.printf "Compatibility warning: Although currently Satyrographos simply copies the given directory,\n";
        Printf.printf "it will have a build script to control library installation, which is a breaking change.";
        let env = Setup.read_depot_exn () in
        Satyrographos_command.Pin.pin_add ~outf env p url
    ]

let pin_remove_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Remove library (experimental)"
    [%map_open
      let p = anon ("LIBRARY" %: string) (* ToDo: Remove this *)
      in
      fun () ->
        Compatibility.optin ();
        let repo = (Setup.read_depot_exn ()).repo in
        Satyrographos_command.Pin.pin_remove ~outf repo p
    ]

let pin_command =
  Command.group ~summary:"Manipulate libraries (experimental)"
    [ "list", pin_list_command; (* ToDo: use this default*)
      "dir", pin_dir_command;
      "add", pin_add_command;
      "remove", pin_remove_command;
    ]
