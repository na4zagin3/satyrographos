open Satyrographos

(** List current packages stored in the given Satyrographos repository. *)
(* TODO Receive env instead of repo *)
val pin_list : outf:Format.formatter -> Repository.t -> unit

(** [pin_dir ~outf repo package_name]
    Show directory in which the given package is stored. *)
(* TODO Receive env instead of repo *)
val pin_dir : outf:Format.formatter -> Repository.t -> string -> unit

(** [pin_add ~outf depot package_name url]
    Register library [package_name] stored in [url], followed by building all the packages in the repository.
    TODO Build only related packages.
    TODO Error handling.
    TODO Retrieving remote codes. *)
(* TODO Receive env instead of depot *)
val pin_add : outf:Format.formatter -> Environment.depot -> string -> string -> unit

(** [pin_remove ~outf repo package_name]
    Remove library [package_name] from the repo.
    TODO Remove the library from registry.
    TODO Error handling. *)
(* TODO Receive env instead of repo *)
val pin_remove : outf:Format.formatter -> Repository.t -> string -> unit
