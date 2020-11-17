Create a new document with example-autogen template
  $ satyrographos new [experimental]example-autogen --license CC-BY-4.0 test-example-autogen
  Name: test-example-autogen
  License: CC-BY-4.0
  Created a new library/document.

Try to build when there is satysfi command
  $ if command satysfi --version >/dev/null 2>&1 && opam list -i --silent satysfi-dist ; then
  >   cd test-example-autogen
  >   SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos build >build.log 2>&1
  >   [ -f main.pdf ] || cat build.log
  >   cd ..
  > fi
  Compatibility warning: You have opted in to use experimental features.
  WARNING: Script lang 0.0.3 is under development.
  
  ================
  Reading runtime dist: /home/puripuri2100/.opam/4.10.0/share/satysfi/dist
  Read user libraries: ()
  Reading opam libraries: (base bibyfi class-exdesign class-jlreq dist easytable enumitem
   fonts-bodoni-star fonts-computer-modern-unicode fonts-cormorant fonts-dejavu
   fonts-junicode fonts-noto-sans fonts-noto-sans-cjk-jp fonts-noto-serif
   fonts-noto-serif-cjk-jp fss lipsum make-html make-latex make-latex-doc
   md2latex ruby ruby-doc simple-itemize siunitx texlogo texlogo-doc tombo
   uline zrbase)
  Overriding dist with user installed one
  Not gathering system fonts
  Generating autogen libraries
  Generating autogen library $today
  Generating autogen library $fonts
  Uncaught exception:
    
    (Failure "fc-scan: command not found")
  
  Raised at file "stdlib.ml", line 29, characters 17-33
  Called from file "process-lib/src/process.ml", line 167, characters 18-51
  Called from file "process-lib/src/process.ml", line 167, characters 18-51
  Called from file "process-lib/src/process.ml", line 171, characters 13-44
  Re-raised at file "process-lib/src/process.ml", line 177, characters 9-20
  Called from file "process-lib/src/process.ml", line 212, characters 20-45
  Called from file "process-lib/src/process.ml", line 167, characters 18-51
  Called from file "process-lib/src/process.ml", line 167, characters 18-51
  Called from file "process-lib/src/process.ml", line 160, characters 16-49
  Re-raised at file "process-lib/src/process.ml", line 163, characters 10-21
  Called from file "src/autogen/fonts.ml", line 237, characters 4-50
  Called from file "src/command/install.ml", line 148, characters 26-54
  Called from file "src/command/install.ml", line 159, characters 2-140
  Called from file "src/command/install.ml", line 213, characters 4-103
  Called from file "src/command/build.ml", line 50, characters 2-146
  Called from file "src/command/build.ml", line 60, characters 6-132
  Called from file "src/command/build.ml", line 71, characters 6-32
  Called from file "src/command/build.ml", line 132, characters 4-92
  Called from file "bin/commandBuild.ml", line 31, characters 9-105
  Called from file "src/command.ml", line 2451, characters 8-238
  Called from file "src/exn.ml", line 111, characters 6-10

Ensure there are no warnings
  $ satyrographos lint -W '-lib/dep/exception-during-setup' --script test-example-autogen/Satyristes --satysfi-version 0.0.5
  WARNING: Script lang 0.0.3 is under development.
  0 problem(s) found.
