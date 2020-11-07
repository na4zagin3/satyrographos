# Satyrographos サテュログラポ̣ス

[![Build Status](https://travis-ci.com/na4zagin3/satyrographos.svg?branch=master)](https://travis-ci.com/na4zagin3/satyrographos)

<img src="./doc/logo.svg" width="100"/>

[SATySFi](https://github.com/gfngfn/SATySFi)用パッケージマネージャー

パッケージ一覧はこちら→[satyrographos-packages](https://satyrographos-packages.netlify.app/) (@matsud224さん作)

**警告 一部のコマンドラインインターフェースは実験的なものであり、今後、予告無く変更・削除することがあります。悪しからず**

Satyrographos は、`~/.opam/<ocaml-version>/share/satysfi/<package>` 以下のファイルを、`~/.satysfi/dist` にコピーするものです。
この時、各パッケージのフォントハッシュファイルは適切に統合されます。
また、システムフォントを SATySFi で使用可能にすることもできます（[システムフォントのインストール](#%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E3%83%95%E3%82%A9%E3%83%B3%E3%83%88%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB) を見よ）。

Satyrographos は SATySFi のインストールを簡略化します。
詳しくは [SATySFi インストールバトル手引き 2019年1月版](https://qiita.com/na4zagin3/items/a6e025c17ef991a4c923) をご覧下さい。

## 文書作成者向け手引
Satyrographライブラリは現在OPAMによって配布されており、従って、まずOPAMで当該ライブラリをインストールした後に`satyrographos install`を実行することでSATySFiから利用可能になります。
OPAMにより管理されているSatyrographosライブラリは、
`satysfi-`で始まる名前でインストール可能になっています。これは、
OCaml用のライブラリ等と区別する為です。

例として、[SATySFi-Fonts-Theano](https://github.com/na4zagin3/SATySFi-fonts-theano)が利用したい場合は、

```sh
opam install satysfi-fonts-theano
satyrographos install
```

とすると、SATySFi-Fonts-Theano提供のフォント`fonts-theano:TheanoDidot`等が利用可能になります。

`satyrographos install`は既定で全てのライブラリを準備しますが、一部のみにすることも可能です。
以下のように、`--package <package>`（または `-l <package>`）オプションが指定されると、
指定されたライブラリのみが準備されます。
`--package`オプションはライブラリ名を取るのですが、ここには`satysfi-`がついていないことに注意してください。

```sh
opam install satysfi-fonts-theano
satyrographos install --package fonts-theano
```

### システムフォントのインストール
**この機能は、将来、使用方法や振舞いが変更される虞があります**

もし、OS に [Fontconfig](https://www.freedesktop.org/wiki/Software/fontconfig/) が存在する場合、例えば、Mac や Linux を使っている場合には、
SATySFi でシステムフォントを使えるように設定することができます。

`satyrographos install` に `--system-font-prefix <フォント名接頭辞>` オプションが追加されると、Satyrographos はシステムフォントの情報を収集し、SATySFi 側からは元々のフォント名に `<フォント名接頭辞>` が付いた名前で使えるように設定します。

例えば、次のコマンドにより、システムフォントが `system:` を冠した名前で使えるようになります。

```
$ satyrographos install --system-font-prefix 'system:'
```

例えば、Arial は `system:Arial` という名前になります。（技術的には、フォントの PostScript 名に、所与の接頭辞が付いた名前で使用可能になります。この仕様は将来変更される可能性があります。）

システムフォントを使う例を以下に示します。

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

## ライブラリ作者向け
### 新規作成
`new` サブコマンドを使うとテンプレートから新規ライブラリを作ることができます。

```sh
$ satyrographos new lib your-new-library
Name: your-new-library
Choose licenses:
0) MIT
1) LGPL-3.0-or-later
> 0
License: MIT
Created a new library/document.
```

Satyrographos は `lib` 以外のテンプレートも提供しています。テンプレートの一覧を得るには `--help` を追加してください。

```sh
$ satyrographos new --help

...

Available templates:
  doc-make@en : Document with Makefile (en)
  doc-make@ja : Document with Makefile (ja)
  doc-omake@en : Document with OMakefile (en)
  doc-omake@ja : Document with OMakefile (ja)
  lib : Package library

...
```

### 名前
ライブラリ名は以下の形式に従って下さい。

|種類|ライブラリ名|OPAMパッケージ名|
|----|------------|----------|
|クラスライブラリ|`class-*`|`satysfi-class-*`|
|フォントライブラリ|`fonts-*`|`satysfi-fonts-*`|
|他|`*`|`satysfi-*`|

例
- `class-stjarticle` `satysfi-class-stjarticle.opam`
- `fonts-theano` `satysfi-fonts-theano.opam`
- `zrbase` `satysfi-zrbase.opam`

### ライブラリの登録方法
ライブラリは OPAM ライブラリとしてインストールする方法と、Satyrographos に直接登録する方法の二つがありますが、後者はまだ開発中です。

実例
- SATySFi-fonts-theano: https://github.com/na4zagin3/SATySFi-fonts-theano
- SATySFi-grcnum: https://github.com/na4zagin3/SATySFi-grcnum

この節では以下のファイル構成を持つパッケージ `great-package` を登録することにしましょう。
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

以上のファイルは以下の様なディレクトリ構成でインストールされます。

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

#### Satyristes——ビルドファイル
Satyristesに以下の内容を記述して下さい。

```lisp
;; Satyrographos 0.0.2 系列向け
(version 0.0.2)

;; ライブラリ宣言
(library
  ;; ライブラリ名
  (name "great-package")
  ;; ライブラリバージョン
  (version "1.0")
  ;; ファイル
  (sources
    ((fontDir "fonts")
     (hash "fonts.satysfi-hash" "hash/fonts.satysfi-hash")
     (packageDir "packages")))
  ;; OPAMパッケージファイル
  (opam "satysfi-great-package.opam")
  ;; 依存関係
  (dependencies ((fonts-theano ()))))

;; ライブラリドキュメント宣言
(libraryDoc
  ;; ライブラリドキュメント名
  (name "great-package-doc")
  ;; ライブラリバージョン
  (version "1.0")
  ;; ドキュメントをビルドする為の作業ディレクトリ
  (workingDirectory "doc")
  ;; ビルドコマンド
  (build
    ;; SATySFiで処理
    ((satysfi "great-package.saty" "-o" "great-package.pdf")))
  ;; ファイル
  (sources
    ((doc "great-package.pdf" "doc/great-package.pdf")))
  ;; OPAMパッケージファイル
  (opam "satysfi-great-package-doc.opam")
  ;; 依存関係
  (dependencies ((great-package ()))))
```
#### OPAM パッケージファイル
現在の所、OPAM パッケージファイルを記述する必要があります。

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
license: "LGPL-3.0-or-later" # お好きなライセンスを
homepage: "<product home page>"
bug-reports: "<product issue tracker>"
dev-repo: "<repo url>"
depends: [
  "satysfi" {>= "0.0.5" & < "0.0.6"}
  "satyrographos" {>= "0.0.2.6" & < "0.0.3"}
  "satysfi-dist"

  # もし他のライブラリに依存している場合にはここに記述して下さい
  "satysfi-fonts-theano" {>= "2.0+satysfi0.0.3+satyrograhos0.0.2"}
]
build: [ ]
install: [
  ["satyrographos" "opam" "install"
   "--name" "great-package"
   "--prefix" "%{prefix}%"
   "--script" "%{build}%/Satyristes"]
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
license: "LGPL-3.0-or-later" # お好きなライセンスを
homepage: "<product home page>"
bug-reports: "<product issue tracker>"
dev-repo: "<repo url>"
depends: [
  "satysfi" {>= "0.0.5" & < "0.0.6"}
  "satyrographos" {>= "0.0.2.6" & < "0.0.3"}

  # 対応するライブラリをここに書きましょう
  "satysfi-great-library" {= "%{version}%"}
]
build: [
  ["satyrographos" "opam" "build"
   "--name" "great-package-doc"
   "--prefix" "%{prefix}%"
   "--script" "%{build}%/Satyristes"]
]
install: [
  ["satyrographos" "opam" "install"
   "--name" "great-package-doc"
   "--prefix" "%{prefix}%"
   "--script" "%{build}%/Satyristes"]
]
```

#### 開発・テスト方法

大抵の場合、ドキュメントに使用方法が尽くされていることと思います。
以下のコマンドを実行することで、パッケージのインストールからドキュメントのビルドまでを一括で行うことができます。

```sh
$ opam add  --verbose --yes "file://$PWD"
又は
$ opam add -vy "file://$PWD"
```

OPAMに頼らずテストを実行する方法については開発中（[#4](https://github.com/na4zagin3/satyrographos/issues/4)）です。

また、`lint` コマンドは依存関係等の問題を検出することができます。適宜実行して下さい。詳しいオプションは[lint](./doc/lint.md)を見て下さい。

```sh
$ satyrographos lint
```

#### Satyrograpohsレポへの登録
https://opam.ocaml.org/doc/Packaging.html に従えば上手に行くはずです。
但し、`opam publish`には`--repo`オプションを加えて下さい。

```sh
# 問題検出
$ satyrographos lint

# レポジトリにタグを打つ
$ git tag -a <tag>
# タグをプッシュ
$ git push origin <tag>

opam publish --repo=na4zagin3/satyrographos-repo
```

## Satyristes ファイル文法
Satyristes ファイルはS式の列で記述されます。以下の宣言を含みます。

- `(version "0.0.2")` :: Satyrographos 0.0.2系列用のファイルであることを示す
- `(library ...)` :: ライブラリ宣言
- `(libraryDoc ...)` :: ライブラリドキュメント宣言

### `(library ...)` 宣言

- `(name "<library-name>")` :: ライブラリ名
- `(version "<package-version>")` :: ライブラリバージョン
- `(sources (<source-declaration> ...))` :: ソース
  - `(font "<dst>" <src>")` :: `<src>` を `dist/fonts/<library-name>/<dst>` に配置
  - `(fontDir "<src>")` :: `<src>` 以下のファイルを再帰的に `dist/fonts/<library-name>/` 以下に配置
  - `(hash "<dst>" "<src>")` :: `<src>` を `dist/hash/<dst>` に配置
  - `(package "<dst>" "<src>")` :: `<src>` を `dist/packages/<library-name>/<dst>` に配置
  - `(packageDir "<src>")` :: `<src>` 以下のファイルを再帰的に `dist/packages/<library-name>/` 以下に配置
  - `(file "<dst>" "<src>")` :: `<src>` を `dist/<dst>` に配置
- `(opam "<opam-package-file>")` :: OPAM package file.
- `(dependencies (<dependency> ...))` :: 依存関係
  - `(<dependent-library-name> ())` :: `<dependent-library-name>`という名のライブラリに依存
- `(compatibility (<compatibility-item>))` :: 互換性警告
  - `(satyrographos "0.0.1")` :: Satyrographos 0.0.1 からディレクトリ構成が変更されていることを警告
  - `(renamePackage "<new-name>" "<old-name>")` :: パッケージ名の変更
  - `(renameFont "<new-name>" "<old-name>")` :: フォント名の変更

### `(libraryDoc ...)` module

- `(name "<library-name>")` :: ライブラリ名
- `(version "<package-version>")` :: ライブラリバージョン
- `(workingDirectory "<working-dir>")` :: 文書のビルドにあたる作業ディレクトリ
- `(build (<build-command> ..))` :: ビルドコマンド
  - `(satysfi <args> ...)` :: SATySFi を起動
  - `(make <args> ...)` :: ランタイムディレクトリを `SATYSFI_RUNTIME` に設定した上で make を起動
- `(sources (<source-declaration> ...))` :: ソース
  - `(doc "<dst>" "<src>")` :: `<src>` を `dist/docs/<library-name>/<dst>` に配置
- `(opam "<opam-package-file>")` :: OPAMパッケージファイル
- `(dependencies (<dependency> ...))` :: 依存関係
  - `(<dependent-library-name> ())` :: `<dependent-library-name>`という名のライブラリに依存
- `(compatibility (<compatibility-item>))` :: Compatibility warning

## Satyrographos--SATySFi版号対応表

|Satyrographos|SATySFi|
|-------|-------------|
|v0.0.2.5以降|v0.0.5系列|
|v0.0.2.1からv0.0.2.4まで|v0.0.4系列以前（但し、ライブラリドキュメント作成にはsatysfi.0.0.3+dev2019.02.27以後を要す）|
|v0.0.1系列|v0.0.3系列以前|
