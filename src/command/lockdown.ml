
let lockdown_file_path ~buildscript_path =
  FilePath.concat
    (FilePath.dirname buildscript_path)
    "lockdown.yaml"

let load_lockdown_file ~buildscript_path =
  let path = lockdown_file_path ~buildscript_path in
  if FileUtil.(test Is_file path)
  then Some (Satyrographos_lockdown.LockdownFile.load_file_exn path)
  else None

let save_lockdown ~verbose ~env ~buildscript_path =
  let buildscript = Satyrographos.BuildScript.load buildscript_path in
  let lockdown =
    Satyrographos_lockdown.Lockdown.generate_lockdown
      ~verbose
      ~env
      ~buildscript
  in
  Satyrographos_lockdown.LockdownFile.save_file_exn
    (lockdown_file_path ~buildscript_path)
    lockdown

let restore_lockdown_result ~verbose ~buildscript_path =
  Satyrographos_lockdown.LockdownFile.load_file_result
    (lockdown_file_path ~buildscript_path)
  |> Result.map (Satyrographos_lockdown.Lockdown.restore_lockdown ~verbose)

let restore_lockdown ~verbose ~buildscript_path =
  restore_lockdown_result ~verbose ~buildscript_path
  |> Result.get_ok
