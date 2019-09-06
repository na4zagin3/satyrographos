open Core


let total_command =
  Command.group ~summary:"Simple SATySFi Package Manager"
    [
      "opam", CommandOpam.opam_command;
      "library", CommandLibrary.library_command;
      "library-opam", CommandLibrary.library_opam_command;
      "status", CommandStatus.status_command;
      "pin", CommandPin.pin_command;
      "install", CommandInstall.install_command;
    ]

let () =
  Command.run ~version:"0.0.1.7" total_command
