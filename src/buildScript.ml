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
type package = {
  name: string;
  opam: string;
  sources: sources [@sexp.omit_nil];
  dependencies: Library.Dependency.t [@sexp.omit_nil];
  compatibility: CompatibilityIdents.t [@sexp.omit_nil];
} [@@deriving sexp]

type section = Library of {
  name: string;
  opam: string;
  sources: source list
    [@sexp.list] [@sexp.omit_nil];
  dependencies: (string * unit (* for future extension *)) list
    [@sexp.list] [@sexp.omit_nil];
  compatibility: CompatibilityIdents.t [@sexp.omit_nil];
  (*
    sources: source list [@sexp.omit_nil];
  *)
  (* sources: source sexp_list; *)
} [@sexpr.list]
[@@deriving sexp]

module StringMap = Map.Make(String)
module StringSet = Set.Make(String)

type t = package StringMap.t [@@deriving sexp]

let input ch =
  let sexp = Sexp.input_sexps ch in
  let modules = sexp |> List.concat_map ~f:(fun sexp ->
    match [%of_sexp: section] sexp with
    | Library {name; opam; sources; dependencies; compatibility} ->
      let sources = List.fold_left ~init:empty_sources ~f:begin fun acc -> function
        | File (dst, src) -> add_files dst src acc
        | Font (dst, src) -> add_fonts dst src acc
        | Hash (dst, src) -> add_hashes dst src acc
        | Package (dst, src) -> add_packages dst src acc
      end sources in
      let dependencies = List.map dependencies ~f:fst |> Library.Dependency.of_list in
      [{name; opam; sources; dependencies; compatibility}]
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

(* Compatibility treatment *)
let compatibility_treatment p l =
  match CompatibilityIdents.to_list p.compatibility with
    | [] -> l
    | ["satyrographos-0.0.1"] -> begin
      let rename_packages = List.map p.sources.packages ~f:(fun (name, _) ->
        let old_package_name = name in
        let new_package_name = p.name ^ "/" ^ name in
        (old_package_name, new_package_name)
      ) in
      { Library.empty with
        compatibility = Library.Compatibility.{
          rename_packages
        }
      }
      |> Library.union l
    end
    | _ -> begin
      let unknown_symbols =
      Set.remove p.compatibility "satyrographos-0.0.1"
      |> [%sexp_of: CompatibilityIdents.t]
      |> Sexp.to_string_hum
      in
      failwithf "Unknown compatibility symbols: %s\n" unknown_symbols ()
    end

(* Read *)
let read_library p ~src_dir =
  let map_file dst_dir = List.map ~f:(fun (dst, src) -> (Filename.concat dst_dir dst, Filename.concat src_dir src)) in
  let other_files = map_file "" p.sources.files in
  let hashes =
    map_file "hash" p.sources.hashes
    |> List.fold ~init:Library.empty ~f:(fun a (dst, src) -> Library.add_hash dst src a)
  in
  let fonts = map_file (Filename.concat "fonts" p.name) p.sources.fonts in
  let packages = map_file (Filename.concat "packages" p.name) p.sources.packages in
  Library.{ empty with
   files=List.concat [other_files; fonts; packages] |> Library.LibraryFiles.of_alist_exn;
   dependencies=p.dependencies;
  }
  |> Library.union hashes
  |> compatibility_treatment p
