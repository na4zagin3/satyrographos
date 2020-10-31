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
  (sources ((package "test.satyh" "test.satyh")))
  (opam "satysfi-package.opam")
  (dependencies ())
  (compatibility ((satyrographos 0.0.1))))
|}

let test_satyh =
  "test.satyh", {||}

let opam_libs = Satyrographos.Library.[
    {empty with
     name = Some "package";
     files = LibraryFiles.of_alist_exn [
         "packages/package/test.satyh", `Content ""
       ]
    };
]

let files =
  [ satysfi_package_opam;
    satyristes;
    test_satyh;
  ]

let () =
  TestCommand.test_lint_command ~opam_libs files
