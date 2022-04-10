open Satyrographos
open Core


let outf = Format.std_formatter

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


let library_opam_list () =
  Compatibility.optin ();
  let env = Setup.read_environment () in
  Option.iter env.opam_reg ~f:(fun opam_reg ->
      OpamSatysfiRegistry.list opam_reg
      |> List.sort ~compare:String.compare
      |> String.concat ~sep:"\n"
      |> print_endline
    )
let library_opam_list_command =
  library_list_command_g library_opam_list

let library_opam_show p () =
  Compatibility.optin ();
  let env = Setup.read_environment () in
  Option.iter env.opam_reg ~f:(fun opam_reg ->
    OpamSatysfiRegistry.directory opam_reg p
      |> Library.read_dir ~outf
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
