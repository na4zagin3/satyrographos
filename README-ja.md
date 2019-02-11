# Satyrographos サテュログラポス

[![Build Status](https://travis-ci.com/na4zagin3/satyrographos.svg?branch=master)](https://travis-ci.com/na4zagin3/satyrographos)

[SATySFi](https://github.com/gfngfn/SATySFi)用の簡易パッケージマネージャー

**警告 `satyrographos install` を除くコマンドラインインターフェースは実験的なものであり、今後、変更・削除されえます**

Satyrographos は、`~/.opam/<ocaml-version>/share/satysfi/<package>` 以下のファイルを、`~/.satysfi/dist` にコピーするものです。
この時、各パッケージのフォントハッシュファイルは適切に統合されます。
また、システムフォントを SATySFi で使用可能にすることもできます（[Install System Fonts](#Install-System-Fonts) を見よ）。

Satyrographos は SATySFi のインストールを簡略化します。
詳しくは [SATySFi インストールバトル手引き 2019年1月版](https://qiita.com/na4zagin3/items/a6e025c17ef991a4c923) をご覧下さい。

## システムフォントのインストール
**この機能はいまだ実験的なものであり、将来、使用方法や振舞いが変更される虞があります**

もし、OS に [Fontconfig](https://www.freedesktop.org/wiki/Software/fontconfig/) が存在する場合、例えば、Mac や Linux を使っている場合には、
SATySFi でシステムフォントを使えるように設定することができます。

`satyrographos install` に `-system-font-prefix <フォント名接頭辞>` オプションが追加されると、Satyrographos はシステムフォントの情報を収集し、SATySFi 側からは元々のフォント名に `<フォント名接頭辞>` が付いた名前で使えるように設定します。

例えば、次のコマンドにより、システムフォントが `system:` を冠した名前で使えるようになります。

```
$ satyrographos install -system-font-prefix 'system:'
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

## 仕組み
Satyrographos は `~/.opam/<ocaml-version>/share/satysfi/<package>` と  `~/.satyrographos/packages/<package>` にある全てのファイルを `~/.satysfi/dist` にリンクします。

また、ファイルの重複検知やハッシュファイルのマージも同時に行います。それを除けば、 `satyrographos install` は以下のコマンドを実行しているのと似たようなものです。
```sh
$ cp -r "$(opam var share)"/share/satysfi/*/* ~/.satysfi/dist
$ cp -r ~/.satyrographos/packages/*/* ~/.satysfi/dist
```

加えて、 `-system-font-prefix <system-font-name-prefix>` が用いられると、 Satyrograph はシステムフォントの情報を `fc-list` コマンドを用いて得、インストールします。

## ライブラリの登録方法
ライブラリは OPAM ライブラリとしてインストールする方法と、Satyrographos に直接登録する方法の二つがありますが、後者はまだ開発中です。

この節では以下のファイル構成を持つパッケージ `great-package` を登録することにしましょう。
```
- ~/src/
  - great-package/
    - hash/
      - fonts.satysfi-hash
    - fonts/
      - interesting-font.ttf
    - packages/
      - your-great.package.satyh
```

### OPAM パッケージ
`~/src/great-package` 全体を `%{share}%/satysfi/great-package` にコピーする OPAM パッケージを書いて下さい。

実例
- SATySFi-fonts-theano: https://github.com/na4zagin3/SATySFi-fonts-theano
- SATySFi-grcnum: https://github.com/na4zagin3/SATySFi-grcnum

### Satyrographos に直接登録する方法（実験的）
ライブラリのあるディレクトリを直接 `satyrographos pin add <ディレクトリ>` で登録して下さい。

```
$ satyrographos pin add ~/src/great-package
$ satyrographos install
```
