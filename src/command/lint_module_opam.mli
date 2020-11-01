open Satyrographos
open Lint_prim

val lint_module_opam :
  locs:location list ->
  basedir:string ->
  BuildScript_prim.m ->
  string -> diagnosis list
