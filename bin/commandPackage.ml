open Satyrographos
open Core

open Setup


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
  Compatibility.optin ();
  [%derive.show: string list] (Registry.list reg) |> print_endline
let package_list_command =
  package_list_command_g package_list

let package_show p () =
  Compatibility.optin ();
  Registry.directory reg p
    |> Package.read_dir
    |> [%sexp_of: Package.t]
    |> Sexp.to_string_hum
    |> print_endline
let package_show_command =
  package_show_command_g package_show

let package_command =
  Command.group ~summary:"Install packages (experimental)"
    [ "list", package_list_command; (* ToDo: use this default*)
      "show", package_show_command;
    ]


let package_opam_list () =
  Compatibility.optin ();
  Option.iter reg_opam ~f:(fun reg_opam ->
    [%derive.show: string list] (SatysfiRegistry.list reg_opam) |> print_endline
  )
let package_opam_list_command =
  package_list_command_g package_opam_list

let package_opam_show p () =
  Compatibility.optin ();
  Option.iter reg_opam ~f:(fun reg_opam ->
    SatysfiRegistry.directory reg_opam p
      |> Package.read_dir
      |> [%sexp_of: Package.t]
      |> Sexp.to_string_hum
      |> print_endline
  )
let package_opam_show_command =
  package_show_command_g package_opam_show

let package_opam_command =
  Command.group ~summary:"Inspect packages installed in the standard library (experimental)"
    [ "list", package_opam_list_command; (* ToDo: use this default*)
      "show", package_opam_show_command;
    ]
