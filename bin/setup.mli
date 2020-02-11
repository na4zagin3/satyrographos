(** Satyrographos depot schema version. *)
val scheme_version : int

(** Home directory. TODO Remove this. *)
val home_dir : string

(** Satyrographos depot directory path. *)
val root_dir : string

(** Satyrographos source repository directory path. *)
val repository_dir : string
(** Satyrographos binary registry directory path. TODO Rename. *)
val library_dir : string
(** Satyrographos metadata file path. *)
val metadata_file : string

(** Satyrographos depot schema version of the current depot directory. *)
val current_scheme_version : int option

(** Whether if the current Satyrographos depot exists and it’s in the current supported schema. TODO Rename. *)
val repository_exists : unit -> bool

(** Initialize the depot directory only when it does not exist or is not initialized. *)
val initialize : unit -> unit

(** OPAM registry. TODO Rename and/or make it private *)
val reg_opam : Satyrographos.OpamSatysfiRegistry.t option

(** Try to read Satyrographos depot. It returns None if it does not exists.
    TODO Rename and/or make it private *)
val try_read_repo : unit -> Satyrographos.Environment.repo option

(** Try to read Satyrographos depot. If the depot does not exists, it returns a new initialized depot.
    TODO Rename and work on Environment.t instead *)
val read_repo : unit -> Satyrographos.Environment.repo

(** Default location of target of install subcommand *)
val default_target_dir : string

(** Read current runtime-dependent information.
    This command SHOULD NOT affect the environment. *)
val read_environment : unit -> Satyrographos.Environment.t
