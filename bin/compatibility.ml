open Core

let optin () =
  match Sys.getenv "SATYROGRAPHOS_EXPERIMENTAL" with
  | Some "1" ->
    Printf.fprintf Out_channel.stderr "Compatibility warning: You have opted in to use experimental features.\n";
    Out_channel.flush Out_channel.stderr
  | _ ->
    Printf.fprintf Out_channel.stderr "Compatibility warning: This is an experimental feature.\n";
    Printf.fprintf Out_channel.stderr "You have to opt in by setting env variable SATYROGRAPHOS_EXPERIMENTAL=1 to test this feature.\n";
    exit 1
