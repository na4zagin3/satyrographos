type package_name = string
exception RegisteredAlready of package_name

type t = {
  package_dir: string;
}

let list reg = FileUtil.ls reg.package_dir |> List.map FilePath.basename
let directory reg name = Filename.concat reg.package_dir name
let mem reg name = directory reg name |> FileUtil.test FileUtil.Is_dir
let remove reg name =
  [directory reg name] |> FileUtil.rm ~force:Force ~recurse:true
let add_dir reg name dir =
  match mem reg name, FileUtil.test FileUtil.Is_dir dir with
  | true, _ -> raise (RegisteredAlready name)
  | _, false -> failwith (dir ^ " is not a directory")
  | false, true -> FileUtil.cp ~recurse:true [dir] (directory reg name)
  (* | false, false -> FileUtil.cp ~recurse:true [dir] (directory reg name) *)

let initialize reg =
  FileUtil.mkdir ~parent:true reg.package_dir
