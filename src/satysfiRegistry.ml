type t = {
  registy_dir: string;
}

let read registy_dir = {
  registy_dir
}
let list reg = FileUtil.ls reg.registy_dir |> List.map FilePath.basename
let directory reg name = Filename.concat reg.registy_dir name
let mem reg name = directory reg name |> FileUtil.test FileUtil.Is_dir
