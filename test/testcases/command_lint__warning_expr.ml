open Core
open Satyrographos_testlib

let satysfi_package_opam =
  "satysfi-package.opam", TestLib.opam_file_for_test
    ~name:"satysfi-package"
    ~synopsis:"" (* Warning opam-file/lint/47 *)
    ~version:"0.1"
    ()

let satyristes =
  "Satyristes", sprintf
    {|(version "0.0.2")

(library
  (name "package")
  ;; Error opam-file/version
  (version "0.1.1")
  (sources ())
  (opam "satysfi-package.opam")
  (dependencies ()))
|}

let files =
  [ satysfi_package_opam;
    satyristes;
  ]

let () =
  let warning_expr =
    Satyrographos.Glob.parse_as_tm_exn (Lexing.from_string "-*")
  in
  TestCommand.test_lint_command ~warning_expr files;
