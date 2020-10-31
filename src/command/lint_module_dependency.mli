open Satyrographos
open Lint_prim

val lint_module_dependency :
  outf:Format.formatter ->
  loc:location list ->
  satysfi_version:Satyrographos_satysfi.Version.t ->
  basedir:string ->
  env:Environment.t ->
  BuildScript_prim.m -> diagnosis list
