open Satyrographos
open Core

module SatysfiDirs = Satyrographos_satysfi.SatysfiDirs


let outf = Format.std_formatter

let status () =
  let env = Setup.read_environment () in
  printf "SATySFi runtime directories: ";
  [%derive.show: string list] (SatysfiDirs.runtime_dirs ()) |> print_endline;
  printf "SATySFi user directory: ";
  [%derive.show: string option] (SatysfiDirs.user_dir ()) |> print_endline;
  printf !"Selected OPAM SATySFi library registry: %{sexp:OpamSatysfiRegistry.t option}\n" env.opam_reg ;
  printf !"Selected SATySFi runtime distribution: %{sexp: string option}\n" env.dist_library_dir


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
