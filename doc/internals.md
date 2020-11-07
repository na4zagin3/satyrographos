# Internals

Satyrographos links all files under `~/.opam/<ocaml-version>/share/satysfi/<package>` and  `~/.satyrographos/packages/<package>` into `~/.satysfi/dist`.

Satyrographos also does duplication detection, hash file merging, show compatibility warning, &c. Basically `satyrographos install` behaves as
```sh
$ cp -r "$(opam var share)"/share/satysfi/*/* ~/.satysfi/dist
$ cp -r ~/.satyrographos/packages/*/* ~/.satysfi/dist
```

With `--system-font-prefix <system-font-name-prefix>`, Satyrograph query system fonts with `fc-list` and installs those fonts too.
