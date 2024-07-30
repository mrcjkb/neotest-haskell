<!-- markdownlint-disable -->
<br />
<div align="center">
  <a href="https://github.com/mrcjkb/neotest-haskell">
    <img src="./logo.svg" alt="neotest-haskell">
  </a>
  <p align="center">
    <a href="https://github.com/mrcjkb/neotest-haskell/issues">Report Bug</a>
  </p>
  <p>
    <strong>
      A <a href="https://github.com/nvim-neotest/neotest">neotest</a> adapter for Haskell.
    </strong>
  </p>
  <p>🦥</p>

[![Neovim][neovim-shield]][neovim-url]
[![Lua][lua-shield]][lua-url]
[![Haskell][haskell-shield]][haskell-url]
[![Nix][nix-shield]][nix-url]

[![GPL2 License][license-shield]][license-url]
[![Issues][issues-shield]][issues-url]
[![Build Status][ci-shield]][ci-url]
[![LuaRocks][luarocks-shield]][luarocks-url]
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-9-purple.svg?style=for-the-badge)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->
</div>
<!-- markdownlint-restore -->

## Quick links

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Examples](#examples)
- [TODO](#todo)
- [Troubleshooting](#troubleshooting)
- [Recommendations](#recommendations)

## Features

- [x] Supports [Cabal](https://www.haskell.org/cabal/) (single/multi-package) projects.
- [x] Supports [Stack](https://docs.haskellstack.org/en/stable/)
      (single/multi-package) projects.
- [x] Parses [Hspec](https://hackage.haskell.org/package/hspec)
      and [Sydtest](https://hackage.haskell.org/package/sydtest)
      `--match` filters for the cursor's position using tree-sitter.
- [x] Parses [Tasty](https://hackage.haskell.org/package/tasty)
      `--pattern` filters for the cursor's position using tree-sitter.
- [x] Parses test results and displays error messages as diagnostics.

<!-- markdownlint-disable -->
https://user-images.githubusercontent.com/12857160/224197351-8ca64bd5-8d89-4689-8c40-18d1d018896e.mp4
<!-- markdownlint-restore -->

## Installation

### rocks.nvim

```vim
:Rocks install neotest-haskell
```

rocks.nvim will install all dependencies if not
already installed (including tree-sitter-haskell).

### Other plugin managers

See also: [neotest installation instructions](https://github.com/nvim-neotest/neotest#installation).

- Requires the tree-sitter parser for haskell to be installed.

The following example uses [`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
{
  'nvim-neotest/neotest',
  dependencies = {
    -- ...,
    'mrcjkb/neotest-haskell',
    'nvim-lua/plenary.nvim',
  }
}
```

## Configuration

Make sure the Haskell parser for tree-sitter is installed,
you can do so via [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter)
like so:

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
    require('neotest-haskell')
  },
}
```

You can also pass a config to the setup. The following are the defaults:

```lua
require('neotest').setup {
  adapters = {
    require('neotest-haskell') {
      -- Default: Use stack if possible and then try cabal
      build_tools = { 'stack', 'cabal' },
      -- Default: Check for tasty first and then try hspec
      frameworks = { 'tasty', 'hspec', 'sydtest' },
    },
  },
}
```

> [!NOTE]
>
> If you were to use `build_tools = { 'cabal', 'stack' }`, then cabal will almost
> always be chosen, because almost all stack projects can be built with cabal.

Alternately, you can pair each test framework with a list of modules,
used to identify the respective framework in a test file:

```lua
require('neotest').setup {
  adapters = {
    require('neotest-haskell') {
      frameworks = {
        { framework = 'tasty', modules = { 'Test.Tasty', 'MyTestModule' }, },
        'hspec',
        'sydtest',
      },
    },
  },
}
```

This can be useful if you have test files that do not import one of the default modules
used for framework identification:

- `tasty`: `modules = { 'Test.Tasty' }`
- `hspec`: `modules = { 'Test.Hspec' }`
- `sydtest`: `modules = { 'Test.Syd' }`

## Advanced configuration

This plugin uses tree-sitter queries in files that match
`<runtimepath>/queries/haskell/<framework>-positions.scm`

For example, to add position queries for this plugin for `tasty`, without
having to fork this plugin, you can add them to
`$XDG_CONFIG_HOME/nvim/after/queries/haskell/tasty-positions.scm`.

> [!NOTE]
>
> - `:h runtimepath`
> - See examples in [`queries/haskell/`](./queries/haskell/).

## Examples

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

See [issues](https://github.com/mrcjkb/neotest-haskell/issues).

## Troubleshooting

To run a health check, run `:checkhealth neotest-haskell` in Neovim.

## Limitations

- To run `sydtest` tests of type `'file'`, `sydtest >= 0.13.0.4` is required,
  if the file has more than one top-level namespace (`describe`, `context`, ..).

## Recommendations

Here are some other plugins I recommend for Haskell development:

- [mrcjkb/haskell-tools.nvim](https://github.com/mrcjkb/haskell-tools.nvim):
  Toolset to improve the Haskell experience in Neovim.
- [haskell-snippets.nvim](https://github.com/mrcjkb/haskell-snippets.nvim)
  Collection of Haskell snippets for [LuaSnip](https://github.com/L3MON4D3/LuaSnip).
- [luc-tielen/telescope_hoogle](https://github.com/luc-tielen/telescope_hoogle):
  Hoogle search.

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
      <td align="center" valign="top" width="14.28%"><a href="http://cs-syd.eu"><img src="https://avatars.githubusercontent.com/u/3521180?v=4?s=100" width="100px;" alt="Tom Sydney Kerckhove"/><br /><sub><b>Tom Sydney Kerckhove</b></sub></a><br /><a href="#mentoring-NorfairKing" title="Mentoring">🧑‍🏫</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/shinzui"><img src="https://avatars.githubusercontent.com/u/519?v=4?s=100" width="100px;" alt="Nadeem Bitar"/><br /><sub><b>Nadeem Bitar</b></sub></a><br /><a href="https://github.com/mrcjkb/neotest-haskell/issues?q=author%3Ashinzui" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/MangoIV"><img src="https://avatars.githubusercontent.com/u/40720523?v=4?s=100" width="100px;" alt="Mango The Fourth"/><br /><sub><b>Mango The Fourth</b></sub></a><br /><a href="https://github.com/mrcjkb/neotest-haskell/issues?q=author%3AMangoIV" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://glitchbra.in"><img src="https://avatars.githubusercontent.com/u/29253044?v=4?s=100" width="100px;" alt="Hécate Moonlight"/><br /><sub><b>Hécate Moonlight</b></sub></a><br /><a href="https://github.com/mrcjkb/neotest-haskell/issues?q=author%3AKleidukos" title="Bug reports">🐛</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/amaanq"><img src="https://avatars.githubusercontent.com/u/29718261?v=4?s=100" width="100px;" alt="Amaan Qureshi"/><br /><sub><b>Amaan Qureshi</b></sub></a><br /><a href="https://github.com/mrcjkb/neotest-haskell/commits?author=amaanq" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://bitsbybrad.com"><img src="https://avatars.githubusercontent.com/u/15267511?v=4?s=100" width="100px;" alt="Brad Sherman"/><br /><sub><b>Brad Sherman</b></sub></a><br /><a href="https://github.com/mrcjkb/neotest-haskell/commits?author=bradsherman" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors)
specification. Contributions of any kind welcome!

<!-- MARKDOWN LNIKS & IMAGES -->
<!-- markdownlint-disable -->
[neovim-shield]: https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white
[neovim-url]: https://neovim.io/
[lua-shield]: https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white
[lua-url]: https://www.lua.org/
[nix-shield]: https://img.shields.io/badge/nix-0175C2?style=for-the-badge&logo=NixOS&logoColor=white
[nix-url]: https://nixos.org/
[haskell-shield]: https://img.shields.io/badge/Haskell-5e5086?style=for-the-badge&logo=haskell&logoColor=white
[haskell-url]: https://www.haskell.org/
[issues-shield]: https://img.shields.io/github/issues/mrcjkb/neotest-haskell.svg?style=for-the-badge
[issues-url]: https://github.com/mrcjkb/neotest-haskell/issues
[license-shield]: https://img.shields.io/github/license/mrcjkb/neotest-haskell.svg?style=for-the-badge
[license-url]: https://github.com/mrcjkb/neotest-haskell/blob/master/LICENSE
[ci-shield]: https://img.shields.io/github/actions/workflow/status/mrcjkb/neotest-haskell/nix-build.yml?style=for-the-badge
[ci-url]: https://github.com/mrcjkb/neotest-haskell/actions/workflows/nix-build.yml
[luarocks-shield]: https://img.shields.io/luarocks/v/MrcJkb/neotest-haskell?logo=lua&color=purple&style=for-the-badge
[luarocks-url]: https://luarocks.org/modules/MrcJkb/neotest-haskell
