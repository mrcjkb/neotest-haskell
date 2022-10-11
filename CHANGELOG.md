# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
