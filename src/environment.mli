(** A type represents runtime environment. *)
type t = {
  opam_reg: OpamSatysfiRegistry.t option;
  (** OPAM Registry. I.e., ~/.satyrograpos *)

  dist_library_dir: string option;
  (** A directory with SATySFi dist for the current SATySFi compiler.
      Typically, this points a directory under OPAM reg or /usr/local/share/satysfi/dist. *)
}

(** An empty runtime environment. *)
val empty: t

(** Environment for child Satyrographos processes *)
type project_env = {
  buildscript_path: string;
  satysfi_runtime_dir: string;
}
[@@deriving sexp]

(* TODO Rename with satysfi_root_dir *)
val get_satysfi_runtime_dir : project_env -> string

val get_satysfi_dist_dir : project_env -> string

val set_project_env_cmd : project_env -> 'a Shexp_process.t -> 'a Shexp_process.t

val get_project_env_cmd : project_env option Shexp_process.t

val get_project_env : unit -> project_env option
