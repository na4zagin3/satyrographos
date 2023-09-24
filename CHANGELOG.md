# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Haskell PVP](https://pvp.haskell.org/).

## [Unreleased]

## [v0.0.2.12] - 2023-09-25
### Changed
- Make `library-opam list` subcommand output in shellscript-friendly multi line format ([#299])
- Update dependent yaml library to 3.0 ([#301])
- Refactored the clam test cases with shared shell script functions ([#300], [#302])
- `install` subcommand shows reverse dependencies of missing libraries ([#303])
- Support Core v0.15 and v0.16 by dropping support of OCaml 4.10 and older ([#309], [#312])

### Fixed
- Race condition non-dependent packages are being removed during reading libraries ([#298])

## [v0.0.2.11] - 2021-03-13
### Changed
- Update templates ([#276] by @puripuri2100)
- Use `--no-default-config` option if available ([#279])
- Install dependencies of doc module before building ([#281])
- `build` subcommand now accepts multiple module names to build ([#281])
- Removed `pin` subcommand ([#285])

### Fixed
- Fixed README ([#277] by  @y-yu, [#282] by  @TonalidadeHidrica, [#290])
- `migrate` subcommand used a wrong module name ([#280])
- Don't stop when fails to load non-dependent libraries ([#289])

## [v0.0.2.10] - 2021-03-08
### Fixed
- Run some architecture-dependent test cases only on 64-bit architectures ([#272])

## [v0.0.2.9] - 2021-03-07
### Added
- Added `md` source type ([#255] by @puripuri2100)
- Added new lint test case `hash/font/location/src-dist` that warns `src-dist` locations in font hash files ([#268])
- Automatically convert `src-dist` field into `src` for Build File 0.0.2 ([#269])

### Changed
- Apply `CC0-1.0` license to the templates ([#258])
- Add build section to library OPAM files in the templates ([#257])

### Fixed
- Fixed library dependencies ([#254])
- CI: Use GitHub Action ([#261], [#262], [#267]; [#263] by @y-yu)

## [v0.0.2.8] - 2020-11-08

### Added
- Add `build` subcommand to create a new project from templates ([#194]).
- Add `$today` autogen library, which has the current datetime and tzname ([#201]).
- (Experimental) Add build script lang 0.0.3 support ([#202]).
  - `(run <args>...)` build command ([#217])
  - `(omake <args>...)` build command ([#226])
  - `(make-with-env-var <args>...)` build command which is equivalent to `(make <args>...)` in build script lang 0.0.2  ([#226])
  - `(make <args>...)` build command now does not set `SATYSFI_RUNTIME` environmental variable ([#226])
  - `(font <dst> <src> (<font-hashes>...))` source ([#224], [#235])
  - `(autogen (<autogen-libraries>...))` clause ([#231])
- Add `[experimental]doc-make@en`, `[experimental]doc-make@ja`, `[experimental]doc-omake@en`, `[experimental]doc-omake@ja`, and `[experimental]example-autogen` templates ([#206], [#209], [#219], [#223], [#242], [#244], [#240]).
- Add `-W <warning-expr>` option to `lint` command to enable/disable specific warnings ([#215]).
- (Experimental) Add `migrate` subcommand to automatically migrate Satyrographos projects ([#216], [#251])
- (Experimental) Add `lockdown` subcommand to save/restore the current build environment ([#225], [#228])
- Support `.satysfi-md` as a source type for dependency extraction ([#248]).

### Changed
- Refine commandline options of `util deps-make` subcommand ([#203], [#204]).
- Remove Compatibility notices for Satyrographos 0.0.1 libraries ([#210])
- Remove prefixes for SATySFi or Make output (e.g., `satysfi out>`) ([#214])
- Improve the error message when the OPAM file and the Satyrographos module have mismatching versions ([#238])
- Renamed autogen libraries ([#239]).  Now they are prefixed with `$`.
- `new` subcommand is no longer experimental ([#242]).
- `lint` subcommand is no longer experimental ([#243]).
- `build` subcommand runs `opam pin` and `opam reinstall` separately ([#252]).

### Fixed
- Fix a bug where unit tests executing satyrographos occationally fail ([#199]).
- Fix a bug where `lint` subcommand fails with an exception when SATySFi is not installed ([#220]).
- Explicitly reject unavailable autogen libraries instead of silently ignoring ([#234]).
- Require paths with `..` are now normalized ([#245]).
- Valid imports were reported when they are importing the same target of problematic imports ([#246]).
- Fix command summaries ([#250])

## [v0.0.2.7] - 2020-10-19
### Added
- Add `new` subcommand to create a new project from templates ([#152], [#158], [#159], [#188]).
- Add `lint` subcommand to detect errors in Satyrographos libraries ([#165], [#185], [#186]).
- Add `debug` subcommand to run utilities for debugging ([#178]).
- Add `debug depgraph` subcommand to output dependency graph of SATySFi source files ([#178], [#180], [#183], [#185]).
- Add `doc/terminology.md` to define terms used in the project ([#177]).

### Changed
- Internal representation of a build file now have location of each module declaration, wherefore outputs of `lint` and `opam buildfile` have line numbers ([#171])
- Use version string generated by `git describe` for pin build ([#189])

### Fixed
- Unit tests get locale-invaliant ([#163]).
- Weird indents in compatibility warnings are fixed ([#164] by @matsud224).
- Missing spaces and confusing option docs are fixed ([#173]).
- Compatibility opt-in warnings are now output to stderr instead of stdout ([#175])

## [v0.0.2.6] - 2020-08-30
### Added
- Add `satysfi` subcommand to run SATySFi as an experimental feature. ([#137])

### Changed
- Add GNU style long options and deprecate old ones ([#134], [#142], [#143]).

## [v0.0.2.5] - 2020-07-11
### Changed
- Now `satyrographos opam uninstall` does nothing. ([#128])

### Removed
- Drop support of OCaml 4.08 and older, and SATySFi 0.0.4 and older.

## [v0.0.2.4] - 2020-03-22
### Added
- Add autogen package `satyrographos/experimental/fonts` (`%fonts`) as an experimental feature. ([#122], [#125])
- Add autogen package `satyrographos/experimental/libraries` (`%libraries`) as an experimental feature. ([#122])

### Fixed
- Show a warning message instead of failing with non-hash files in hash dir ([#110] reported by @gfngfn, [#111])
- Show a filename when a hash file contains a grammatical error ([#115])

## [v0.0.2.3] - 2020-02-15
### Added
- Add file sections to recursively add fonts `(fontDir <dir>)` and packages `(packageDir <dir>)` ([#102])

### Changed
- For OCaml 4.09 and later, Package metadata format in OPAM and Satyrographos registries is changed.
  This may require people using the affected OCaml versions to remove `~/.satyrographos`. ([#89])
- Outputs from external commands have prefix for each line ([#101], [#103])

### Fixed
- Using `(file <dst> <src>)` had `opam install` fail  ([#96])
- `install` didn’t fail when dependencies are not met ([#97])
- Fix missing line breaks in verbose messages ([#100])
- Fix a bug where `install` fails when `/usr/share/satysfi/dist` or `/usr/local/share/satysfi/dist` exists but
  no satysfi packages are installed in OPAM. ([#106])

## [v0.0.2.2] - 2019-12-28
### Added
- Add alias `-l` of `-library` option of `install` subcommand ([#74])
- Support core v0.13 ([#70] by @xclerc & [#71])

### Fixed
- Fix filepath of installed system fonts ([#73] by @matonix)
- Fix a message missing the line break ([#75])

## [v0.0.2.1] - 2019-09-11
### Added
- Read SATYROGRAPHOS_DIR for Satyrographos registry ([#55])

### Changed
- Stop writing `~/.satyrographos` unless it is required ([#57])

## [v0.0.2.0] - 2019-09-10
### Added
- Add `-package PACKAGE` option to `install` subcommand. ([#29], [#35])
- Support build script `Satyristes` ([#30], [#33], [#41])
- Show compatibility warnings ([#40], [#46])
- Build library docs (require satysfi capable with `-C` option) ([#43])

### Changed
- Use consistent terminology. ([#39])
- Changed metadata format stored in package registry, which requires removing existing `~/.satyrographos` directory ([#51])

### Fixed
- Fix install directory when environment variable `SATYSFI_RUNTIME` exists. ([#25])

## [v0.0.1.7] - 2019-04-19
### Fixed
- Satyrographos does not fail even when OPAM does not exist

## [v0.0.1.6] - 2019-04-09
### Added
- Add `install -copy` to copy files rather than create symlinks.

## [v0.0.1.5] - 2019-02-13
### Changed
- When satysfi dist does not exist in the OPAM registory, Satyrographos use one in either `/usr/local/share/satysfi/dist` or `/usr/share/satysfi/dist`.
- `satyrographos status` has more information.

### Fixed
- Non-deterministic test failure

## [v0.0.1.4] - 2019-02-11
### Fixed
- Fix build error with YoJson 1.4.1+satysfi
- Updated README

## [v0.0.1.3] - 2019-02-10
### Fixed
- Fix build error with YoJson 1.6.0

## [v0.0.1.2] - 2019-01-07
### Added
- Add compatibility gates and warnings.
- Add `-system-font-prefix <system-font-name-prefix>` to install system fonts.
- Add `-verbose` to control message verbosity.

### Changed
- Use new repository schema.
- Installs symbolic links to files under the registory rather than their copies.

## [v0.0.1.1] - 2018-10-31
### Added
- Accepts `-help`, `help` and so on in command line argument

## [v0.0.1.0] - 2018-10-21
### Added
- Add Licence and Changelog.
- Functionality to register packages
- Functionality to install registered packages
- Merge hash files
- Detect duplicated package files
- Detect duplicated hash definitions

[#25]: https://github.com/na4zagin3/satyrographos/pull/25
[#29]: https://github.com/na4zagin3/satyrographos/pull/29
[#30]: https://github.com/na4zagin3/satyrographos/pull/30
[#33]: https://github.com/na4zagin3/satyrographos/pull/33
[#35]: https://github.com/na4zagin3/satyrographos/pull/35
[#39]: https://github.com/na4zagin3/satyrographos/pull/39
[#40]: https://github.com/na4zagin3/satyrographos/pull/40
[#41]: https://github.com/na4zagin3/satyrographos/pull/41
[#43]: https://github.com/na4zagin3/satyrographos/pull/43
[#46]: https://github.com/na4zagin3/satyrographos/pull/46
[#51]: https://github.com/na4zagin3/satyrographos/pull/51
[#55]: https://github.com/na4zagin3/satyrographos/pull/55
[#57]: https://github.com/na4zagin3/satyrographos/pull/57
[#70]: https://github.com/na4zagin3/satyrographos/pull/70
[#71]: https://github.com/na4zagin3/satyrographos/pull/71
[#73]: https://github.com/na4zagin3/satyrographos/pull/73
[#74]: https://github.com/na4zagin3/satyrographos/pull/74
[#75]: https://github.com/na4zagin3/satyrographos/pull/75
[#89]: https://github.com/na4zagin3/satyrographos/pull/89
[#96]: https://github.com/na4zagin3/satyrographos/pull/96
[#97]: https://github.com/na4zagin3/satyrographos/pull/97
[#100]: https://github.com/na4zagin3/satyrographos/pull/100
[#101]: https://github.com/na4zagin3/satyrographos/pull/101
[#102]: https://github.com/na4zagin3/satyrographos/pull/102
[#103]: https://github.com/na4zagin3/satyrographos/pull/103
[#106]: https://github.com/na4zagin3/satyrographos/pull/106
[#110]: https://github.com/na4zagin3/satyrographos/pull/110
[#111]: https://github.com/na4zagin3/satyrographos/pull/111
[#115]: https://github.com/na4zagin3/satyrographos/pull/115
[#121]: https://github.com/na4zagin3/satyrographos/pull/121
[#122]: https://github.com/na4zagin3/satyrographos/pull/122
[#125]: https://github.com/na4zagin3/satyrographos/pull/125
[#128]: https://github.com/na4zagin3/satyrographos/pull/128
[#134]: https://github.com/na4zagin3/satyrographos/pull/134
[#137]: https://github.com/na4zagin3/satyrographos/pull/137
[#142]: https://github.com/na4zagin3/satyrographos/pull/142
[#143]: https://github.com/na4zagin3/satyrographos/pull/143
[#152]: https://github.com/na4zagin3/satyrographos/pull/152
[#158]: https://github.com/na4zagin3/satyrographos/pull/158
[#159]: https://github.com/na4zagin3/satyrographos/pull/159
[#163]: https://github.com/na4zagin3/satyrographos/pull/163
[#164]: https://github.com/na4zagin3/satyrographos/pull/164
[#165]: https://github.com/na4zagin3/satyrographos/pull/165
[#171]: https://github.com/na4zagin3/satyrographos/pull/171
[#173]: https://github.com/na4zagin3/satyrographos/pull/173
[#175]: https://github.com/na4zagin3/satyrographos/pull/175
[#177]: https://github.com/na4zagin3/satyrographos/pull/177
[#178]: https://github.com/na4zagin3/satyrographos/pull/178
[#180]: https://github.com/na4zagin3/satyrographos/pull/180
[#183]: https://github.com/na4zagin3/satyrographos/pull/183
[#185]: https://github.com/na4zagin3/satyrographos/pull/185
[#186]: https://github.com/na4zagin3/satyrographos/pull/186
[#188]: https://github.com/na4zagin3/satyrographos/pull/188
[#189]: https://github.com/na4zagin3/satyrographos/pull/189
[#190]: https://github.com/na4zagin3/satyrographos/pull/190
[#194]: https://github.com/na4zagin3/satyrographos/pull/194
[#199]: https://github.com/na4zagin3/satyrographos/pull/199
[#201]: https://github.com/na4zagin3/satyrographos/pull/201
[#202]: https://github.com/na4zagin3/satyrographos/pull/202
[#203]: https://github.com/na4zagin3/satyrographos/pull/203
[#204]: https://github.com/na4zagin3/satyrographos/pull/204
[#206]: https://github.com/na4zagin3/satyrographos/pull/206
[#209]: https://github.com/na4zagin3/satyrographos/pull/209
[#210]: https://github.com/na4zagin3/satyrographos/pull/210
[#214]: https://github.com/na4zagin3/satyrographos/pull/214
[#215]: https://github.com/na4zagin3/satyrographos/pull/215
[#216]: https://github.com/na4zagin3/satyrographos/pull/216
[#217]: https://github.com/na4zagin3/satyrographos/pull/217
[#219]: https://github.com/na4zagin3/satyrographos/pull/219
[#220]: https://github.com/na4zagin3/satyrographos/pull/220
[#223]: https://github.com/na4zagin3/satyrographos/pull/223
[#224]: https://github.com/na4zagin3/satyrographos/pull/224
[#225]: https://github.com/na4zagin3/satyrographos/pull/225
[#226]: https://github.com/na4zagin3/satyrographos/pull/226
[#228]: https://github.com/na4zagin3/satyrographos/pull/228
[#231]: https://github.com/na4zagin3/satyrographos/pull/231
[#234]: https://github.com/na4zagin3/satyrographos/pull/234
[#235]: https://github.com/na4zagin3/satyrographos/pull/235
[#238]: https://github.com/na4zagin3/satyrographos/pull/238
[#239]: https://github.com/na4zagin3/satyrographos/pull/239
[#240]: https://github.com/na4zagin3/satyrographos/pull/240
[#242]: https://github.com/na4zagin3/satyrographos/pull/242
[#243]: https://github.com/na4zagin3/satyrographos/pull/243
[#244]: https://github.com/na4zagin3/satyrographos/pull/244
[#245]: https://github.com/na4zagin3/satyrographos/pull/245
[#246]: https://github.com/na4zagin3/satyrographos/pull/246
[#248]: https://github.com/na4zagin3/satyrographos/pull/248
[#250]: https://github.com/na4zagin3/satyrographos/pull/250
[#251]: https://github.com/na4zagin3/satyrographos/pull/251
[#252]: https://github.com/na4zagin3/satyrographos/pull/252
[#254]: https://github.com/na4zagin3/satyrographos/pull/254
[#255]: https://github.com/na4zagin3/satyrographos/pull/255
[#257]: https://github.com/na4zagin3/satyrographos/pull/257
[#258]: https://github.com/na4zagin3/satyrographos/pull/258
[#261]: https://github.com/na4zagin3/satyrographos/pull/261
[#262]: https://github.com/na4zagin3/satyrographos/pull/262
[#263]: https://github.com/na4zagin3/satyrographos/pull/263
[#267]: https://github.com/na4zagin3/satyrographos/pull/267
[#268]: https://github.com/na4zagin3/satyrographos/pull/268
[#269]: https://github.com/na4zagin3/satyrographos/pull/269
[#272]: https://github.com/na4zagin3/satyrographos/pull/272
[#276]: https://github.com/na4zagin3/satyrographos/pull/276
[#277]: https://github.com/na4zagin3/satyrographos/pull/277
[#279]: https://github.com/na4zagin3/satyrographos/pull/279
[#280]: https://github.com/na4zagin3/satyrographos/pull/280
[#281]: https://github.com/na4zagin3/satyrographos/pull/281
[#282]: https://github.com/na4zagin3/satyrographos/pull/282
[#285]: https://github.com/na4zagin3/satyrographos/pull/285
[#289]: https://github.com/na4zagin3/satyrographos/pull/289
[#290]: https://github.com/na4zagin3/satyrographos/pull/290
[#298]: https://github.com/na4zagin3/satyrographos/pull/298
[#299]: https://github.com/na4zagin3/satyrographos/pull/299
[#300]: https://github.com/na4zagin3/satyrographos/pull/300
[#301]: https://github.com/na4zagin3/satyrographos/pull/301
[#302]: https://github.com/na4zagin3/satyrographos/pull/302
[#303]: https://github.com/na4zagin3/satyrographos/pull/303
[#309]: https://github.com/na4zagin3/satyrographos/pull/309
[#312]: https://github.com/na4zagin3/satyrographos/pull/312


[Unreleased]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.12...HEAD
[v0.0.2.12]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.11...v0.0.2.12
[v0.0.2.11]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.10...v0.0.2.11
[v0.0.2.10]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.9...v0.0.2.10
[v0.0.2.9]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.8...v0.0.2.9
[v0.0.2.8]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.7...v0.0.2.8
[v0.0.2.7]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.6...v0.0.2.7
[v0.0.2.6]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.5...v0.0.2.6
[v0.0.2.5]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.4...v0.0.2.5
[v0.0.2.4]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.3...v0.0.2.4
[v0.0.2.3]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.2...v0.0.2.3
[v0.0.2.2]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.1...v0.0.2.2
[v0.0.2.1]: https://github.com/na4zagin3/satyrographos/compare/v0.0.2.0...v0.0.2.1
[v0.0.2.0]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.7...v0.0.2.0
[v0.0.1.7]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.6...v0.0.1.7
[v0.0.1.6]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.5...v0.0.1.6
[v0.0.1.5]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.4...v0.0.1.5
[v0.0.1.4]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.3...v0.0.1.4
[v0.0.1.3]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.2...v0.0.1.3
[v0.0.1.2]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.1...v0.0.1.2
[v0.0.1.1]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.0...v0.0.1.1
[v0.0.1.0]: https://github.com/na4zagin3/satyrographos/tree/v0.0.1.0
