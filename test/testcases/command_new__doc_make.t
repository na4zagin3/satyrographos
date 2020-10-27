Create a new library with --license option
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos new doc-make --license CC-BY-4.0 test-doc
  Compatibility warning: You have opted in to use experimental features.
  Name: test-doc
  License: CC-BY-4.0
  Created a new library/document.

Try to build when there is satysfi command
  $ if command satysfi --version >/dev/null 2>&1 && opam list -i --silent satysfi-dist && opam list -i --silent satysfi-fss ; then
  >   cd test-doc
  >   SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos build >build.log 2>&1
  >   [ -f main.pdf ] || cat build.log
  > fi
