module P = Shexp_process

(** [redirect_to_stdout ~prefix ~prefix_out ~prefix_err c] return a command where
    stdout and stderr from the given [c] are redirected to stdout with given prefixes. *)
val redirect_to_stdout : ?prefix:string ->
?prefix_out:string -> ?prefix_err:string -> unit P.t -> unit P.t
