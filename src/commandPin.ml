open Core

let outf = Format.std_formatter

(* TODO Receive env instead of repo *)
let pin_list repo =
  [%derive.show: string list] (Repository.list repo) |> print_endline

(* TODO Receive env instead of repo *)
let pin_dir repo p =
  Repository.directory repo p |> print_endline

let pin_add env p url =
  let Environment.{ repo; reg; } = env in
  let (_: string list option) =
  Uri.of_string url
  |> Repository.add ~outf repo p in
  Printf.printf "Added %s (%s)\n" p url;
  Registry.update_all ~outf reg
  |> [%derive.show: string list option]
  |> Printf.printf "Built libraries: %s\n"

(* TODO Receive env instead of repo *)
let pin_remove repo p =
  (* TODO remove the library *)
  Repository.remove repo p;
  Printf.printf "Removed %s\n" p
