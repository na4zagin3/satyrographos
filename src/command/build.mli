open Satyrographos

val read_module :
  outf:Format.formatter ->
  verbose:bool ->
  build_module:BuildScript_prim.m ->
  buildscript_path:string ->
  string * Library.t

val build :
  outf:Format.formatter ->
  build_dir:string option ->
  verbose:bool ->
  build_module:BuildScript_prim.m ->
  buildscript_path:string ->
  system_font_prefix:string option ->
  env:Environment.t ->
  unit

val build_command :
  outf:Format.formatter ->
  buildscript_path:string ->
  names:string list option ->
  verbose:bool ->
  env:Environment.t ->
  build_dir:string option ->
  unit
