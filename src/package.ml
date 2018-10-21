module PackageFiles = Map.Make(String)

module Json = struct
  include Yojson.Safe
  let equal_json = (=)
end

let string_map_printer fmt v =
  [%derive.show: (string * string) list] (PackageFiles.bindings v)
  |> Format.fprintf fmt "%s"

let json_map_printer fmt v =
  (PackageFiles.bindings v)
  |> List.map (fun (f, (abs_f, json)) -> (f, `Tuple [`List (List.map (fun x -> `String x) abs_f); json]))
  |> (fun x -> `Assoc x)
  |> Json.pretty_to_string
  |> Format.fprintf fmt "%s"

type t = {
  hashes: (string list * Json.json) PackageFiles.t [@printer fun fmt v -> json_map_printer fmt v];
  files: string PackageFiles.t [@printer fun fmt v -> string_map_printer fmt v];
}
[@@deriving show, eq]

let empty = {
  hashes = PackageFiles.empty;
  files = PackageFiles.empty;
}


let show_file_list = [%derive.show: string list]

let add_file f absolute_path p =
  if FilePath.is_relative absolute_path
  then failwith ("BUG: FilePath must be absolute but got " ^ absolute_path)
  else { p with files = PackageFiles.add f absolute_path p.files }

let add_hash f abs_f p =
  let json = Json.from_file abs_f in
  { p with hashes = PackageFiles.add f ([abs_f], json) p.hashes }

let union p1 p2 =
  let handle_file_conflict f f1 f2 = match FileUtil.cmp f1 f2 with
    | None -> Some(f1)
    | Some(-1) -> failwith ("Cannot read either of files " ^ f ^ "\n  " ^ f1 ^ "\n  " ^ f2)
    | _ -> failwith ("Conflicting file " ^ f ^ "\n  " ^ f1 ^ "\n  " ^ f2)
  in
  let handle_hash_conflict f (f1, h1) (f2, h2) = match h1, h2 with
    | `Assoc a1, `Assoc a2 -> Some(List.append f1 f2, `Assoc (List.append a1 a2)) (* TODO: Handle conflicting cases*)
    | _, _ -> failwith ("Conflicting file " ^ f ^ "\n  " ^ show_file_list f1 ^ "\n and \n  " ^ show_file_list f2)
  in
  { hashes = PackageFiles.union handle_hash_conflict p1.hashes p2.hashes;
    files = PackageFiles.union handle_file_conflict p1.files p2.files;
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
    if FilePath.is_subdir rel_f "hash"
    then add_hash rel_f f acc
    else add_file rel_f f acc
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
  ) p.files;
  PackageFiles.iter (fun path (_, h) ->
    let file_dst = FilePath.concat d path in
    Printf.printf "Generating %s\n" file_dst;
    FileUtil.mkdir ~parent:true (FilePath.dirname file_dst);
    Json.to_file file_dst h
  ) p.hashes


let mark_filename = ".satyrographos"
let mark_managed_dir d =
  FileUtil.mkdir ~parent:true d;
  FileUtil.touch (FilePath.concat d mark_filename)

let is_managed_dir d =
  FileUtil.test FileUtil.Is_file (FilePath.concat d mark_filename)
