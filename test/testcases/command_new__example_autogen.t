Create a new document with example-autogen template
  $ satyrographos new [experimental]example-autogen --license CC-BY-4.0 test-example-autogen
  Name: test-example-autogen
  License: CC-BY-4.0
  Created a new library/document.

Try to build when there is satysfi command
  $ if command satysfi --version >/dev/null 2>&1 && command fc-scan --version >/dev/null 2>&1 && opam list -i --silent satysfi-dist ; then
  >   cd test-example-autogen
  >   SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos build >build.log 2>&1
  >   [ -f main.pdf ] || cat build.log
  >   cd ..
  > fi

Ensure there are no warnings
  $ satyrographos lint -W '-lib/dep/exception-during-setup' --script test-example-autogen/Satyristes --satysfi-version 0.0.5
  WARNING: Script lang 0.0.3 is under development.
  0 problem(s) found.
