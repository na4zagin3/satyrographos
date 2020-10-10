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

module StringMap = Map.Make(String)
module StringSet = Set.Make(String)

type t = m StringMap.t [@@deriving sexp]

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

let get_dependencies_opt = function
  | Library l -> Some l.dependencies
  | LibraryDoc l -> Some l.dependencies

let get_name = function
  | Library l -> l.name
  | LibraryDoc l -> l.name

let get_opam_opt = function
  | Library l -> Some l.opam
  | LibraryDoc l -> Some l.opam

let get_version_opt = function
  | Library l -> Some l.version
  | LibraryDoc l -> Some l.version

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
  let map_file dst_dir =
    let append_prefix =
      if String.is_empty dst_dir
      then ident
      else Filename.concat dst_dir in
    List.map ~f:(fun (dst, src) -> (append_prefix dst, Filename.concat src_dir src))
  in
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
    files =
      List.concat [other_files; fonts; packages]
      |> List.map ~f:(fun (dst, fn) -> dst, `Filename fn)
      |> Library.LibraryFiles.of_alist_exn;
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
  |> List.map ~f:(function (dst, src) -> (dst, `Filename src))
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
