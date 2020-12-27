Create a new library with --license option
  $ satyrographos new --license MIT lib test-lib
  Name: test-lib
  License: MIT
  Created a new library/document.

Dump generated files
  $ mkdir empty-dir
  $ diff -Nr empty-dir test-lib
  diff -Nr empty-dir/.gitignore test-lib/.gitignore
  0a1
  > *.satysfi-aux
  diff -Nr empty-dir/README.md test-lib/README.md
  0a1,3
  > # satysfi-test-lib
  > 
  > A great library_opam_template
  diff -Nr empty-dir/Satyristes test-lib/Satyristes
  0a1,43
  > ;; For Satyrographos 0.0.2 series
  > (version 0.0.2)
  > 
  > ;; Library declaration
  > (library
  >   ;; Library name
  >   (name "test-lib")
  >   ;; Library version
  >   (version "1.0.0")
  >   ;; Files
  >   (sources
  >     ((packageDir "src")))
  >   ;; OPAM package file
  >   (opam "satysfi-test-lib.opam")
  >   ;; Dependency
  >   (dependencies
  >     ((dist ()) ; Standard library
  >      (base ()) ; Base library
  >     )))
  > 
  > ;; Library doc declaration
  > (libraryDoc
  >   ;; Library doc name
  >   (name "test-lib-doc")
  >   ;; Library version
  >   (version "1.0.0")
  >   ;; Working directory to build docs
  >   (workingDirectory "doc")
  >   ;; Build commands
  >   (build
  >     ;; Run SATySFi
  >     ((satysfi "manual.saty" "-o" "manual.pdf")))
  >   ;; Files
  >   (sources
  >     ((doc "manual.pdf" "doc/manual.pdf")))
  >   ;; OPAM package file
  >   (opam "satysfi-test-lib-doc.opam")
  >   ;; Dependency
  >   (dependencies
  >     ((test-lib ()) ; the main library
  >      (dist ()) ; Standard library
  >      (base ()) ; Base library
  >     )))
  diff -Nr empty-dir/doc/manual.saty test-lib/doc/manual.saty
  0a1,33
  > @require: stdjareport
  > @require: itemize
  > @require: annot
  > 
  > @require: base/typeset/base
  > @require: base/float
  > 
  > @require: test-lib/test-lib
  > 
  > % Document-local function definition
  > let-inline \show-float f =
  >   f
  >   |> Float.to-string
  >   |> embed-string
  > in
  > 
  > document (|
  >   title = {test-lib Manual};
  >   author = {Your Name};
  > |) '<
  >   +p {
  >     See `https://qiita.com/na4zagin3/items/b392f5d522f9bcc0493b` for the instruction in Japanese.
  >   }
  >   +chapter{Examples} <
  >     +p {
  >       ${\pi = \mathrm-token!(Float.to-string TestLib.pi)}.
  >     }
  >     +p {
  >       Geometric mean of 1, 3, and 5 is
  >       \show-float(TestLib.geo-mean [1.; 3.; 5.]);
  >     }
  >   >
  > >
  diff -Nr empty-dir/satysfi-test-lib-doc.opam test-lib/satysfi-test-lib-doc.opam
  0a1,36
  > opam-version: "2.0"
  > name: "satysfi-test-lib-doc"
  > version: "1.0.0"
  > synopsis: "Document of A Great SATySFi Package"
  > description: """
  > Brilliant description comes here.
  > """
  > maintainer: "Your name <email@example.com>"
  > authors: "Your name <email@example.com>"
  > license: "MIT" # Choose what you want
  > homepage: "https://github.com/<github-username>/satysfi-test-lib"
  > dev-repo: "git+https://github.com/<github-username>/satysfi-test-lib.git"
  > bug-reports: "https://github.com/<github-username>/satysfi-test-lib/issues"
  > depends: [
  >   "satysfi" { >= "0.0.5" & < "0.0.6" }
  >   "satyrographos" { >= "0.0.2.6" & < "0.0.3" }
  > 
  >   # You may want to include the corresponding library
  >   "satysfi-test-lib" {= "%{version}%"}
  > 
  >   # Other libraries
  >   "satysfi-dist"
  >   "satysfi-base"
  > ]
  > build: [
  >   ["satyrographos" "opam" "build"
  >    "--name" "test-lib-doc"
  >    "--prefix" "%{prefix}%"
  >    "--script" "%{build}%/Satyristes"]
  > ]
  > install: [
  >   ["satyrographos" "opam" "install"
  >    "--name" "test-lib-doc"
  >    "--prefix" "%{prefix}%"
  >    "--script" "%{build}%/Satyristes"]
  > ]
  diff -Nr empty-dir/satysfi-test-lib.opam test-lib/satysfi-test-lib.opam
  0a1,33
  > opam-version: "2.0"
  > name: "satysfi-test-lib"
  > version: "1.0.0"
  > synopsis: "A Great SATySFi Package"
  > description: """
  > Brilliant description comes here.
  > """
  > maintainer: "Your name <email@example.com>"
  > authors: "Your name <email@example.com>"
  > license: "MIT"
  > homepage: "https://github.com/<github-username>/satysfi-test-lib"
  > dev-repo: "git+https://github.com/<github-username>/satysfi-test-lib.git"
  > bug-reports: "https://github.com/<github-username>/satysfi-test-lib/issues"
  > depends: [
  >   "satysfi" { >= "0.0.5" & < "0.0.6" }
  >   "satyrographos" { >= "0.0.2.6" & < "0.0.3" }
  > 
  >   # If your library depends on other libraries, please write down here
  >   "satysfi-dist"
  >   "satysfi-base"
  > ]
  > build: [
  >   ["satyrographos" "opam" "build"
  >    "--name" "test-lib"
  >    "--prefix" "%{prefix}%"
  >    "--script" "%{build}%/Satyristes"]
  > ]
  > install: [
  >   ["satyrographos" "opam" "install"
  >    "--name" "test-lib"
  >    "--prefix" "%{prefix}%"
  >    "--script" "%{build}%/Satyristes"]
  > ]
  diff -Nr empty-dir/src/test-lib.satyh test-lib/src/test-lib.satyh
  0a1,35
  > % .satyh files are loaded by the PDF backend.
  > % .satyh-markdown and .saty-html files are loaded by the text backend for markdoown and html outputs, respectively.
  > % A .satyg file is loaded when the corresponding .satyh or .satyh-* files are not loaded.
  > % See https://qiita.com/puripuri2100/items/ca0b054d38480f1bda61 for more details about the load order.
  > 
  > % load standard list package
  > @require: list
  > 
  > % load float package from base library
  > @require: base/float
  > 
  > module TestLib : sig
  >   % Type declaration of module TestLib
  > 
  >   val pi : float
  > 
  >   val geo-mean : float list -> float
  > 
  > end = struct
  >   % Actual definitions
  > 
  >   let pi = 3.1415926535897932384626433832795
  > 
  >   % function definition that is not exposed
  >   let sum xs =
  >     xs
  >     |> List.fold-left (+.) 0.
  > 
  >   let geo-mean xs =
  >     xs
  >     |> List.map Float.log
  >     |> sum
  >     |> Float.exp
  > 
  > end
  [1]

Interactively create a new library
  $ mv test-lib test-lib-non-interactive
  $ printf "0\n" | satyrographos new lib test-lib
  Name: test-lib
  Choose licenses:
  0) MIT
  1) LGPL-3.0-or-later
  > License: MIT
  Created a new library/document.
  $ mv test-lib test-lib-interactive

Compare them
  $ diff -Nr test-lib-non-interactive test-lib-interactive

Ensure there are no warnings
  $ cd test-lib-interactive
  $ satyrographos lint -W '-lib/dep/exception-during-setup' --satysfi-version 0.0.5
  0 problem(s) found.
