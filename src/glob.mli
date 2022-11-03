module TokenMatcher : sig
  type 'a t

  val empty : 'a t

  val exec : 'a t -> string list -> 'a option
end

val parse_as_tm_exn : Lexing.lexbuf -> bool TokenMatcher.t

val split_on_slash : string -> string list
