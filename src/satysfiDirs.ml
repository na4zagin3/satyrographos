open Core

let runtime_dirs () =
  if String.equal Sys.os_type "Win32" then
    match Sys.getenv "SATYSFI_RUNTIME" with
    | None    -> []
    | Some(s) -> [s]
  else
    ["/usr/local/share/satysfi"; "/usr/share/satysfi"]

let home_dir () = if String.equal Sys.os_type "Win32"
  then Sys.getenv "userprofile"
  else Sys.getenv "HOME"

let user_dir () =
    Option.map ~f:(fun s -> Filename.concat s ".satysfi") (home_dir ())

let is_runtime_dir dir =
  FileUtil.(test Is_dir) (Filename.concat dir "packages")

let opam_share_dir ~outf =
  try
    Unix.open_process_in "opam var share"
    |> In_channel.input_all
    |> String.strip
    |> begin function
      | "" -> None
      | x -> Some x
    end
  with
    Failure x ->
      Format.fprintf outf "Failed to get opam directory.\n %s@." x;
      None

let option_to_list = function
  | Some x -> [x]
  | None -> []

let satysfi_dist_dir ~outf =
  let shares = option_to_list (opam_share_dir ~outf) @ ["/usr/local/share"; "/usr/share"] in
  let dist_dirs = List.map shares ~f:(fun d -> Filename.concat d "satysfi" |> (fun d -> Filename.concat d "dist")) in
  let rec f = function
    | [] -> failwith "Can't find SATySFi lib. Please install it."
    | (d :: ds) ->
      if is_runtime_dir d
        then d
        else f ds
  in
  f dist_dirs
