open Core

let version_filepath d =
  FilePath.concat d "version"

let packages_dirpath d =
  FilePath.concat d "packages"

let mark_version d version =
  let file = version_filepath d in
  let write_version ch =
    Out_channel.output_string ch (string_of_int version)
  in
  Out_channel.with_file file ~append:false ~f:write_version

let get_version d =
  let file = version_filepath d in
  let read_version ch =
    let line = In_channel.input_line ch in
    Option.value_exn line
    |> int_of_string
  in
  match FileUtil.test FileUtil.Is_file file, FileUtil.test FileUtil.Is_dir (packages_dirpath d) with
  | true, _ -> Some (In_channel.with_file file ~f:read_version)
  | false, true -> Some 0
  | false, false -> None

