open Satyrographos
open Core

open Setup


let library_show_command_g p_show =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Show library information (experimental)"
    [%map_open
      let p = anon ("LIBRARY" %: string)
      in
      fun () ->
        p_show p ()
    ]
let library_list_command_g p_list =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"Show list of libraries installed (experimental)"
    [%map_open
      let _ = args (* ToDo: Remove this *)
      in
      fun () ->
        p_list ()
    ]

let library_list () =
  Compatibility.optin ();
  match try_read_repo () with
  | Some { repo=_; reg; } ->
    [%derive.show: string list] (Registry.list reg) |> print_endline
  | None -> printf "No libraries"
  let library_list_command =
    library_list_command_g library_list

let library_show p () =
  Compatibility.optin ();
  let { repo=_; reg; } = read_repo () in
  Registry.directory reg p
    |> Library.read_dir
    |> [%sexp_of: Library.t]
    |> Sexp.to_string_hum
    |> print_endline
let library_show_command =
  library_show_command_g library_show

let library_command =
  Command.group ~summary:"Install libraries (experimental)"
    [ "list", library_list_command; (* ToDo: use this default*)
      "show", library_show_command;
    ]


let library_opam_list () =
  Compatibility.optin ();
  Option.iter reg_opam ~f:(fun reg_opam ->
    [%derive.show: string list] (OpamSatysfiRegistry.list reg_opam) |> print_endline
  )
let library_opam_list_command =
  library_list_command_g library_opam_list

let library_opam_show p () =
  Compatibility.optin ();
  Option.iter reg_opam ~f:(fun reg_opam ->
    OpamSatysfiRegistry.directory reg_opam p
      |> Library.read_dir
      |> [%sexp_of: Library.t]
      |> Sexp.to_string_hum
      |> print_endline
  )
let library_opam_show_command =
  library_show_command_g library_opam_show

let library_opam_command =
  Command.group ~summary:"Inspect libraries installed in the OPAM managed directory (experimental)"
    [ "list", library_opam_list_command; (* ToDo: use this default*)
      "show", library_opam_show_command;
    ]
