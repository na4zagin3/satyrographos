Prepare a Satyrographos 0.0.2 library
  $ mkdir test-lib
  $ cat > test-lib/Satyristes <<EOF
  > (version 0.0.2)
  > (library
  >   (name "package")
  >   (version "0.1")
  >   (sources (
  >     (package "test.satyh" "test.satyh")
  >     (font "test.satyh" "test.satyh")
  >     (hash "fonts.satysfi-hash" "fonts.satysfi-hash")
  >     (font "TheanoDidot-Regular.otf" "theano/TheanoDidot-Regular.otf")
  >     (file "md/mdja2.satysfi-md" "mdja2.satysfi-md")
  >     ))
  >   (opam "satysfi-package.opam")
  >   (compatibility ((renameFont fonts-theano:TheanoDidot TheanoDidot)
  >                   (satyrographos 0.0.1)))
  >   (dependencies ((fss ()))))
  > 
  > (libraryDoc
  >   (name "package-doc")
  >   (version "0.1")
  >   (build ())
  >   (sources ())
  >   (opam "satysfi-package-doc.opam")
  >   (dependencies ((package ()))))
  > EOF
  $ cat > test-lib/satysfi-package.opam <<EOF
  > opam-version: "2.0"
  > build: []
  > install: [
  >   ["satyrographos" "opam" "install"
  >    "--name" "satysfi-package"
  >    "--prefix" "%{prefix}%"
  >    "--script" "%{build}%/Satyristes"]
  > ]
  > EOF
  $ cat > test-lib/satysfi-package-doc.opam <<EOF
  > opam-version: "2.0"
  > build: [
  >   ["satyrographos" "opam" "build"
  >    "--name" "satysfi-package-doc"
  >    "--prefix" "%{prefix}%"
  >    "--script" "%{build}%/Satyristes"]
  > ]
  > install: [
  >   ["satyrographos" "opam" "install"
  >    "--name" "satysfi-package-doc"
  >    "--prefix" "%{prefix}%"
  >    "--script" "%{build}%/Satyristes"]
  > ]
  > EOF

  $ cd test-lib

Default is NO
  $ printf "\n" | SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos migrate
  Compatibility warning: You have opted in to use experimental features.
  *WARNING*
  Before migration, please ensure that `satyrographos lint` reports no problems.
  Otherwise, address them.
  Additionally, please take a backup (e.g., committing changes to the git repo) beforehand.
  Type “yes” if you are ready to proceed.
  [yes/NO] Canceled.

Migrate the library
  $ printf "yes\n\n" | SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos migrate
  Compatibility warning: You have opted in to use experimental features.
  *WARNING*
  Before migration, please ensure that `satyrographos lint` reports no problems.
  Otherwise, address them.
  Additionally, please take a backup (e.g., committing changes to the git repo) beforehand.
  Type “yes” if you are ready to proceed.
  [yes/NO] Reading $TESTCASE_ROOT/test-lib/Satyristes.
  Writing $TESTCASE_ROOT/test-lib/Satyristes.
  WARNING: Script lang 0.0.3 is under development.
  Reading satysfi-package.opam
  Fixing build section in satysfi-package.opam.
  Writing satysfi-package.opam
  Reading satysfi-package-doc.opam
  Please be sure satysfi-package-doc.opam has the following build section.
  
  build:
    ["satyrographos" "opam" "install"
     "--name" "satysfi-package-doc"
     "--prefix" "%{prefix}%"
     "--script" "%{build}%/Satyristes"]
  Done.

Dump generated files
  $ mkdir ../empty-dir
  $ diff -Nr ../empty-dir .
  diff -Nr ../empty-dir/Satyristes ./Satyristes
  0a1,11
  > (Lang 0.0.3)
  > (Library (name package) (version 0.1) (opam satysfi-package.opam)
  >  (sources
  >   ((Package test.satyh test.satyh) (Font test.satyh test.satyh ())
  >    (Hash fonts.satysfi-hash fonts.satysfi-hash)
  >    (Font TheanoDidot-Regular.otf theano/TheanoDidot-Regular.otf ())
  >    (File md/mdja2.satysfi-md mdja2.satysfi-md)))
  >  (dependencies (fss))
  >  (compatibility ((RenameFont fonts-theano:TheanoDidot TheanoDidot))))
  > (LibraryDoc (name package-doc) (version 0.1) (opam satysfi-package-doc.opam)
  >  (workingDirectory .) (dependencies (package)))
  diff -Nr ../empty-dir/satysfi-package-doc.opam ./satysfi-package-doc.opam
  0a1,13
  > opam-version: "2.0"
  > build: [
  >   ["satyrographos" "opam" "build"
  >    "--name" "satysfi-package-doc"
  >    "--prefix" "%{prefix}%"
  >    "--script" "%{build}%/Satyristes"]
  > ]
  > install: [
  >   ["satyrographos" "opam" "install"
  >    "--name" "satysfi-package-doc"
  >    "--prefix" "%{prefix}%"
  >    "--script" "%{build}%/Satyristes"]
  > ]
  diff -Nr ../empty-dir/satysfi-package.opam ./satysfi-package.opam
  0a1,23
  > opam-version: "2.0"
  > build: [
  >   "satyrographos"
  >   "opam"
  >   "install"
  >   "--name"
  >   "satysfi-package"
  >   "--prefix"
  >   "%{prefix}%"
  >   "--script"
  >   "%{build}%/Satyristes"
  > ]
  > install: [
  >   "satyrographos"
  >   "opam"
  >   "install"
  >   "--name"
  >   "satysfi-package"
  >   "--prefix"
  >   "%{prefix}%"
  >   "--script"
  >   "%{build}%/Satyristes"
  > ]
  [1]

Migration is idempotent
  $ printf "yes\n\n" | SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos migrate
  Compatibility warning: You have opted in to use experimental features.
  *WARNING*
  Before migration, please ensure that `satyrographos lint` reports no problems.
  Otherwise, address them.
  Additionally, please take a backup (e.g., committing changes to the git repo) beforehand.
  Type “yes” if you are ready to proceed.
  [yes/NO] WARNING: Script lang 0.0.3 is under development.
  Nothing to migrate.
