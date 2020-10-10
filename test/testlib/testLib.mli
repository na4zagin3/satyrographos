open Shexp_process

val exec_log_file_path : string -> string

val repeat_string : int -> string -> string
(** [repeat_string n s] returns a string, repeating string [s] [n]-times. *)

val censor : (string * string) list -> unit t
(** [censor wordlist] returns a Shexp process which behaves like a sed which replaces words in the given word lists.

    [wordlist] is an associative list of pairs of a censored word and a replecement. *)

val censor_tempdirs : unit t
(** [censor_tempdirs] returns a Shexp process which behaves like a sed which masks
    paths to temporary directories *)

val with_formatter : ?where:Std_io.t -> (Format.formatter -> 'a) -> 'a t
(** [with_formatter ~where f] returns a Shexp process which executes [f] with a formatter which redirect to
    the given Shexp IO [where], whose default value is [Stdout] *)

val echo_line : unit t
(** A Shexp process which output a horizontal line to Stdout. *)

val dump_dir : string -> unit t
(** [dump_dir dir] returns a Shexp process which dumps directory [dir]’s content to Stdout. *)

val run_function : (outf:Format.formatter -> unit) -> unit t
(** [run_fuction f] return a Shexp running [f ~outf] where [~outf] is a Formatter.
    Exceptions raised by [f] will be caught and its stacktraces will be output. *)

val test_install :
  ?replacements:(string * string) list ->
  (dest_dir:string -> temp_dir:string -> 'a t) ->
  ('a -> dest_dir:string -> temp_dir:string -> outf:Format.formatter -> unit) ->
  unit t

val read_env : ?repo:unit -> ?opam_reg:string -> ?dist_library_dir:string -> unit -> Satyrographos.Environment.t

val prepare_files :
  string -> (string * string) list -> unit t
(** [prepare_files dir files] creates [files] under [directory] *)

val opam_file_for_test :
  ?synopsis:string ->
  ?name:string ->
  ?version:string ->
  ?description:string -> ?depends:string -> ?satysfi_name:string -> unit -> string
