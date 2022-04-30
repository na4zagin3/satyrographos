open Core

let runtime_dirs () =
  if String.equal Sys.os_type "Win32" then
    match Sys.getenv "SATYSFI_RUNTIME" with
    | None    -> []
    | Some(s) -> [s]
  else
    ["/usr/local/share/satysfi"; "/usr/share/satysfi"]

let is_satysfi_runtime_dir dir =
  FileUtil.(test Is_dir) (Filename.concat dir "packages")

let home_dir () = if String.equal Sys.os_type "Win32"
  then Sys.getenv "userprofile"
  else Sys.getenv "HOME"

let user_dir () =
    Option.map ~f:(fun s -> Filename.concat s ".satysfi") (home_dir ())

let expand_package_root_dirs ~satysfi_version package_root_dirs =
  let suffixes =
    ["dist/packages"]
    @ if Version.read_local_packages satysfi_version
    then ["local/packages"]
    else []
  in
  List.concat_map suffixes ~f:(fun suffix ->
      List.map package_root_dirs ~f:(fun path -> FilePath.concat path suffix))

let option_to_list = function
  | Some x -> [x]
  | None -> []

let dist_library_dir ~satysfi_opam_reg ~outf:_ =

  let shares = ["/usr/local/share"; "/usr/share"] in
  let dist_dirs =
    option_to_list satysfi_opam_reg
    @ List.map shares ~f:(fun d -> Filename.concat d "satysfi")
    |> List.map ~f:(fun d -> Filename.concat d "dist")
  in
  let rec f = function
    | [] -> None
    | (d :: ds) ->
      if is_satysfi_runtime_dir d
      then Some d
      else f ds
  in
  f dist_dirs


let read_satysfi_env ~outf (env: Satyrographos.Environment.t) =
  let dist_library_dir = dist_library_dir ~satysfi_opam_reg:(Option.map env.opam_reg ~f:(fun reg -> reg.registry_dir)) ~outf in
  { env with dist_library_dir }
