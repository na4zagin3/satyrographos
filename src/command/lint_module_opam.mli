open Satyrographos
open Lint_prim

val lint_module_opam :
  loc:location list ->
  basedir:string ->
  BuildScript_prim.m ->
  string -> diagnosis list
