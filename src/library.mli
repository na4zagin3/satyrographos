module LibraryFiles : sig
  include Core.Map.S with type Key.t = String.t

  val union : (string -> 'a -> 'a -> 'a option) -> 'a t -> 'a t -> 'a t
end

module Json : sig
  include module type of Yojson.Safe
  type t = [%import: Yojson.Safe.t] [@@deriving sexp, compare, hash]
end

module Dependency : sig
  include Core.Set.S with type Elt.t = String.t
end

module StringMap : sig
  include Core.Map.S with type Key.t = String.t
end

module JsonSet : sig
  include Core.Set.S with type Elt.t = Json.t
end

module Rename : sig
  type t = {
    new_name: string;
    old_name: string;
  }
  [@@deriving sexp, compare]
end

module RenameSet : sig
  include Core.Set.S with type Elt.t = Rename.t
end

module Compatibility : sig
  type t = {
    rename_packages: RenameSet.t [@sexp.omit_nil];
    rename_fonts: RenameSet.t [@sexp.omit_nil];
  }
  [@@deriving sexp, compare]
  val empty : t
  val is_empty : t -> bool
  val union : t -> t -> t
  val union_list : t list -> t
end

type file =
  [ `Filename of string
  | `Content of string
  ]
[@@deriving sexp, compare]

type t = {
  (* TODO (gh-50) make name and version into non-optional.
     These fields need to be split out. *)
  name: string option;
  version: string option;

  hashes: (string list * Json.t) LibraryFiles.t [@sexp.omit_nil];
  files: file LibraryFiles.t [@sexp.omit_nil];
  compatibility: Compatibility.t [@sexp.omit_nil];
  dependencies: Dependency.t [@sexp.omit_nil];
  autogen: Dependency.t [@sexp.omit_nil];
}
[@@deriving sexp, compare]

(** Empty library *)
val empty : t

(** Library to string *)
val to_string : t -> string

(** [validate l] validates library [l] and return a list of errors *)
val validate : t -> string list

(** [normalize l] normalizes library [l] *)
val normalize : outf:Format.formatter -> t -> t

(** [add_file f absolute_path l] adds file [f] whose content is at [absolute_path] to library [l] *)
val add_file : string -> FilePath.filename -> t -> t

(** [add_hash f absolute_path l] adds hash file [f] whose content is at [absolute_path] to library [l] *)
val add_hash : string -> FilePath.filename -> t -> t

(** [add_hash f context json l] adds hash file [f] whose content is [json] to library [l] *)
val add_hash_json : string -> string -> Json.t -> t -> t

(** [union l1 l2] returns union of [l1] and [l2]. File or hash conflict raises an error. *)
val union : t -> t -> t

type metadata = {
  version: int;
  libraryName: string [@default ""];
  libraryVersion: string [@default ""];
  compatibility: Compatibility.t;
  dependencies: (string * unit (* for future extension *)) list;
  autogen: (string * unit (* for future extension *)) list [@sexp.omit_nil];
}
[@@deriving sexp, compare]

val current_version : int

(** [read_dir_result ~outf dir] read a library at [dir] *)
val read_dir_result : outf:Format.formatter -> FilePath.filename -> (t, string) Core.Result.t

(** [read_dir ~outf dir] read a library at [dir] *)
val read_dir : outf:Format.formatter -> FilePath.filename -> t

(** [write_dir ?verbose ?symlink ~outf dir l] write library [l] at [dir],
    copying files if [symlink] is [false] (default) or symbolic-linking them otherwise. *)
val write_dir :
  ?verbose:bool ->
  ?symlink:bool -> outf:Format.formatter -> string -> t -> unit

(** [mark_managed_dir dir] marks [dir] as a Satyrographos-managed dir.
    This actually creates a file named “.satyrographos” at [dir].
*)
val mark_managed_dir : FilePath.filename -> unit

(** [is_managed_dir dir] checks if [dir] is marked as a Satyrographos-managed dir.
*)
val is_managed_dir : FilePath.filename -> bool
