open Satyrographos

val run_satysfi_command : satysfi_runtime:string -> string list -> unit Shexp_process.t

val satysfi_command :
  outf:Format.formatter ->
  system_font_prefix:string option ->
  autogen_libraries:string list ->
  libraries:string list option ->
  verbose:bool ->
  project_env:Environment.project_env option ->
  env:Environment.t ->
  string list ->
  int Shexp_process.t
