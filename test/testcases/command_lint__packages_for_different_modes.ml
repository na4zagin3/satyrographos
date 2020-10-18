open Core
open Satyrographos_testlib

let satysfi_package_opam =
  "satysfi-package.opam", TestLib.opam_file_for_test
    ~name:"satysfi-package"
    ~version:"0.1"
    ~depends:{|
  "satysfi" {>= "0.0.5" & < "0.0.6"}
  "satyrographos" {>= "0.0.2.6" & < "0.0.3"}

  "satysfi-lib1" {= "0.1"}
|}
    ()

let satyristes =
  "Satyristes", sprintf
    {|(version "0.0.2")

(library
  (name "package")
  (version "0.1")
  (sources ((package "test.satyh" "test.satyh")
            (package "test2.satyg" "test2.satyg")
           ))
  (opam "satysfi-package.opam")
  (dependencies ((lib1 ()))))
|}

let packages = [
  "test.satyh", {|@require: lib1/math
|};
  "test2.satyg", {|@require: lib1/list
|};
]

let opam_libs = Satyrographos.Library.[
    {empty with
     name = Some "lib1";
     version = Some "0.1";
     files = LibraryFiles.of_alist_exn [
         "packages/lib1/list.satyg",
         `Content "";
         "packages/lib1/math.satyh",
         `Content "";
       ]
    };
  ]


let files =
  [ satysfi_package_opam;
    satyristes;
  ] @ packages

let () =
  TestCommand.test_lint_command ~opam_libs files
