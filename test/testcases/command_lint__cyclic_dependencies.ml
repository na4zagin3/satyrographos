open Core
open Satyrographos_testlib

let satysfi_package_opam =
  "satysfi-package.opam", TestLib.opam_file_for_test
    ~name:"satysfi-package"
    ~version:"0.1"
    ()

let satysfi_package_doc_opam =
  "satysfi-package-doc.opam", TestLib.opam_file_for_test
    ~name:"satysfi-package-doc"
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
  (sources ((package "test.satyh" "test.satyh")
            (package "test2.satyh" "test2.satyh")
            (package "test.satyh-md" "test.satyh-md")
            (package "test2.satyh-md" "test2.satyh-md")))
  (opam "satysfi-package.opam")
  (dependencies ()))
|}

let packages = [
  "test.satyh", {|@require: package/test2
|};
  "test2.satyh", {|@require: package/test
|};
  "test.satyh-md", {|@require: package/test2
|};
  "test2.satyh-md", {|@require: package/test
|};
]


let opam_libs = [
]

let files =
  [ satysfi_package_opam;
    satysfi_package_doc_opam;
    satyristes;
  ] @ packages

let () =
  TestCommand.test_lint_command ~opam_libs files
