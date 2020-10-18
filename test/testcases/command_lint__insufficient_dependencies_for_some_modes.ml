open Core
open Satyrographos_testlib

let satysfi_package_opam =
  "satysfi-package.opam", TestLib.opam_file_for_test
    ~name:"satysfi-package"
    ~version:"0.1"
    ()

let satyristes =
  "Satyristes", sprintf
    {|(version "0.0.2")

(library
  (name "package")
  (version "0.1")
  (sources ((package "first.satyh" "first.satyh")
            (package "second.satyg" "second.satyg")
            (package "third.satyh" "third.satyh")
           ))
  (opam "satysfi-package.opam")
  (dependencies ()))
|}

let packages = [
  "first.satyh", {|@import: second
|};
  "second.satyg", {|@import: third
|};
  "third.satyh", {|
|};
]

let opam_libs = [
]


let files =
  [ satysfi_package_opam;
    satyristes;
  ] @ packages

let () =
  TestCommand.test_lint_command ~opam_libs files
