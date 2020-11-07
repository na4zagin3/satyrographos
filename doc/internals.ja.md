# 内部仕様

Satyrographos は `~/.opam/<ocaml-version>/share/satysfi/<package>` と  `~/.satyrographos/packages/<package>` にある全てのファイルを `~/.satysfi/dist` にリンクする。

また、ファイルの重複検知やハッシュファイルのマージ等も同時に行う。それを除けば、 `satyrographos install` は以下のコマンドを実行しているのと似たようなものである。

```sh
$ cp -r "$(opam var share)"/share/satysfi/*/* ~/.satysfi/dist
$ cp -r ~/.satyrographos/packages/*/* ~/.satysfi/dist
```

加えて、 `--system-font-prefix <system-font-name-prefix>` が用いられると、 Satyrograph はシステムフォントの情報を `fc-list` コマンドを用いて得、インストールする。
