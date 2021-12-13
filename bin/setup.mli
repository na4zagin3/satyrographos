(** Default location of target of install subcommand *)
val default_target_dir : string

(** Read current runtime-dependent information.
    This command SHOULD NOT affect the environment. *)
val read_environment : ?opam_switch:OpamTypes.switch -> unit -> Satyrographos.Environment.t
