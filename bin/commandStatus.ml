open Satyrographos
open Core

open Setup


let status () =
  printf "Scheme version: ";
  [%derive.show: int option] current_scheme_version |> print_endline;
  try_read_repo () |> Option.iter ~f:(fun { repo; reg; } ->
    printf "Source repository: ";
    [%derive.show: string list] (Repository.list repo) |> print_endline;
    printf "Built library registry: ";
    [%derive.show: string list] (Registry.list reg) |> print_endline;);
  printf "SATySFi runtime directories: ";
  [%derive.show: string list] (SatysfiDirs.runtime_dirs ()) |> print_endline;
  printf "SATySFi user directory: ";
  [%derive.show: string option] (SatysfiDirs.user_dir ()) |> print_endline;
  printf "Selected SATySFi runtime distribution: %s\n" (SatysfiDirs.satysfi_dist_dir ())

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
