open Core

let opam_file_with_name_field =
  "satysfi-package.opam", sprintf
    {|opam-version: "2.0"
|}

let opam_file_without_name_field =
  "satysfi-package-doc.opam", sprintf
    {|opam-version: "2.0"
|}

let files =
  [ opam_file_with_name_field;
    opam_file_without_name_field;
  ]

let () =
  TestCommand.test_lint_command files
