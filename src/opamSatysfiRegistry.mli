type t
[@@deriving sexp]

val read : string -> t option

val list : t -> string list

val directory : t -> string -> string
