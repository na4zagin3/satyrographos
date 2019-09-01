open Core

type sources = {
  files: (string * string) list
    [@sexp.omit_nil];
  fonts: (string * string) list
    [@sexp.omit_nil];
  hashes: (string * string) list
    [@sexp.omit_nil];
  packages: (string * string) list
    [@sexp.omit_nil];
}
[@@deriving sexp]

let empty_sources = {
  files=[];
  fonts=[];
  hashes=[];
  packages=[];
}

let add_files dst src acc = {acc with files=(dst, src) :: acc.files}
let add_fonts dst src acc = {acc with fonts=(dst, src) :: acc.fonts}
let add_hashes dst src acc = {acc with hashes=(dst, src) :: acc.hashes}
let add_packages dst src acc = {acc with packages=(dst, src) :: acc.packages}

type source =
  | File of string * string
  | Font of string * string
  | Hash of string * string
  | Package of string * string
[@@deriving sexp]

(*
let sexp_of_source = function
  | File (dst, src) ->
    ["file"; dst; src] |> [%sexp_of: string list]
  | Font (dst, src) ->
    ["font"; dst; src] |> [%sexp_of: string list]
  | Hash (dst, src) ->
    ["hash"; dst; src] |> [%sexp_of: string list]
  | Package (dst, src) ->
    ["package"; dst; src] |> [%sexp_of: string list]

let source_of_source sexp =
  let list = [%of_sexp: string list] sexp in
  match list with
  | ["file"; dst; src] -> File (dst, src)
  | ["font"; dst; src] -> Font (dst, src)
  | ["hash"; dst; src] -> Hash (dst, src)
  | ["package"; dst; src] -> Package (dst, src)
  | _ -> Error.create "Source must be (<type> <dst> <src>) where <type> is either file, font, hash, or package" sexp ident
      |> Error.raise
*)

type package = {
  name: string;
  opam: string;
  sources: sources [@sexp.omit_nil];
} [@@deriving sexp]

type section = Package of {
  name: string;
  opam: string;
  sources: source list [@sexp.list] [@sexp.omit_nil];
  (*
    sources: source list [@sexp.omit_nil];
  *)
  (* sources: source sexp_list; *)
} [@sexpr.list]
[@@deriving sexp]

module StringMap = Map.Make(String)

type t = package StringMap.t [@@deriving sexp]

(*
*)
let input ch =
  let sexp = Sexp.input_sexps ch in
  let modules = sexp |> List.concat_map ~f:(fun sexp ->
    match [%of_sexp: section] sexp with
    | Package {name; opam; sources} ->
      let sources = List.fold_left ~init:empty_sources ~f:begin fun acc -> function
        | File (dst, src) -> add_files dst src acc
        | Font (dst, src) -> add_fonts dst src acc
        | Hash (dst, src) -> add_hashes dst src acc
        | Package (dst, src) -> add_packages dst src acc
      end sources in
      [{name; opam; sources}]
  ) in
  List.map ~f:(fun m -> m.name, m) modules
  |> StringMap.of_alist_exn

let from_file f =
  Unix.(with_file f ~mode:[O_RDONLY] ~f:(fun fd ->
    input (in_channel_of_descr fd)))

let package_to_opam_file p =
  let name = OpamPackage.Name.of_string ("satysfi-" ^ p.name) in
  OpamFile.OPAM.empty
  |> OpamFile.OPAM.with_name name

let export_opam_package p =
  let file = OpamFilename.raw p.opam in
  package_to_opam_file p
  |> OpamFile.OPAM.write (OpamFile.make file)

let export_opam bs =
  StringMap.iter bs ~f:export_opam_package
