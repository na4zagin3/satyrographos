let satyristes_template =
"Satyristes",
{|(lang "0.0.3")

(doc
  (name  "main")
  (build ((omake)))
  (dependencies
   (;; Standard library
    dist
    ;; Third-party library
    fss
    )))
|}

let omakefile_template =
  "OMakefile",
  {|# SATySFi/Satyrographos rules
%.pdf: %.saty
    satyrographos satysfi -- -o $@ $<
.SCANNER: %.pdf: %.saty :value: $(digest $&)
    satyrographos util deps-make -o $@ --mode pdf $<

.DEFAULT: main.pdf
|}

let omakeroot_template =
  "OMakeroot",
  {|open build/C
open build/OCaml
open build/LaTeX

DefineCommandVars()

.SUBDIRS: .
|}

let readme_template =
"README.md",
{|# @@library@@

A great document.

## Requirement

Needs OMake to build this project.

## How to compile?

Run `satyrographos build`.
|}

let files = [
  Template_docMake_en.main_saty_template;
  Template_docMake_en.local_satyh_template;
  satyristes_template;
  Template_docMake_en.gitignore_template;
  omakefile_template;
  omakeroot_template;
  readme_template;
]

let template =
  "[experimental]doc-omake@en", ("Document with OMakefile (en)", files)
