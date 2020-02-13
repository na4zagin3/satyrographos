type t = {
  registry_dir: string;
}

let read registry_dir =
  if FileUtil.(test Is_dir registry_dir)
  then Some {
    registry_dir
  }
  else None
let list reg = FileUtil.ls reg.registry_dir |> List.map FilePath.basename
let directory reg name = Filename.concat reg.registry_dir name
let mem reg name = directory reg name |> FileUtil.test FileUtil.Is_dir
