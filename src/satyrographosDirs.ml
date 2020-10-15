open Core

let repository_dir sg_dir = Filename.concat sg_dir "repo"
(* TODO Rename libraries with registry in the next major version. *)
let registry_dir sg_dir = Filename.concat sg_dir "libraries"
let metadata_file sg_dir = Filename.concat sg_dir "metadata"
let version_file sg_dir = FilePath.concat sg_dir "version"

let mark_scheme_version d version =
  let file = version_file d in
  let write_version ch =
    Out_channel.output_string ch (string_of_int version)
  in
  Out_channel.with_file file ~append:false ~f:write_version

let get_scheme_version d =
  let file = version_file d in
  let read_version ch =
    let line = In_channel.input_line ch in
    Option.value_exn line
    |> int_of_string
  in
  match FileUtil.test FileUtil.Is_file file, FileUtil.test FileUtil.Is_dir (registry_dir d) with
  | false, false -> None
  | false, true -> Some 0
  | true, false -> Some 0
  | true, _ -> Some (In_channel.with_file file ~f:read_version)
