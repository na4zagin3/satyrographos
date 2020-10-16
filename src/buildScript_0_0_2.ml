open Core
open BuildScript_prim


let recursively f base_dir src acc =
  let base_src = FilePath.concat base_dir src in
  FileUtil.(find Is_file base_src (fun acc path ->
    let dst = FilePath.make_relative base_src path in
    let src_path = FilePath.make_relative base_dir path in
    f dst src_path acc
  )) acc

let add_files dst src acc = `File {dst; src} :: acc
let add_fonts dst src acc = `Font {dst; src} :: acc
let add_hashes dst src acc = `Hash {dst; src} :: acc
let add_packages dst src acc = `Package {dst; src} :: acc

type source =
  | File of string * string
  | Font of string * string
  | FontDir of string
  | Hash of string * string
  | Package of string * string
  | PackageDir of string
[@@deriving sexp]

module Compatibility = struct
  type t =
    | Satyrographos of string
    | RenamePackage of string * string
    | RenameFont of string * string
    [@@deriving sexp, compare]

  let to_internal = function
    | Satyrographos v -> BuildScript_prim.Compatibility.Satyrographos v
    | RenamePackage (n, o) -> BuildScript_prim.Compatibility.RenamePackage (n, o)
    | RenameFont (n, o) -> BuildScript_prim.Compatibility.RenameFont (n, o)
end

module Section = struct
  type t =
  | Version of string
  | Library of {
    name: string;
    version: string;
    opam: string;
    sources: source list
      [@sexp.omit_nil];
    dependencies: (string * unit (* for future extension *)) list
      [@sexp.omit_nil];
    compatibility: Compatibility.t list [@sexp.omit_nil];
    (*
      sources: source list [@sexp.omit_nil];
    *)
    (* sources: source sexp_list; *)
  } [@sexpr.list]
  | LibraryDoc of {
    name: string;
    version: string;
    opam: string;
    workingDirectory: string [@default "."];
    build: string list list [@sexp.omit_nil];
    sources: documentSource list
      [@sexp.omit_nil];
    dependencies: (string * unit (* for future extension *)) list
      [@sexp.omit_nil];
  } [@sexpr.list]
  [@@deriving sexp]
end

module StringMap = Map.Make(String)
module StringSet = Set.Make(String)

type t = m StringMap.t [@@deriving sexp]

let load_sections f =
  Sexp.Annotated.load_sexps f
  |> List.map ~f:(fun e -> Sexp.Annotated.get_range e, Sexp.Annotated.get_sexp e |> [%of_sexp: Section.t])

let section_to_modules ~base_dir (range, (m : Section.t)) =
  match m with
  | Section.Version "0.0.2" -> []
    | Version v ->
      failwithf "This Saytorgraphos only supports build script version 0.0.2, but got %s" v ()
    | Library {name; version; opam; sources; dependencies; compatibility} ->
      let sources = List.fold_left ~init:empty_sources ~f:begin fun acc -> function
        | File (dst, src) -> add_files dst src acc
        | Font (dst, src) -> add_fonts dst src acc
        | Hash (dst, src) -> add_hashes dst src acc
        | Package (dst, src) -> add_packages dst src acc
        | FontDir (src) -> recursively add_fonts base_dir src acc
        | PackageDir (src) -> recursively add_packages base_dir src acc
      end sources in
      let dependencies = List.map dependencies ~f:fst |> Library.Dependency.of_list in
      let compatibility =
        List.map ~f:Compatibility.to_internal compatibility
        |> CompatibilitySet.of_list
      in
      let position = Some (position_of_range range) in
      [name, Library {name; version; opam; sources; dependencies; compatibility; position; }]
    | LibraryDoc {name; version; opam; workingDirectory: string; build; sources; dependencies;} ->
      if String.suffix name 4 |> String.equal "-doc" |> not
      then failwithf "libradiDoc must have suffic -doc but got %s" name ();
      let dependencies = List.map dependencies ~f:fst |> Library.Dependency.of_list in
      let position = Some (position_of_range range) in
      [name, LibraryDoc {name; version; opam; workingDirectory: string; build; sources; dependencies; position; }]

let sections_to_modules ~base_dir sections =
  let modules = sections |> List.concat_map ~f:(section_to_modules ~base_dir) in
  modules
  |> StringMap.of_alist_exn

let load f =
  let base_dir = FilePath.dirname f in
  load_sections f
  |> sections_to_modules ~base_dir
