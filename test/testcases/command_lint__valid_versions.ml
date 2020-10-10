open Core
open Satyrographos_testlib

let opam_file_alpha_digit =
  "satysfi-package-alpha-digit.opam",
  TestLib.opam_file_for_test
    ~name:"satysfi-package-alpha-digit"
    ~version:"0a1"
    ()

let opam_file_alpha_symb =
  "satysfi-package-alpha-symb.opam",
  TestLib.opam_file_for_test
    ~name:"satysfi-package-alpha-symb"
    ~version:"0a+1"
    ()

let opam_file_digit_alpha =
  "satysfi-package-digit-alpha.opam",
  TestLib.opam_file_for_test
    ~name:"satysfi-package-digit-alpha"
    ~version:"0.1a"
    ()

let opam_file_digit_symb =
  "satysfi-package-digit-symb.opam",
  TestLib.opam_file_for_test
    ~name:"satysfi-package-digit-symb"
    ~version:"0.1+1"
    ()

let opam_file_with_version_field_alpha =
  "satysfi-package-end-with-alpha.opam",
  TestLib.opam_file_for_test
    ~name:"satysfi-package-end-with-alpha"
    ~version:"0a0"
    ()

let satyristes =
  "Satyristes", sprintf
    {|(version "0.0.2")

(library
  (name "package-alpha-digit")
  (version "0a")
  (sources ())
  (opam "satysfi-package-alpha-digit.opam")
  (dependencies ()))

(library
  (name "package-alpha-symb")
  (version "0a")
  (sources ())
  (opam "satysfi-package-alpha-symb.opam")
  (dependencies ()))

(library
  (name "package-digit-alpha")
  (version "0.1")
  (sources ())
  (opam "satysfi-package-digit-alpha.opam")
  (dependencies ()))

(library
  (name "package-digit-symb")
  (version "0.1")
  (sources ())
  (opam "satysfi-package-digit-symb.opam")
  (dependencies ()))
|}

let files =
  [ opam_file_alpha_digit;
    opam_file_alpha_symb;
    opam_file_digit_alpha;
    opam_file_digit_symb;
    satyristes;
  ]

let () =
  TestCommand.test_lint_command files
