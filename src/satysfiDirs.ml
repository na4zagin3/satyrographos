open Core

let runtime_dirs () =
  if Sys.os_type = "Win32" then
    match Sys.getenv "SATYSFI_RUNTIME" with
    | None    -> []
    | Some(s) -> [s]
  else
    ["/usr/local/share/satysfi"; "/usr/share/satysfi"]

let home_dir () = if Sys.os_type = "Win32"
  then Sys.getenv "userprofile"
  else Sys.getenv "HOME"

let user_dir () =
    Option.map ~f:(fun s -> Filename.concat s ".satysfi") (home_dir ())
