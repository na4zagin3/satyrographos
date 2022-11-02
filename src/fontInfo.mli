module Font : sig
  type lang = string
    [@@deriving sexp, compare]

  type t = {
    file: string;
    postscriptname: string;
    index: int;
    fontformat: string;
    family: (string * lang) list;
    style: (string * lang) list;
    fullname: (string * lang) list;
    slant: int;
    weight: float;
    width: int;
    foundry: string;
    verticallayout: string; (* TODO It should be int, though*)
    outline: bool;
    scalable: bool;
    color: bool;
    charset: string;
    lang: lang list;
    fontversion: int;
    fontfeatures: string;
    namelang: string;
    prgname: string;
  } [@@deriving sexp, compare]

end

module DistinctFont : sig
  type t = {
    file: string;
    index: int;
  } [@@deriving sexp, compare]

  val of_font : Font.t -> t
end

module DistinctFontMap : sig
  include Core.Map.S with type Key.t = DistinctFont.t
end

val font_info_list_task : string list -> unit Shexp_process.t

val font_list_task : outf:Format.formatter -> unit Shexp_process.t -> Font.t DistinctFontMap.t Shexp_process.t
