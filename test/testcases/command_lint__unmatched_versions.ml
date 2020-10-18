open Core
open Satyrographos_testlib

let opam_file_with_version_field =
  "satysfi-package.opam",
  TestLib.opam_file_for_test
    ~name:"satysfi-package"
    ~version:"0.0.1"
    ()

let opam_file_with_version_field_digit =
  "satysfi-package-end-with-digit.opam",
  TestLib.opam_file_for_test
    ~name:"satysfi-package-end-with-digit"
    ~version:"0.11"
    ()

let opam_file_with_version_field_alpha =
  "satysfi-package-end-with-alpha.opam",
  TestLib.opam_file_for_test
    ~name:"satysfi-package-end-with-alpha"
    ~version:"0ab"
    ()

let opam_file_without_version_field =
  "satysfi-package-doc.opam", TestLib.opam_file_for_test
    ~name:"satysfi-package-doc"
    ?version:None
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

(library
  (name "package-end-with-digit")
  (version "0.1")
  (sources ())
  (opam "satysfi-package-end-with-digit.opam")
  (dependencies ()))

(library
  (name "package-end-with-alpha")
  (version "0a")
  (sources ())
  (opam "satysfi-package-end-with-alpha.opam")
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
  [ opam_file_with_version_field;
    opam_file_with_version_field_digit;
    opam_file_with_version_field_alpha;
    opam_file_without_version_field;
    satyristes;
  ]

let opam_libs = Satyrographos.Library.[
    {empty with name = Some "package"};
  ]

let () =
  TestCommand.test_lint_command ~opam_libs files
