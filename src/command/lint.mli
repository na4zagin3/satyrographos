open Satyrographos

val lint :
  outf:Format.formatter ->
  satysfi_version:Satyrographos_satysfi.Version.t ->
  warning_expr:bool Glob.TokenMatcher.t option ->
  verbose:bool ->
  buildscript_path:string option ->
  env:Environment.t ->
  int

val get_opam_name : opam:OpamFile.OPAM.t -> opam_path:string -> string
