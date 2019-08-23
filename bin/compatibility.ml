open Core

let optin () =
  match Sys.getenv "SATYROGRAPHOS_EXPERIMENTAL" with
  | Some "1" ->
    Printf.printf "Compatibility warning: You have opted in to use experimental features.\n"
  | _ ->
    Printf.printf "Compatibility warning: This is an experimental feature.\n";
    Printf.printf "You have to opt in by setting env variable SATYROGRAPHOS_EXPERIMENTAL=1 to test this feature.\n";
    exit 1
