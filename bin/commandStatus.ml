open Satyrographos
open Core

module SatysfiDirs = Satyrographos_satysfi.SatysfiDirs


let outf = Format.std_formatter

let status () =
  printf "Scheme version: ";
  [%derive.show: int option] Setup.current_scheme_version |> print_endline;
  let env = Setup.read_environment () in
  env.depot |> Option.iter ~f:(fun { repo; reg; } ->
    printf "Source repository: ";
    [%derive.show: string list] (Repository.list repo) |> print_endline;
    printf "Built library registry: ";
    [%derive.show: string list] (Registry.list reg) |> print_endline;);
  printf "SATySFi runtime directories: ";
  [%derive.show: string list] (SatysfiDirs.runtime_dirs ()) |> print_endline;
  printf "SATySFi user directory: ";
  [%derive.show: string option] (SatysfiDirs.user_dir ()) |> print_endline;
  [%derive.show: string option] (SatysfiDirs.satysfi_dist_dir ~outf)
  |> printf "Selected SATySFi runtime distribution: %s\n"

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
