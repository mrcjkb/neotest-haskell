# neotest-haskell

A [Neotest](https://github.com/nvim-neotest/neotest) adapter for Haskell.

## Status

* This test runner is still under early development, so there may be breaking changes.

## Features

* Supports [Cabal v2](https://www.haskell.org/cabal/) (single/multi-package) projects.
* Supports [Stack](https://docs.haskellstack.org/en/stable/) (single/multi-package) projects.
* Parses [Hspec](https://hackage.haskell.org/package/hspec) `--match` filters for the cursor's position using TreeSitter.
* Parses Hspec test results and displays error messages as virtual text.

![neotest-haskell](https://user-images.githubusercontent.com/12857160/195435665-6ef3175e-039d-4473-a322-a51eefab0a27.png)

## Installation / Configuration
See also: [neotest installation instructions](https://github.com/nvim-neotest/neotest#installation).

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

Requires [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) and the parser for haskell.


```lua
use {
  'nvim-treesitter/nvim-treesitter',
  config = function()
    require('nvim-treesitter.configs').setup {
      ensure_installed = {
        'haskell',
        --...,
      },
      -- Automatically install missing parsers when entering buffer
      auto_install = true,
      -- ...,
    }
  end,
}
```

```lua
use({
  "nvim-neotest/neotest",
  requires = {
    -- ...,
    "MrcJkb/neotest-haskell",
  }
  config = function()
    require("neotest").setup({
      -- ...,
      adapters = {
        -- ...,
        require("neotest-haskell"),
      }
    })
    -- Suggested keymaps
    local opts = { noremap = true, }
    vim.keymap.set('n', '<leader>nr', function() require('neotest').run.run() end, opts)
    vim.keymap.set('n', '<leader>no', function() require('neotest').output.open() end, opts)
    vim.keymap.set('n', '<leader>ns', function() require('neotest').summary.toggle() end, opts)
  end
})

```

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

```sh
# Assuming a Cabal package called "my_package"
cabal new-run my_package --test-option -m --test-option "/Prelude.head/Empty list/"
```
...or with the following Stack command:

```sh
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

```sh
# Assuming a Cabal package called "my_package"
cabal new-run my_package --test-option -m --test-option "/Prelude.head/"
```
...or with the following Stack command:

```sh
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


### Further down the line

- [ ] Add support for [tasty](https://hackage.haskell.org/package/tasty)
- [ ] Provide `nvim-dap` configuration
