<!-- markdownlint-disable -->
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.1] - 2023-04-15
### Fixed
- Support for neotest's upcoming [`nio` async library](https://github.com/nvim-neotest/neotest/pull/228).

## [0.8.0] - 2023-03-31
### Added
- Support for the [`sydtest`](https://hackage.haskell.org/package/sydtest) test framework.
- Move position queries to `queries/haskell/<framework>-positions.scm`
  and `queries/haskell/<framework>-test`. This allows the addition of extra
  queries to `$XDG_CONFIG_HOME/nvim/after/queries/haskell/<framework>-positions.scm`
### Fixed
- Hspec: support `context`, `xcontext`, `specify` and `xspecify`

## [0.7.0] - 2023-03-22
### Added
- Support configuring which modules are used to identify test frameworks.

## [0.6.0] - 2023-03-19
### Added
- Support for the [`tasty`](https://hackage.haskell.org/package/tasty) test framework.
- Tested with:
  * `tasty-hspec`
  * `tasty-hunit`
  * `tasty-quickcheck`
  * `tasty-smallcheck`
  * `tasty-hedgehog`
  * `tasty-leancheck`
  * `tasty-expected-failure`
  * `tasty-program`
  * `tasty-wai`

## [0.5.0] - 2023-03-12
### Added
- Health checks (`:help checkhealth`).
- Hspec: Support for skipped tests (`xdescribe` `xit`, `xprop`).

## [0.4.0] - 2023-03-10
### Added
- Configuration option `build_tools` which allows selection of one's preferred build tool to run tests.
### Changed
- Improved and simplified Hspec test/namespace position discovery.
- Improved parsing of Hspec test results.
- Do not send a notification with Hspec `--match` expression.
### Fixed
- Run all top-level tests in tests of type `file` (#50).

## [0.3.0] - 2023-02-28
### Added
- Support for test files (See [#45](https://github.com/mrcjkb/neotest-haskell/issues/45)).
  Running `neotes.run.run(vim.api.nvim_buf_get_name)` will now run a single process for the top-level Hspec node.
- Support for simple cabal projects. These are projects with a single package and no `cabal.project` file.

## [0.2.2] - 2023-01-14
### Fixed
- Trims string ends from failed test results
- Packer init in minimal config for reproducing issues locally.

## [0.2.1] - 2022-10-29
### Fixed
- Virtual text not displayed if test name contains lua `match` special characters.
- Detect files ending in "Tests.hs" as test files

## [0.2.0] - 2022-10-12
### Added
- Stack support!
### Fixed
- Error message when running outside of test definitions.
- Virtual text not shown when cursor is on `it` or `prop` test.

## [0.1.1] - 2022-10-12
### Fixed
- [Whitespace of virtual text error messages not trimmed](https://github.com/MrcJkb/neotest-haskell/issues/13)
### Changed
- [Do not display full output as virtual text.](https://github.com/MrcJkb/neotest-haskell/issues/12).
  To display output, see `:h neotest.output.open()`.
- Run all tests if no package is found.
- Run tests without options if no (hspec) test options can be found.

## [0.1.0] - 2022-10-11
### Added
- Parse hspec test results and display error messages as virtual text.

## [0.0.3] - 2022-10-10
### Fixed
- Remove double-quotes from match argument, which caused hspec not to be able ot find any matches.

## [0.0.2] - 2022-09-25
### Changed
- Simplify generated cabal command to run `new-test` instead of `new-run`.
  Previously, the generated command would have looked like this:
  `cabal new-run <test-suite-name> -- -m "/path/to/hspec/branch/"`
  Now it looks like this:
  `cabal new-test <(sub)package-name> --test-argument -m --test-argument "/path/to/hspec/branch/"`
  The reason for this change is to make it Cabal's responsibility to ensure the correct tests are run if a package has more than one test suite.
  With the previous approach, it was possible to run the wrong test suite without any matches.
