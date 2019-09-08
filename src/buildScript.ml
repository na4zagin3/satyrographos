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

module CompatibilityIdents = Set.Make(String)
module Compatibility = struct
  type t =
    | Satyrographos of string
    | RenamePackage of string * string
    | RenameFont of string * string
    [@@deriving sexp, compare]
end
module CompatibilitySet = Set.Make(Compatibility)

type library = {
  name: string;
  version: string;
  opam: string;
  sources: sources [@sexp.omit_nil];
  dependencies: Library.Dependency.t [@sexp.omit_nil];
  compatibility: CompatibilitySet.t [@sexp.omit_nil];
} [@@deriving sexp]

type documentSource =
  | Doc of string * string
[@@deriving sexp]

type libraryDoc = {
  name: string;
  version: string;
  opam: string;
  workingDirectory: string;
  build: string list list [@sexp.omit_nil];
  sources: documentSource list [@sexp.omit_nil];
  dependencies: Library.Dependency.t [@sexp.omit_nil];
} [@@deriving sexp]

type m = Library of library | LibraryDoc of libraryDoc
  [@@deriving sexp]

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
    compatibility: CompatibilitySet.t [@sexp.omit_nil];
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

let from_file f =
  let sections = Sexp.load_sexps_conv_exn f [%of_sexp: Section.t] in
  let modules = sections |> List.concat_map ~f:(function
    | Version "0.0.2" -> []
    | Version v ->
      failwithf "This Saytorgraphos only supports build script version 0.0.2, but got %s" v ()
    | Library {name; version; opam; sources; dependencies; compatibility} ->
      let sources = List.fold_left ~init:empty_sources ~f:begin fun acc -> function
        | File (dst, src) -> add_files dst src acc
        | Font (dst, src) -> add_fonts dst src acc
        | Hash (dst, src) -> add_hashes dst src acc
        | Package (dst, src) -> add_packages dst src acc
      end sources in
      let dependencies = List.map dependencies ~f:fst |> Library.Dependency.of_list in
      [name, Library {name; version; opam; sources; dependencies; compatibility}]
    | LibraryDoc {name; version; opam; workingDirectory: string; build; sources; dependencies;} ->
      if String.suffix name 4 |> String.equal "-doc" |> not
      then failwithf "libradiDoc must have suffic -doc but got %s" name ();
      let dependencies = List.map dependencies ~f:fst |> Library.Dependency.of_list in
      [name, LibraryDoc {name; version; opam; workingDirectory: string; build; sources; dependencies;}]
  ) in
  modules
  |> StringMap.of_alist_exn

let library_to_opam_file name =
  let name = OpamPackage.Name.of_string ("satysfi-" ^ name) in
  OpamFile.OPAM.empty
  |> OpamFile.OPAM.with_name name

let library_doc_to_opam_file name =
  let name = OpamPackage.Name.of_string ("satysfi-" ^ name ^ "-doc") in
  OpamFile.OPAM.empty
  |> OpamFile.OPAM.with_name name

let export_opam_package = function
  | Library p ->
    let file = OpamFilename.raw p.opam in
    library_to_opam_file p.name
    |> OpamFile.OPAM.write (OpamFile.make file)
  | LibraryDoc p ->
    let file = OpamFilename.raw p.opam in
    library_doc_to_opam_file p.name
    |> OpamFile.OPAM.write (OpamFile.make file)

let export_opam bs =
  StringMap.iter bs ~f:export_opam_package

let get_name = function
  | Library l -> l.name
  | LibraryDoc l -> l.name

(* Compatibility treatment *)
let compatibility_treatment (p: library) (l: Library.t) =
  let f = function
    | Compatibility.RenamePackage (n, o) ->
      Library.Compatibility.{ empty with
        rename_packages = Library.RenameSet.singleton Library.Rename.{
          new_name = n;
          old_name = o;
        }
      }
    | Compatibility.RenameFont (n, o) ->
      Library.Compatibility.{ empty with
        rename_fonts = Library.RenameSet.singleton Library.Rename.{
          new_name = n;
          old_name = o;
        }
      }
    | Satyrographos "0.0.1" ->
      let open Library in
      let rename_packages = List.map p.sources.packages ~f:(fun (name, _) ->
        let old_package_name = name in
        let new_package_name = p.name ^ "/" ^ name in
        Rename.{ old_name = old_package_name; new_name = new_package_name }
      ) |> RenameSet.of_list in
      Compatibility.{ empty with
        rename_packages
      }
    | unknown_symbol -> begin
      let unknown_symbol =
      unknown_symbol
      |> [%sexp_of: Compatibility.t]
      |> Sexp.to_string_hum
      in
      failwithf "Unknown compatibility symbols: %s\n" unknown_symbol ()
  end
  in
  let compatibility =
    CompatibilitySet.to_list p.compatibility
    |> List.map ~f
    |> Library.Compatibility.union_list
  in
  Library.(union l { empty with compatibility})

(* Read *)
let read_library (p: library) ~src_dir =
  let map_file dst_dir = List.map ~f:(fun (dst, src) -> (Filename.concat dst_dir dst, Filename.concat src_dir src)) in
  let other_files = map_file "" p.sources.files in
  let hashes =
    map_file "hash" p.sources.hashes
    |> List.fold ~init:Library.empty ~f:(fun a (dst, src) -> Library.add_hash dst src a)
  in
  let fonts = map_file (Filename.concat "fonts" p.name) p.sources.fonts in
  let packages = map_file (Filename.concat "packages" p.name) p.sources.packages in
  Library.{ empty with
   name = Some p.name;
   version = Some p.version;
   files=List.concat [other_files; fonts; packages] |> Library.LibraryFiles.of_alist_exn;
   dependencies=p.dependencies;
  }
  |> Library.union hashes
  |> compatibility_treatment p

let read_libraryDoc (p: libraryDoc) ~src_dir =
  let map_file dst_dir = List.map ~f:(fun (dst, src) -> (Filename.concat dst_dir dst, Filename.concat src_dir src)) in
  let docs =
  p.sources
  |> List.map ~f:(function Doc (dst, src) -> (dst, src))
  |> map_file (Filename.concat "docs" p.name)
  in
  Library.{ empty with
   name = Some p.name;
   version = Some p.version;
   files=Library.LibraryFiles.of_alist_exn docs;
   dependencies=p.dependencies;
  }

let read_module = function
  | Library l -> read_library l
  | LibraryDoc l -> read_libraryDoc l
