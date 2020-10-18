let name = "lib"

let lib_satyh_template =
"src/@@library@@.satyh",
{|% .satyh files are loaded by the PDF backend.
% .satyh-markdown and .saty-html files are loaded by the text backend for markdoown and html outputs, respectively.
% A .satyg file is loaded when the corresponding .satyh or .satyh-* files are not loaded.
% See https://qiita.com/puripuri2100/items/ca0b054d38480f1bda61 for more details about the load order.

% load standard list package
@require: list

% load float package from base library
@require: base/float

module @@library:camel@@ : sig
  % Type declaration of module @@library:camel@@

  val pi : float

  val geo-mean : float list -> float

end = struct
  % Actual definitions

  let pi = 3.1415926535897932384626433832795

  % function definition that is not exposed
  let sum xs =
    xs
    |> List.fold-left (+.) 0.

  let geo-mean xs =
    xs
    |> List.map Float.log
    |> sum
    |> Float.exp

end
|}

let manual_template =
"doc/manual.saty",
{|@require: stdjareport
@require: itemize
@require: annot

@require: base/typeset/base
@require: base/float

@require: @@library@@/@@library@@

% Document-local function definition
let-inline \show-float f =
  f
  |> Float.to-string
  |> embed-string
in

document (|
  title = {@@library@@ Manual};
  author = {Your Name};
|) '<
  +p {
    See `https://qiita.com/na4zagin3/items/b392f5d522f9bcc0493b` for the instruction in Japanese.
  }
  +chapter{Examples} <
    +p {
      ${\pi = \mathrm-token!(Float.to-string @@library:camel@@.pi)}.
    }
    +p {
      Geometric mean of 1, 3, and 5 is
      \show-float(@@library:camel@@.geo-mean [1.; 3.; 5.]);
    }
  >
>
|}

let satyristes_template =
"Satyristes",
{|;; For Satyrographos 0.0.2 series
(version 0.0.2)

;; Library declaration
(library
  ;; Library name
  (name "@@library@@")
  ;; Library version
  (version "1.0.0")
  ;; Files
  (sources
    ((packageDir "src")))
  ;; OPAM package file
  (opam "satysfi-@@library@@.opam")
  ;; Dependency
  (dependencies
    ((dist ()) ; Standard library
     (base ()) ; Base library
    )))

;; Library doc declaration
(libraryDoc
  ;; Library doc name
  (name "@@library@@-doc")
  ;; Library version
  (version "1.0.0")
  ;; Working directory to build docs
  (workingDirectory "doc")
  ;; Build commands
  (build
    ;; Run SATySFi
    ((satysfi "manual.saty" "-o" "manual.pdf")))
  ;; Files
  (sources
    ((doc "manual.pdf" "doc/manual.pdf")))
  ;; OPAM package file
  (opam "satysfi-@@library@@-doc.opam")
  ;; Dependency
  (dependencies
    ((@@library@@ ()) ; the main library
     (dist ()) ; Standard library
     (base ()) ; Base library
    )))
|}

let library_opam_template =
"satysfi-@@library@@.opam",
{|opam-version: "2.0"
name: "satysfi-@@library@@"
version: "1.0.0"
synopsis: "A Great SATySFi Package"
description: """
Brilliant description comes here.
"""
maintainer: "Your name <email@example.com>"
authors: "Your name <email@example.com>"
license: "@@license@@"
homepage: "https://github.com/<github-username>/satysfi-@@library@@"
dev-repo: "git+https://github.com/<github-username>/satysfi-@@library@@.git"
bug-reports: "https://github.com/<github-username>/satysfi-@@library@@/issues"
depends: [
  "satysfi" { @@satysfi_version@@ }
  "satyrographos" { @@satyrographos_version@@ }

  # If your library depends on other libraries, please write down here
  "satysfi-dist"
  "satysfi-base"
]
build: [ ]
install: [
  ["satyrographos" "opam" "install"
   "--name" "@@library@@"
   "--prefix" "%{prefix}%"
   "--script" "%{build}%/Satyristes"]
]
|}

let library_doc_opam_template =
"satysfi-@@library@@-doc.opam",
{|opam-version: "2.0"
name: "satysfi-@@library@@-doc"
version: "1.0.0"
synopsis: "Document of A Great SATySFi Package"
description: """
Brilliant description comes here.
"""
maintainer: "Your name <email@example.com>"
authors: "Your name <email@example.com>"
license: "@@license@@" # Choose what you want
homepage: "https://github.com/<github-username>/satysfi-@@library@@"
dev-repo: "git+https://github.com/<github-username>/satysfi-@@library@@.git"
bug-reports: "https://github.com/<github-username>/satysfi-@@library@@/issues"
depends: [
  "satysfi" { @@satysfi_version@@ }
  "satyrographos" { @@satyrographos_version@@ }
  "satysfi-dist"

  # You may want to include the corresponding library
  "satysfi-@@library@@" {= "%{version}%"}
  "satysfi-dist"
  "satysfi-base"
]
build: [
  ["satyrographos" "opam" "build"
   "--name" "@@library@@-doc"
   "--prefix" "%{prefix}%"
   "--script" "%{build}%/Satyristes"]
]
install: [
  ["satyrographos" "opam" "install"
   "--name" "@@library@@-doc"
   "--prefix" "%{prefix}%"
   "--script" "%{build}%/Satyristes"]
]
|}

let gitignore_template =
".gitignore",
{|*.satysfi-aux
|}

let readme_template =
"README.md",
{|# satysfi-@@library@@

A great library_opam_template
|}

let files = [
    lib_satyh_template;
    manual_template;
    satyristes_template;
    library_opam_template;
    library_doc_opam_template;
    gitignore_template;
    readme_template;
  ]
