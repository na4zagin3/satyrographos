open Core


let total_command =
  Command.group ~summary:"Simple SATySFi Package Manager"
    [
      "build", CommandBuild.build_command;
      "debug", CommandDebug.debug_command;
      "new", CommandNew.new_command;
      "opam", CommandOpam.opam_command;
      "library", CommandLibrary.library_command;
      "library-opam", CommandLibrary.library_opam_command;
      "lint", CommandLint.lint_command;
      "lockdown", CommandLockdown.lockdown_command;
      "migrate", CommandMigrate.migrate_command;
      "satysfi", CommandSatysfi.satysfi_command;
      "status", CommandStatus.status_command;
      "util", CommandUtil.util_command;
      "pin", CommandPin.pin_command;
      "install", CommandInstall.install_command;
    ]

(* %%VERSION_NUM%% is expanded by "dune subst" *)
let () =
  Command.run ~version:"%%VERSION_NUM%%" total_command
