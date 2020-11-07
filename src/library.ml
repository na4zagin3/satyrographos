open Core

module LibraryFiles = struct
  include Map.Make(String)

  let union f = merge ~f:(fun ~key:key -> function
    | `Left v | `Right v -> Some v
    | `Both (x, y) -> f key x y
  )
end

module Json = struct
  (*
  include Yojson.Safe
  type t = Json_derivers.Yojson.t
  let ( sexp_of_t, t_of_sexp, compare, hash ) = Json_derivers.Yojson.( sexp_of_t, t_of_sexp, compare, hash )
  *)
  let ( to_string, from_file, to_file ) = Yojson.Safe.( to_string, from_file, to_file )
  include Json_derivers.Yojson
end

module Dependency = Set.Make(String)
module StringMap = Map.Make(String)
module JsonSet = Set.Make(Json)
module Rename = struct
  type t = {
    new_name: string;
    old_name: string;
  }
  [@@deriving sexp, compare]
end
module RenameSet = Set.Make(Rename)
module Compatibility = struct
  type t = {
    rename_packages: RenameSet.t [@sexp.omit_nil];
    rename_fonts: RenameSet.t [@sexp.omit_nil];
  }
  [@@deriving sexp, compare]
  let empty = {
    rename_packages = RenameSet.empty;
    rename_fonts = RenameSet.empty;
  }
  let is_empty c =
    RenameSet.is_empty c.rename_packages
    && RenameSet.is_empty c.rename_fonts
  let union c1 c2 = {
    rename_packages = RenameSet.union c1.rename_packages c2.rename_packages;
    rename_fonts = RenameSet.union c1.rename_fonts c2.rename_fonts;
  }
  let union_list = List.fold ~init:empty ~f:union
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

let empty = {
  name = None;
  version = None;
  hashes = LibraryFiles.empty;
  files = LibraryFiles.empty;
  compatibility = Compatibility.empty;
  dependencies = Dependency.empty;
  autogen = Dependency.empty;
}


let show_file_list files =
  [%sexp_of: string list] files
  |> Sexp.to_string

let hash_map_singleton (k, x) =
  StringMap.singleton k (JsonSet.singleton x)

let to_string x =
  [%sexp_of: t] x
  |> Sexp.to_string

let hash_map_union =
  (* TODO use merge_skewed *)
  StringMap.merge ~f:(fun ~key:_ -> function
    | `Left v | `Right v -> Some v
    | `Both (x, y) -> Some(JsonSet.union x y)
  )

let validate_hash f abs_fs = function
  | (`Assoc a) ->
    List.map ~f:hash_map_singleton a
    |> List.fold_left ~f:hash_map_union ~init:StringMap.empty
    |> StringMap.filter ~f:(fun v -> JsonSet.length v > 1)
    |> StringMap.mapi ~f:(fun ~key:k ~data:v -> Printf.sprintf "Conflict values in %s:\nField: %s\nValues: %s\nOriginally from: %s\n\n"
      f
      k
      (Json.to_string (`List (JsonSet.elements v)))
      (show_file_list abs_fs)
    )
    |> StringMap.data

  | _ -> [f ^ " is not an object. Originally from " ^ show_file_list abs_fs]

let validate p =
  LibraryFiles.mapi p.hashes
    ~f:(fun ~key:f ~data:(abs_fs, h) -> validate_hash f abs_fs h)
  |> LibraryFiles.data
  |> List.concat

