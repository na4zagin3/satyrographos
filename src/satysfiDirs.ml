open Batteries

let runtime_dirs () =
  if Sys.os_type = "Win32" then
    match Sys.getenv_opt "SATYSFI_RUNTIME" with
    | None    -> []
    | Some(s) -> [s]
  else
    ["/usr/local/share/satysfi"; "/usr/share/satysfi"]

let home_dir () = if Sys.os_type = "Win32"
  then Sys.getenv_opt "userprofile"
  else Sys.getenv_opt "HOME"

let user_dir () =
    Option.map (fun s -> Filename.concat s ".satysfi") (home_dir ())
