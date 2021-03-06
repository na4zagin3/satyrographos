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
  (sources ((hash "mathfonts.satysfi-hash" "mathfonts.satysfi-hash")
            (hash "fonts.satysfi-hash" "fonts.satysfi-hash")))
  (opam "satysfi-package.opam")
  (dependencies ()))
|}

let fonts_satysfi_hash =
  "fonts.satysfi-hash", {|
{
  "font1": <Single:{"src-dist": "abc.ttf" }>
}
|}

let mathfonts_satysfi_hash =
  "mathfonts.satysfi-hash", {|
{
  "mathfont1": <Single:{"src-dist": "math-abc.ttf" }>
}
|}

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
    fonts_satysfi_hash;
    mathfonts_satysfi_hash;
  ]

let () =
  TestCommand.test_lint_command ~opam_libs files
