open Core

let opam_file_without_name_field =
  "satysfi-package-doc.opam", sprintf
    {|opam-version: "2.0"
|}

let satyristes =
  "Satyristes", sprintf
    {|(version "0.0.2")

(library
  (name "package")
  (version "0.1")
  (sources ())
  (opam "satysfi-package.opam")
  (dependencies ()))

(libraryDoc
  (name "package-doc")
  (version "0.1")
  (build ())
  (sources ())
  (opam "satysfi-package-doc.opam")
  (dependencies ((package ()))))
|}

let files =
  [ opam_file_without_name_field;
    satyristes;
  ]

let () =
  TestCommand.test_lint_command files