let normalize_hash ~outf = function
  | (`Assoc a) ->
    let map = StringMap.of_alist_reduce a ~f:(fun v1 v2 ->
      Format.fprintf outf "WARNING: Conflict values. Choosing first.\n%s\n%s\n@."
        (Json.to_string v1)
        (Json.to_string v2);
      v1
    ) in
    `Assoc (StringMap.to_alist map)
  | j ->
    Format.fprintf outf "Invalid value: %s\n@."
        (Json.to_string j);
      j

let normalize ~outf p = {
  hashes = LibraryFiles.map p.hashes ~f:(fun (paths, json) -> paths, normalize_hash ~outf json);
  files = p.files;
  compatibility = p.compatibility;
  dependencies = p.dependencies;
  autogen = p.autogen;
  name = p.name;
  version = p.version;
}

let add_file f absolute_path p =
  if FilePath.is_relative absolute_path
  then failwith ("BUG: FilePath must be absolute but got " ^ absolute_path)
  else { p with files = LibraryFiles.add_exn ~key:f ~data:(`Filename absolute_path) p.files }

let handle_hash_conflict f (f1, h1) (f2, h2) = match h1, h2 with
  | `Assoc a1, `Assoc a2 -> Some(List.append f1 f2, `Assoc (List.append a1 a2)) (* TODO: Handle conflicting cases*)
  | _, _ -> failwith ("Conflicting file " ^ f ^ "\n  " ^ show_file_list f1 ^ "\n and \n  " ^ show_file_list f2)

let add_hash_json f context json p =
  { p with
    hashes =
      LibraryFiles.union handle_hash_conflict
        p.hashes
        (LibraryFiles.singleton f ([context], json));
  }

let add_hash f abs_f p =
  try
    let json = Json.from_file abs_f in
    add_hash_json f abs_f json p
  with
  | Yojson.Json_error msg ->
    failwithf "JSON Error in file %s: %s" abs_f msg ()

let union p1 p2 =
  let handle_file_conflict f f1 f2= match f1, f2 with
    | `Content fc1, `Content fc2 -> begin
      if String.equal fc1 fc2
      then Some(`Content fc1)
      else failwith ("Conflicting file " ^ f)
    end
    | `Filename fn2, `Content fc1
    | `Content fc1, `Filename fn2 -> begin
      let fc2 = In_channel.read_all fn2 in
      if String.equal fc1 fc2
      then Some(`Content fc1)
      else failwith ("Conflicting file " ^ f)
    end
    | `Filename f1, `Filename f2 ->
      match FileUtil.cmp f1 f2 with
      | None -> Some(`Filename f1)
      | Some(-1) -> failwith ("Cannot read either of files " ^ f ^ "\n  " ^ f1 ^ "\n  " ^ f2)
      | _ -> failwith ("Conflicting file " ^ f ^ "\n  " ^ f1 ^ "\n  " ^ f2)
  in
  { hashes = LibraryFiles.union handle_hash_conflict p1.hashes p2.hashes;
    files = LibraryFiles.union handle_file_conflict p1.files p2.files;
    compatibility = Compatibility.union p1.compatibility p2.compatibility;
    dependencies = Dependency.union p1.dependencies p2.dependencies;
    autogen = Dependency.union p1.autogen p2.autogen;
    name = Core.Option.first_some p1.name p2.name;
    version = Core.Option.first_some p1.version p2.version;
  }

let%test "union: empty + empty = empty" =
  [%compare.equal: t] empty (union empty empty)

let%test "union: empty + p = empty" =
  let p = add_file "a" "/b" empty in
  [%compare.equal: t] p (union empty p)

let%test "union: p + empty = empty" =
  let p = add_file "a" "/b" empty in
  [%compare.equal: t] p (union p empty)

type metadata = {
  version: int;
  libraryName: string [@default ""];
  libraryVersion: string [@default ""];
  compatibility: Compatibility.t;
  dependencies: (string * unit (* for future extension *)) list;
  autogen: (string * unit (* for future extension *)) list [@sexp.omit_nil];
}
[@@deriving sexp, compare]

let current_version = 1

let add_metadata f (p: t) =
  (* TODO Handle failure *)
  let metadata = Sexp.load_sexp_conv_exn f [%of_sexp: metadata] in
  let ds = metadata.dependencies |> List.map ~f:fst in
  let ags = metadata.autogen |> List.map ~f:fst in
  { p with
    dependencies = Dependency.of_list ds |> Dependency.union p.dependencies;
    autogen = Dependency.of_list ags |> Dependency.union p.autogen;
    compatibility = Compatibility.union p.compatibility metadata.compatibility;
    name = if String.is_empty metadata.libraryName then None else Some metadata.libraryName;
    version = if String.is_empty metadata.libraryVersion then None else Some metadata.libraryVersion;
  }
let save_metadata f (p: t) =
  let dependencies =
    Dependency.to_list p.dependencies
    |> List.map ~f:(fun x -> x, ())
  in
  let autogen =
    Dependency.to_list p.autogen
    |> List.map ~f:(fun x -> x, ())
  in
  { version = current_version;
    dependencies;
    autogen;
    compatibility = p.compatibility;
    libraryName = Option.value ~default:"" p.name;
    libraryVersion = Option.value ~default:"" p.version;
  }
  |> [%sexp_of: metadata]
  |> Sexp.save_hum f

let metadata_filename = "metadata"

let read_dir ~outf d =
  let add acc f =
    let rel_f = FilePath.make_relative d f in
    match rel_f with
    | ".satyrographos" -> acc
    | _ when String.equal rel_f metadata_filename ->
      add_metadata f acc
    | _ when FilePath.is_subdir rel_f "hash" ->
      if FilePath.check_extension rel_f "satysfi-hash"
      then add_hash rel_f f acc
      else begin
        Format.fprintf outf "Hash file “%s” is ignored due to the wrong extension.\n" rel_f;
        acc
      end
    | _ ->
      add_file rel_f f acc
  in
  if FileUtil.test FileUtil.Is_dir d
  then FileUtil.(find ~follow:Follow Is_file d add empty)
  else failwith (d ^ " is not a library directory")

let write_dir ?(verbose=false) ?(symlink=false) ~outf d p =
  let p = normalize ~outf p in
  FileUtil.mkdir ~parent:true d;
  LibraryFiles.iteri ~f:(fun ~key:path ~data ->
    let file_dst = FilePath.concat d path in
    match data with
    | `Content data ->
      let file_dst = FilePath.concat d path in
      begin if verbose
        then Format.fprintf outf "Writing to %s@." file_dst
      end;
      FileUtil.mkdir ~parent:true (FilePath.dirname file_dst);
      Out_channel.write_all file_dst ~data
    | `Filename fullpath ->
      let action = if symlink
        then "Linking"
        else "Copying"
      in
      begin if verbose
        then Format.fprintf outf "%s %s to %s@." action fullpath file_dst
      end;
      FileUtil.mkdir ~parent:true (FilePath.dirname file_dst);
      if symlink
      then (* Breaking change in Core v0.11 and v0.12. Use Core v0.12 notation when the OCaml 4.06 support is dropped.
        Core v0.11:
          Unix.symlink ~src:fullpath ~dst:file_dst
        Core v0.12:
          Unix.symlink ~target:fullpath ~link_name:file_dst
        *)
        UnixLabels.symlink ~to_dir:false ~src:fullpath ~dst:file_dst
      else FileUtil.cp [fullpath] file_dst
  ) p.files;
  LibraryFiles.iteri ~f:(fun ~key:path ~data:(_, h) ->
    let file_dst = FilePath.concat d path in
    begin if verbose
      then Format.fprintf outf "Generating %s@." file_dst
    end;
    FileUtil.mkdir ~parent:true (FilePath.dirname file_dst);
    Json.to_file file_dst h
  ) p.hashes;
  save_metadata (FilePath.concat d metadata_filename) p


let mark_filename = ".satyrographos"
let mark_managed_dir d =
  FileUtil.mkdir ~parent:true d;
  FileUtil.touch (FilePath.concat d mark_filename)

let is_managed_dir d =
  FileUtil.test FileUtil.Is_file (FilePath.concat d mark_filename)
