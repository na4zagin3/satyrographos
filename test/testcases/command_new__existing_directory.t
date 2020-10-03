Attempt to create a new library with the conflicting name
  $ mkdir test-lib
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos new --license MIT lib test-lib
  Compatibility warning: You have opted in to use experimental features.
  test-lib already exists.
  [1]
  $ find test-lib | LC_ALL=C sort
  test-lib
