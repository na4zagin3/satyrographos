# Satyrographos

[![Build Status](https://travis-ci.com/na4zagin3/satyrographos.svg?branch=master)](https://travis-ci.com/na4zagin3/satyrographos)

[日本語版 README はこちら](https://github.com/na4zagin3/satyrographos/blob/master/README-ja.md)

A package manager for [SATySFi](https://github.com/gfngfn/SATySFi).

_WARNING: Some command line interfaces are EXPERIMENTAL and subject to change and removal at any time without prior notice._

It composes files under directories `~/.opam/<ocaml-version>/share/satysfi/<package>` installed by OPAM and copies them into directory `~/.satysfi/dist`.
It also sets up environments so that SATySFi can use system fonts. See Section [Install System Fonts](#Install-System-Fonts) below.

Satyrographos simplifies installation of SATySFi.

```sh
# https://opam.ocaml.org/doc/Install.html
sh <(curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)

# You might have to disable sandboxing. See
# https://github.com/ocaml/opam-repository/issues/12050#issuecomment-393478072
opam init
eval $(opam env)
opam repository add satysfi-external https://github.com/gfngfn/satysfi-external-repo.git
opam repository add satyrographos https://github.com/na4zagin3/satyrographos-repo.git
opam update

opam depext satysfi satysfi-dist satyrographos
opam install satysfi satysfi-dist satyrographos

satyrographos install
```

To use the latest version of Satyrographos, pin the repository like this:

```
opam pin add https://github.com/na4zagin3/satyrographos.git
```

## For Document Authors
As Satyrographos uses OPAM as an underlining package manager, you need to install libraries you want into OPAM first.
Once they are installed in OPAM registry, `satyrographos install` will set up so that all the installed packages are available for SATySFi.
A SATySFi library may be available with the name prefixed with `satysfi-` in OPAM repository to distinguish from other OCaml packages.

For example, if you want to use fonts distributed as
［SATySFi-Fonts-Theano](https://github.com/na4zagin3/SATySFi-fonts-theano), run the following commands.

```sh
opam install satysfi-fonts-theano
satyrographos install
```

Now you can use the fonts in the library.

You can also set up with specified libraries with `-package <package>` option rather than all the available ones.
Be noticed that `-package` option is followed by a package names _without_ `satysfi-` prefix.

```sh
opam install satysfi-fonts-theano
satyrographos install -package fonts-theano
```

### Install System Fonts
_This feature is still experimental and its interface and/or behaviour may be changed later._

If your machine is using [Fontconfig](https://www.freedesktop.org/wiki/Software/fontconfig/), i.e., using Mac or Linux Desktop Environment, Satyrographos can set up SATySFi to utilise your existing system fonts.

Satyrographos offers the `-system-font-prefix <system-font-name-prefix>` option of gathering system fonts to enable them for use with names prefixed with `<system-font-name-prefix>` with SATySFi.

For example, the following command installs system fonts with the prefix `system:`.

```
$ satyrographos install -system-font-prefix 'system:'
```

Then you can use the system fonts, for example, Arial as `system:Arial`. (Technically, a font will have a SATySFi name which consists of the given prefix and the font's PostScript name. This behavior may be changed in the near future.)

```
@require: stdjabook

let-inline ctx \set-non-cjk-font name it =
  let ctx =
    ctx |> set-font Latin (name, 1., 0.)
        |> set-font OtherScript (name, 1., 0.)
  in
  read-inline ctx it

let-inline ctx \set-cjk-font name it =
  let ctx =
    ctx |> set-font HanIdeographic (name, 1., 0.)
        |> set-font Kana (name, 1., 0.)
  in
  read-inline ctx it
in

document (|
  title = {System Fonts};
  author = {\@na4zagin3};
  show-title = true;
  show-toc = false;
|) '<
  +p {
    ABCDabcd
    \set-non-cjk-font(`system:Tahoma-Bold`){ABCDabcd}
  }
  +p {
    あいうえお漢字
    \set-cjk-font(`system:HiraKakuStd-W8`){あいうえお漢字}
  }
>

```

## For Library Authors
### How Does It Work?
Satyrographos links all files under `~/.opam/<ocaml-version>/share/satysfi/<package>` and  `~/.satyrographos/packages/<package>` into `~/.satysfi/dist`.

Satyrographos also does duplication detection, hash file merging, show compatibility warning, &c. Basically `satyrographos install` behaves as
```sh
$ cp -r "$(opam var share)"/share/satysfi/*/* ~/.satysfi/dist
$ cp -r ~/.satyrographos/packages/*/* ~/.satysfi/dist
```

With `-system-font-prefix <system-font-name-prefix>`, Satyrograph query system fonts with `fc-list` and installs those fonts too.

### Library Names
Please follow the following formats.

|Type|Library Name|OPAM Package Name|
|----|------------|----------|
|Class library|`class-*`|`satysfi-class-*`|
|Font library|`fonts-*`|`satysfi-fonts-*`|
|Etc.|`*`|`satysfi-*`|

Examples:
- `class-stjarticle` `satysfi-class-stjarticle.opam`
- `fonts-theano` `satysfi-fonts-theano.opam`
- `zrbase` `satysfi-zrbase.opam`

### Register Libraries
You can add a new library for SATySFi as an OPAM library. (OPAM-independent managing is under development.)

Here are examples.
- SATySFi-fonts-theano: https://github.com/na4zagin3/SATySFi-fonts-theano
- SATySFi-grcnum: https://github.com/na4zagin3/SATySFi-grcnum

In this section, we are going to register a new library `great-package` like this.
```
- great-package/
  - doc/
    - great-package.saty           :: Library document
  - fonts/
    - interesting-font.ttf         :: Font file to install
  - hash/
    - fonts.satysfi-hash           :: Hash file to install
  - packages/
    - great-package.satyh          :: Package file to install
  - Satyristes                     :: Satyrograpos build file
  - satysfi-great-package.opam     :: OPAM package description of the library
  - satysfi-great-package-doc.opam :: OPAM package description of the library doc
```

Those files will be installed as the following hierarchy.

```
- SATYSFI_ROOT/dist/
  - docs/
    - great-package/
      - great-package.pdf
  - fonts/
    - great-package/
      - interesting-font.ttf
  - hash/
    - fonts.satysfi-hash
  - packages/
    - great-package/
      - great-package.satyh
```

#### Satyristes: Build file
Create Satyristes file with the following content.

```lisp
;; For Satyrographos 0.0.2 series
(version 0.0.2)

;; Library declaration
(library
  ;; Library name
  (name "great-package")
  ;; Library version
  (version "1.0")
  ;; Files
  (sources
    ((fontDir "fonts")
     (hash "fonts.satysfi-hash" "hash/fonts.satysfi-hash")
     (packageDir "packages")))
  ;; OPAM package file
  (opam "satysfi-great-package.opam")
  ;; Dependency
  (dependencies ((fonts-theano ()))))

;; Library doc declaration
(libraryDoc
  ;; Library doc name
  (name "great-package-doc")
  ;; Library version
  (version "1.0")
  ;; Working directory to build docs
  (workingDirectory "doc")
  ;; Build commands
  (build
    ;; Run SATySFi
    ((satysfi "great-package.saty" "-o" "great-package.pdf")))
  ;; Files
  (sources
    ((doc "great-package.pdf" "doc/great-package.pdf")))
  ;; OPAM package file
  (opam "satysfi-great-package-doc.opam")
  ;; Dependency
  (dependencies ((great-package ()))))
```


#### OPAM Package Files
You need OPAM package files for now.

```opam
# satysfi-great-library.opam
opam-version: "2.0"
name: "satysfi-great-library"
version: "1.0"
synopsis: "A Great SATySFi Package"
description: """
Brilliant description comes here.
"""
maintainer: "Your name <email@example.com>"
authors: "Your name <email@example.com>"
license: "LGPL-3.0-or-later" # Choose what you want
homepage: "<product home page>"
bug-reports: "<product issue tracker>"
dev-repo: "<repo url>"
depends: [
  "satysfi" {>= "0.0.4" & < "0.0.5"}
  "satyrographos" {>= "0.0.2" & < "0.0.3"}

  # If your library depends on other libraries, please write down here
  "satysfi-fonts-theano" {>= "2.0+satysfi0.0.3+satyrograhos0.0.2"}
]
build: [ ]
install: [
  ["satyrographos" "opam" "install"
   "-name" "great-package"
   "-prefix" "%{prefix}%"
   "-script" "%{build}%/Satyristes"]
]
```

```opam
# satysfi-great-library-doc.opam
opam-version: "2.0"
name: "satysfi-great-library-doc"
version: "1.0"
synopsis: "Document of A Great SATySFi Package"
description: """
Brilliant description comes here.
"""
maintainer: "Your name <email@example.com>"
authors: "Your name <email@example.com>"
license: "LGPL-3.0-or-later" # Choose what you want
homepage: "<product home page>"
bug-reports: "<product issue tracker>"
dev-repo: "<repo url>"
depends: [
  "satysfi" {>= "0.0.4" & < "0.0.5"}
  "satyrographos" {>= "0.0.2" & < "0.0.3"}
  "satysfi-dist"

  # You may want to include the corresponding library
  "satysfi-great-library" {= "%{version}%"}
]
build: [
  ["satyrographos" "opam" "build"
   "-name" "great-package-doc"
   "-prefix" "%{prefix}%"
   "-script" "%{build}%/Satyristes"]
]
install: [
  ["satyrographos" "opam" "install"
   "-name" "great-package-doc"
   "-prefix" "%{prefix}%"
   "-script" "%{build}%/Satyristes"]
]
```

#### Development / Testing

I assume your document files contain many use cases.
You can install the package and build the document with the following command.

```sh
$ opam add  --verbose --yes "file://$PWD"

OR

$ opam add -vy "file://$PWD"
```

There’s ongoing ticket [#4](https://github.com/na4zagin3/satyrographos/issues/4) to run
test cases without OPAM installation. Stay tuned!

#### Register Satyrograpohs Repo
`opam-publish` must work.
Follow https://opam.ocaml.org/doc/Packaging.html except you need to specify `--repo` option.

```
# Tag you repository
git tag -a <tag>
# Push the tag
git push origin <tag>

opam publish --repo=na4zagin3/satyrographos-repo
```

## Satyristes file syntax

Satyristes file is a sequence of S-Expressions. A Satyristes can contain the following descriptions.

- `(version "0.0.2")` :: Shows the file is for Satyrographos 0.0.2 series
- `(library ...)` :: Definition of a library module
- `(libraryDoc ...)` :: Definition of a library doc module

### `(library ...)` module

- `(name "<library-name>")` :: Library name.
- `(version "<package-version>")` :: Library version.
- `(sources (<source-declaration> ...))` :: Sources.
  - `(font "<dst>" "<src>")` :: Copies `<src>` into `dist/fonts/<library-name>/<dst>`.
  - `(fontDir "<src>")` :: Recursively copies files under `<src>` into `dist/fonts/<library-name>/`.
  - `(hash "<dst>" "<src>")` :: Copies `<src>` into `dist/hash/<dst>`.
  - `(package "<dst>" "<src>")` :: Copies `<src>` into `dist/packages/<library-name>/<dst>`.
  - `(packageDir "<src>")` :: Recursively copies files under `<src>` into `dist/packages/<library-name>`.
  - `(file "<dst>" "<src>")` :: Copies `<src>` into `dist/<dst>`.
- `(opam "<opam-package-file>")` :: OPAM package file.
- `(dependencies (<dependency> ...))` :: Dependencies.
  - `(<dependent-library-name> ())` :: Dependency on library `<dependent-library-name>`. `()` is for future extension.
- `(compatibility (<compatibility-item>))` :: Compatibility warning.
  - `(satyrographos "0.0.1")` :: Warn directory schema change since Satyrographos 0.0.1
  - `(renamePackage "<new-name>" "<old-name>")` :: Warn package renaming
  - `(renameFont "<new-name>" "<old-name>")` :: Warn font renaming

### `(libraryDoc ...)` module

- `(name "<library-name>")` :: Library name
- `(version "<package-version>")` :: Library version
- `(workingDirectory "<working-dir>")` :: Working directory to build documents
- `(build (<build-command> ...))` :: Build commands for documents
  - `(satysfi <args> ...)` :: Run SATySFi
  - `(make <args> ...)` :: Run make with setting a runtime directory to SATYSFI_RUNTIME
- `(sources (<source-declaration> ...))` :: Sources
  - `(doc "<dst>" "<src>")` :: Copies `<src>` into `dist/docs/<library-name>/<dst>`
- `(opam "<opam-package-file>")` :: OPAM package file
- `(dependencies (<dependency> ...))` :: Dependencies
  - `(<library-name> ())` :: Dependency on library `<library-name>`. `()` is for future extension.
- `(compatibility (<compatibility-item>))` :: Compatibility warning

## Supported Versions

|Satyrographos|SATySFi|
|-------|-------------|
|v0.0.2 series|v0.0.4 series and older (Library build requires  satysfi.0.0.3+dev2019.02.27 or newer)|
|v0.0.1 series|v0.0.3 series and older|
