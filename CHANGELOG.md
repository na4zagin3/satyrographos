# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Haskell PVP](https://pvp.haskell.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.7...HEAD
[v0.0.1.7]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.6...v0.0.1.7
[v0.0.1.6]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.5...v0.0.1.6
[v0.0.1.5]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.4...v0.0.1.5
[v0.0.1.4]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.3...v0.0.1.4
[v0.0.1.3]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.2...v0.0.1.3
[v0.0.1.2]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.1...v0.0.1.2
[v0.0.1.1]: https://github.com/na4zagin3/satyrographos/compare/v0.0.1.0...v0.0.1.1
[v0.0.1.0]: https://github.com/na4zagin3/satyrographos/tree/v0.0.1.0
