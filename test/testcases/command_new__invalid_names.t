Attempt to create libraries with invalid names
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos new --license MIT lib test/lib
  Compatibility warning: You have opted in to use experimental features.
  Project name should consist of ASCII alphabets, numbers, underscores, or hyphens.
  [1]
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos new --license MIT lib test.lib
  Compatibility warning: You have opted in to use experimental features.
  Project name should consist of ASCII alphabets, numbers, underscores, or hyphens.
  [1]
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos new --license MIT lib test-lib.
  Compatibility warning: You have opted in to use experimental features.
  Project name should consist of ASCII alphabets, numbers, underscores, or hyphens.
  [1]
