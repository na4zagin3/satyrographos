type package_name = string

type t = {
  package_dir: string;
}

let list reg = FileUtil.ls reg.package_dir |> List.map FilePath.basename
let directory reg name = Filename.concat reg.package_dir name
let mem reg name = directory reg name |> FileUtil.test FileUtil.Is_dir
