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
  (sources ((packageDir "src")))
  (opam "satysfi-package.opam")
  (dependencies ()))
|}

let test_satyh =
  "src/dir/test.satyh", {|
@import: ../lib
|}

let lib_satyh =
  "src/lib.satyh", ""

let files =
  [ satysfi_package_opam;
    satyristes;
    test_satyh;
    lib_satyh;
  ]

let opam_libs = Satyrographos.Library.[
    {empty with name = Some "package"};
  ]

let () =
  let f cwd =
    ".", Some (FilePath.concat cwd "Satyristes")
  in
  TestCommand.test_lint_command ~f ~opam_libs files
