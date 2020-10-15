open Core
open Satyrographos

(* TODO Use formatter instead of printf *)

let pin_list ~outf:(_: Format.formatter) repo =
  [%derive.show: string list] (Repository.list repo) |> print_endline

let pin_dir ~outf:(_: Format.formatter) repo p =
  Repository.directory repo p |> print_endline

let pin_add ~outf depot p url =
  let Environment.{ repo; reg; } = depot in
  let (_: string list option) =
  Uri.of_string url
  |> Repository.add ~outf repo p in
  Printf.printf "Added %s (%s)\n" p url;
  Registry.update_all ~outf reg
  |> [%derive.show: string list option]
  |> Printf.printf "Built libraries: %s\n"

let pin_remove ~outf:(_: Format.formatter) repo p =
  (* TODO remove the library *)
  Repository.remove repo p;
  Printf.printf "Removed %s\n" p
