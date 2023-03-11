# neotest-haskell

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)
![Haskell](https://img.shields.io/badge/Haskell-5e5086?style=for-the-badge&logo=haskell&logoColor=white)

[![Nix build](https://github.com/MrcJkb/neotest-haskell/actions/workflows/nix-build.yml/badge.svg)](https://github.com/MrcJkb/neotest-haskell/actions/workflows/nix-build.yml)

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-3-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

A [Neotest](https://github.com/nvim-neotest/neotest) adapter for Haskell.


## Quick links
- [Features](#featues)
- [Installation](#installation)
- [Configuration](#configuration)
- [Examples](#examples)
- [TODO](#todo)
- [Troubleshooting](#troubleshooting)
- [Recommendations](#recommendations)


## Features

* Supports [Cabal](https://www.haskell.org/cabal/) (single/multi-package) projects.
* Supports [Stack](https://docs.haskellstack.org/en/stable/) (single/multi-package) projects.
* Parses [Hspec](https://hackage.haskell.org/package/hspec) `--match` filters for the cursor's position using tree-sitter.
* Parses Hspec test results and displays error messages as virtual text.

https://user-images.githubusercontent.com/12857160/224197351-8ca64bd5-8d89-4689-8c40-18d1d018896e.mp4


## Installation

See also: [neotest installation instructions](https://github.com/nvim-neotest/neotest#installation).

* Requires [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) and the parser for haskell.

The following example uses [`packer.nvim`](https://github.com/wbthomason/packer.nvim):

```lua
use({
  'nvim-neotest/neotest',
  requires = {
    -- ...,
    'mrcjkb/neotest-haskell',
    'nvim-treesitter/nvim-treesitter',
    'nvim-lua/plenary.nvim',
  }
})
```


## Configuration

Make sure the Haskell parser for tree-sitter is installed:

```lua
require('nvim-treesitter.configs').setup {
  ensure_installed = {
    'haskell',
    --...,
  },
}
```

Add `neotest-haskell` to your `neotest` adapters:

```lua
require('neotest').setup {
  -- ...,
  adapters = {
    -- ...,
    require('neotest-haskell') {
      -- Default: Use stack if possible and then try cabal
      build_tools = { 'stack', 'cabal' },
    },
  }
}
```
> **Note**
>
> If you were to use `build_tools = { 'cabal', 'stack' }`, then cabal will almost
> always be chosen, because almost all stack projects can be built with cabal.


## Examples

### Hspec

```haskell
module FixtureSpec ( spec ) where
import Test.Hspec
import Test.Hspec.QuickCheck
import Control.Exception ( evaluate )

spec :: Spec
spec = describe "Prelude.head" $ do
  it "returns the first element of a list" $ head [23 ..] `shouldBe` (23 :: Int)

  prop "returns the first element of an *arbitrary* list" $ \x xs ->
    head (x : xs) `shouldBe` (x :: Int)

  describe "Empty list" $
    it "throws an exception if used with an empty list"
      $             evaluate (head [])
      `shouldThrow` anyException
```

In the above listing, calling `:lua require('neotest').run.run()`
with the cursor on the line...
```haskell
  describe "Empty list" $
```
...will run the tests with the following Cabal command:

```console
# Assuming a Cabal package called "my_package"
cabal test my_package --test-option -m --test-option "/Prelude.head/Empty list/"
```
...or with the following Stack command:

```console
# Assuming a Stack package called "my_package"
stack test my_package --ta "--match \"/Prelude.head/Empty list/\""
```
...which will run the `"throws an exception if used with an empty list"` test.

Calling `:lua require('neotest').run.run()`
with the cursor on the line...
```haskell
spec = describe "Prelude.head" $ do
```
...will run the tests with the following Cabal command:

```console
# Assuming a Cabal package called "my_package"
cabal test my_package --test-option -m --test-option "/Prelude.head/"
```
...or with the following Stack command:

```console
# Assuming a Stack package called "my_package"
stack test my_package --ta "--match \"/Prelude.head/\""
```
...which will run all tests in the module.


## TODO

### Cabal support

- [x] Run cabal v2 tests with Hspec
- [x] Support both single + multi-package cabal v2 projects
- [x] Support cabal v2 projects with more than one test suite per package
- [x] Parse cabal v2 Hspec test results


### Stack support

- [x] Run stack tests with Hspec
- [x] Support both single + multi-package stack projects
- [x] Support stack projects with more than one test suite per package
- [x] Parse stack Hspec test results


### Testing frameworks

- [x] [hspec](https://hackage.haskell.org/package/hspec)
- [ ] [tasty](https://hackage.haskell.org/package/tasty)
- [ ] [sydtest](https://github.com/NorfairKing/sydtest)
- [ ] [yesod-test](https://hackage.haskell.org/package/yesod-test)
- [ ] Extract interface so that users can add their own adapters

### Other
- [ ] Provide `nvim-dap` configuration


## Troubleshooting

To run a health check, run `:checkhealth neotest-haskell` in Neovim.


## Recommendations

Here are some other plugins I recommend for Haskell development:

* [mrcjkb/haskell-tools.nvim](https://github.com/MrcJkb/haskell-tools.nvim): Toolset to improve the Haskell experience in Neovim
* [luc-tielen/telescope_hoogle](https://github.com/luc-tielen/telescope_hoogle): Hoogle search


## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Trouble-Truffle"><img src="https://avatars.githubusercontent.com/u/90542764?v=4?s=100" width="100px;" alt="Perigord"/><br /><sub><b>Perigord</b></sub></a><br /><a href="https://github.com/mrcjkb/neotest-haskell/commits?author=Trouble-Truffle" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/saep"><img src="https://avatars.githubusercontent.com/u/1560366?v=4?s=100" width="100px;" alt="Sebastian Witte"/><br /><sub><b>Sebastian Witte</b></sub></a><br /><a href="https://github.com/mrcjkb/neotest-haskell/commits?author=saep" title="Code">💻</a> <a href="#infra-saep" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/mrcjkb/neotest-haskell/commits?author=saep" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/andy-bell101"><img src="https://avatars.githubusercontent.com/u/13719403?v=4?s=100" width="100px;" alt="Andy Bell"/><br /><sub><b>Andy Bell</b></sub></a><br /><a href="https://github.com/mrcjkb/neotest-haskell/commits?author=andy-bell101" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
