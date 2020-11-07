open Core
open BuildScript_prim


let recursively f base_dir src acc =
  let base_src = FilePath.concat base_dir src in
  FileUtil.(find Is_file base_src (fun acc path ->
    let dst = FilePath.make_relative base_src path in
    let src_path = FilePath.make_relative base_dir path in
    f dst src_path acc
  )) acc

type font =
  | Single of string
  | Collection of string * int
[@@deriving sexp]

let add_files dst src acc = `File {dst; src} :: acc
let add_fonts dst src acc = `Font {dst; src} :: acc
let add_font_with_hash dst src names acc =
  let conv_name = function
    | Single name ->
      `Single name
    | Collection (name, index) ->
     `Collection (name, index)
  in
  `FontWithHash ({dst; src}, List.map ~f:conv_name names) :: acc
let add_hashes dst src acc = `Hash {dst; src} :: acc
let add_packages dst src acc = `Package {dst; src} :: acc
let add_doc dst src acc = `Doc {dst; src} :: acc

type source =
  | File of string * string
  | Font of string * string * font list
  | FontDir of string
  | Hash of string * string
  | Package of string * string
  | PackageDir of string
[@@deriving sexp]

type documentSource =
  | Doc of string * string
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
  | Lang of string
  | Library of {
    name: string;
    version: string;
    opam: string;
    sources: source list
      [@sexp.omit_nil];
    dependencies: string list
      [@sexp.omit_nil];
    autogen: string list [@sexp.omit_nil];
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
    dependencies: string list
      [@sexp.omit_nil];
    autogen: string list [@sexp.omit_nil];
  } [@sexpr.list]
  | Doc of {
      name: string;
      workingDirectory: string [@default "."];
      build: string list list [@sexp.omit_nil];
      dependencies: string list
                    [@sexp.omit_nil];
      autogen: string list [@sexp.omit_nil];
    } [@sexpr.list]
  [@@deriving sexp]
end

module StringMap = Map.Make(String)
module StringSet = Set.Make(String)

type t = m StringMap.t [@@deriving sexp]

let load_sections f =
  Sexp.Annotated.load_sexps f
  |> List.map ~f:(fun e -> Sexp.Annotated.get_range e, Sexp.Annotated.get_sexp e |> [%of_sexp: Section.t])

let parse_build_command = function
  | "run" :: cmd :: args ->
    Run (cmd, args)
  | "run" :: _ ->
    failwithf "run command requires a executable name like (run <cmd> <args>...)" ()
  | "make" :: args ->
    Make args
  | "make-with-env-var" :: args ->
    MakeWithEnvVar args
  | "satysfi" :: args ->
    Satysfi args
  | "omake" :: args ->
    OMake args
  | cmd -> failwithf "command %s is not supported" ([%sexp_of: string list] cmd |> Sexp.to_string) ()

let section_to_modules ~base_dir (range, (m : Section.t)) =
  match m with
  | Section.Lang "0.0.3" -> []
  | Lang v ->
    failwithf "BUG: section_to_modules: expects build script version 0.0.3, but got %s" v ()
  | Library {name; version; opam; sources; dependencies; compatibility; autogen;} ->
    let sources = List.fold_left ~init:empty_sources ~f:begin fun acc -> function
        | File (dst, src) -> add_files dst src acc
        | Font (dst, src, names) -> add_font_with_hash dst src names acc
        | Hash (dst, src) -> add_hashes dst src acc
        | Package (dst, src) -> add_packages dst src acc
        | FontDir (src) -> recursively add_fonts base_dir src acc
        | PackageDir (src) -> recursively add_packages base_dir src acc
      end sources in
    let dependencies = dependencies |> Library.Dependency.of_list in
    let autogen = autogen |> Library.Dependency.of_list in
    let compatibility =
      List.map ~f:Compatibility.to_internal compatibility
      |> CompatibilitySet.of_list
    in
    let position = Some (position_of_range range) in
    [name, Library {name; version; opam; sources; dependencies; compatibility; position; autogen; }]
  | LibraryDoc {name; version; opam; workingDirectory: string; build; sources; dependencies; autogen;} ->
    if String.suffix name 4 |> String.equal "-doc" |> not
    then failwithf "libraryDoc must have suffix -doc but got %s" name ();
    let dependencies = dependencies |> Library.Dependency.of_list in
    let autogen = autogen |> Library.Dependency.of_list in
    let sources = List.fold_left ~init:empty_sources ~f:begin fun acc -> function
        | Doc (dst, src) -> add_doc dst src acc
      end sources in
    let build =
      List.map ~f:parse_build_command build
    in
    let position = Some (position_of_range range) in
    [name, LibraryDoc {name; version; opam; workingDirectory: string; build; sources; dependencies; position; autogen; }]
  | Doc {name; workingDirectory; build; dependencies; autogen;} ->
    let position = Some (position_of_range range) in
    let build =
      List.map ~f:parse_build_command build
    in
    let dependencies = dependencies |> Library.Dependency.of_list in
    let autogen = autogen |> Library.Dependency.of_list in
    [name, Doc {name; workingDirectory; build; dependencies; position; autogen;}]

let sections_to_modules ~base_dir sections =
  let modules = sections |> List.concat_map ~f:(section_to_modules ~base_dir) in
  modules
  |> StringMap.of_alist_exn

let load f =
  let base_dir = FilePath.dirname f in
  load_sections f
  |> sections_to_modules ~base_dir

let migrate_from_0_0_2 =
  let module BS2 = BuildScript_0_0_2 in
  let module Section2 = BuildScript_0_0_2.Section in
  let conv_source = function
    | BS2.File (dst, src) ->
      File (dst, src)
    | BS2.Font (dst, src) ->
      Font (dst, src, [])
    | BS2.Hash (dst, src) ->
      Hash (dst, src)
    | BS2.Package (dst, src) ->
      Package (dst, src)
    | BS2.FontDir (src) ->
      FontDir (src)
    | BS2.PackageDir (src) ->
      PackageDir (src)
  in
  let conv_document_source = function
    | BS2.Doc (dst, src) ->
      Doc (dst, src)
  in
  let conv_compatibility = function
    | BS2.Compatibility.Satyrographos _ ->
      None
    | RenamePackage (n, o) ->
      Some (Compatibility.RenamePackage (n, o))
    | RenameFont (n, o) ->
      Some (RenameFont (n, o))
  in
  let conv_section = function
    | Section2.Version _ ->
      Section.Lang "0.0.3"
    | Section2.Library l ->
      Section.Library {
        name = l.name;
        version = l.version;
        opam = l.opam;
        sources = List.map ~f:conv_source l.sources;
        dependencies = l.dependencies |> List.map ~f:fst;
        compatibility =
          l.compatibility
          |> List.filter_map ~f:conv_compatibility ;
        autogen = [];
      }
    | Section2.LibraryDoc l ->
      Section.LibraryDoc {
        name = l.name;
        version = l.version;
        opam = l.opam;
        sources = List.map ~f:conv_document_source l.sources;
        workingDirectory = l.workingDirectory;
        build = l.build;
        dependencies = l.dependencies |> List.map ~f:fst;
        autogen = [];
      }
  in
  conv_section

let save_sections f ss =
  ss
  |> List.map ~f:[%sexp_of: Section.t]
  |> Sexp.save_sexps_hum f
