type library_name = string

type entry = {
  url: Uri_sexp.t;
} [@@deriving sexp]

type store

val initialize : store -> unit

val list : store -> library_name list

val find : store -> library_name -> entry option

val mem : store -> library_name -> bool

val remove_multiple : store -> library_name list -> unit

val add : store -> library_name -> entry -> unit
