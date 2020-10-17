open Core
open Satyrographos_testlib

let opam_file_with_name_field =
  "satysfi-package.opam",
  TestLib.opam_file_for_test
    ~name:"satysfi-package-mark-ii"
    ~version:"0.1"
    ()

let opam_file_without_name_field =
  "satysfi-package-document.opam", TestLib.opam_file_for_test
    ?name:None
    ~version:"0.1"
    ~depends:{|
  "satysfi" {>= "0.0.5" & < "0.0.6"}
  "satyrographos" {>= "0.0.2.6" & < "0.0.3"}

  "satysfi-package" {= "0.1"}
|}
    ()

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
  (opam "satysfi-package-document.opam")
  (dependencies ((package ()))))
|}

let files =
  [ opam_file_with_name_field;
    opam_file_without_name_field;
    satyristes;
  ]

let opam_libs = Satyrographos.Library.[
    {empty with name = Some "package"};
  ]

let () =
  TestCommand.test_lint_command ~opam_libs files
