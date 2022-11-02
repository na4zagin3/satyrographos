open Satyrographos

type persistent_autogen = Satyrographos_lockdown.LockdownFile.autogen

val get_library_map :
  outf:Format.formatter ->
  system_font_prefix:string option ->
  autogen_libraries:string list ->
  libraries:string list option ->
  env:Environment.t ->
  persistent_autogen:persistent_autogen ->
  unit ->
  (string, Library.t, Library.StringSet.Elt.comparator_witness) Base.Map.t

val install :
  string ->
  outf:Format.formatter ->
  system_font_prefix:string option ->
  ?autogen_libraries:string list ->
  libraries:string list option ->
  verbose:bool ->
  ?safe:bool ->
  copy:bool ->
  env:Environment.t ->
  persistent_autogen:persistent_autogen ->
  unit ->
  unit
