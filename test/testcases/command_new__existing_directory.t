Attempt to create a new library with the conflicting name
  $ mkdir test-lib
  $ satyrographos new --license MIT lib test-lib
  test-lib already exists.
  [1]
  $ find test-lib | LC_ALL=C sort
  test-lib
