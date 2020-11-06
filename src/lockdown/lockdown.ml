let generate_lockdown ~verbose ~buildscript =
  let open Satyrographos in
  let dependent_opam_packages =
    BuildScript.get_opam_dependencies buildscript
  in
  LockdownFile.make
    ~dependencies:
      (LockdownFile.Opam
         (OpamDependencies.get_opam_dependencies ~verbose dependent_opam_packages))

let restore_lockdown ~verbose (lockdown : LockdownFile.t) =
  begin match lockdown.dependencies with
      LockdownFile.Opam opam_dependencies ->
      OpamDependencies.restore_opam_dependencies
        ~verbose
        opam_dependencies
  end
