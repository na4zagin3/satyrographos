Attempt to create libraries with invalid names
  $ satyrographos new --license MIT lib test/lib
  Project name should consist of ASCII alphabets, numbers, underscores, or hyphens.
  [1]
  $ satyrographos new --license MIT lib test.lib
  Project name should consist of ASCII alphabets, numbers, underscores, or hyphens.
  [1]
  $ satyrographos new --license MIT lib test-lib.
  Project name should consist of ASCII alphabets, numbers, underscores, or hyphens.
  [1]
