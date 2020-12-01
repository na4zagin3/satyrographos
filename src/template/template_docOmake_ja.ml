(*
   SPDX-License-Identifier: CC0-1.0
*)

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

let readme_template =
  "README.md",
  {|# @@library@@

素敵な文書

## 依存

この文書の処理にはOMakeを要する。

## 処理方法

`satyrographos build`コマンドを走らせること。
|}

let files = [
  Template_docMake_ja.main_saty_template;
  Template_docMake_ja.local_satyh_template;
  satyristes_template;
  Template_docMake_en.gitignore_template;
  Template_docOmake_en.omakefile_template;
  Template_docOmake_en.omakeroot_template;
  readme_template;
]

let template =
  "[experimental]doc-omake@ja", ("Document with OMakefile (ja)", files)
