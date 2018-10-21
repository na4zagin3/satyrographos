module PackageFiles = Map.Make(String)

let string_map_printer fmt v =
  [%derive.show: (string * string) list] (PackageFiles.bindings v)
  |> Format.fprintf fmt "%s"

type t = {
  hashes: unit;
  files: string PackageFiles.t [@printer fun fmt v -> string_map_printer fmt v];
}
[@@deriving show, eq]

let empty = {
  hashes = ();
  files = PackageFiles.empty;
}

let add_file f absolute_path p =
  if FilePath.is_relative absolute_path
  then failwith ("BUG: FilePath must be absolute but got " ^ absolute_path)
  else { p with files = PackageFiles.add f absolute_path p.files }

let union p1 p2 =
  let error_file_conflict f f1 f2 = match FileUtil.cmp f1 f2 with
    | None -> Some(f1)
    | Some(-1) -> failwith ("Cannot read either of files " ^ f ^ "\n  " ^ f1 ^ "\n  " ^ f2)
    | _ -> failwith ("Conflicting file " ^ f ^ "\n  " ^ f1 ^ "\n  " ^ f2)
  in
  { hashes = ();
    files = PackageFiles.union error_file_conflict p1.files p2.files;
  }

let%test "union: empty + empty = empty" =
  equal empty (union empty empty)

let%test "union: empty + p = empty" =
  let p = add_file "a" "/b" empty in
  equal p (union empty p)

let%test "union: p + empty = empty" =
  let p = add_file "a" "/b" empty in
  equal p (union p empty)

let read_dir d =
  let add acc f =
    let rel_f = FilePath.make_relative d f in
    add_file rel_f f acc
  in
  if FileUtil.test FileUtil.Is_dir d
  then FileUtil.(find ~follow:Follow Is_file d add empty)
  else failwith (d ^ " is not a package directory")

let write_dir d p =
  PackageFiles.iter (fun path fullpath ->
    let file_dst = FilePath.concat d path in
    Printf.printf "Copying %s to %s\n" fullpath file_dst;
    FileUtil.mkdir ~parent:true (FilePath.dirname file_dst);
    FileUtil.cp [fullpath] file_dst
  ) p.files


let mark_filename = ".satyrographos"
let mark_managed_dir d =
  FileUtil.mkdir ~parent:true d;
  FileUtil.touch (FilePath.concat d mark_filename)

let is_managed_dir d =
  FileUtil.test FileUtil.Is_file (FilePath.concat d mark_filename)
