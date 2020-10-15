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

(** Whether if the current Satyrographos depot exists and it’s in the current supported schema. *)
val depot_exists : unit -> bool

(** Initialize the depot directory only when it does not exist or is not initialized. *)
val initialize : unit -> unit

(** Try to read Satyrographos depot. If the depot does not exists, throws an error. *)
val read_depot_exn : unit -> Satyrographos.Environment.depot

(** Default location of target of install subcommand *)
val default_target_dir : string

(** Read current runtime-dependent information.
    This command SHOULD NOT affect the environment. *)
val read_environment : unit -> Satyrographos.Environment.t
