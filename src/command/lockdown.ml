
let lockdown_file_path ~buildscript_path =
  FilePath.concat
    (FilePath.dirname buildscript_path)
    "lockdown.yaml"

let save_lockdown ~verbose ~buildscript_path =
  let buildscript = Satyrographos.BuildScript.load buildscript_path in
  let lockdown =
    Satyrographos_lockdown.Lockdown.generate_lockdown
      ~verbose
      ~buildscript
  in
  Satyrographos_lockdown.LockdownFile.save_file_exn
    (lockdown_file_path ~buildscript_path)
    lockdown

let restore_lockdown ~verbose ~buildscript_path =
  let lockdown =
    Satyrographos_lockdown.LockdownFile.load_file_exn
      (lockdown_file_path ~buildscript_path);
  in
  Satyrographos_lockdown.Lockdown.restore_lockdown ~verbose lockdown;
