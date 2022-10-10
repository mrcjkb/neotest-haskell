# neotest-haskell

**[WIP]** [Neotest](https://github.com/nvim-neotest/neotest) adapter for Haskell (cabal-v2 or stack with [Hspec](https://hackage.haskell.org/package/hspec))

## Status

* This test runner is still under early development, so there may be breaking changes.

## Features

* Supports cabal v2 (single/multi-package) projects.
* Parses hspec `--match` filters for the cursor's position using TreeSitter.
* Parses hspec (cabal v2) test results and displays error messages as virtual text.

![neotest-haskell](https://user-images.githubusercontent.com/12857160/194965194-a65d18b6-b6f7-48c1-bdde-a6831bf1b362.png)

## Configuration

* Requires [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) and the parser for haskell.
* Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use({
  "nvim-neotest/neotest",
  requires = {
    ...,
    "MrcJkb/neotest-haskell",
  }
  config = function()
    require("neotest").setup({
      ...,
      adapters = {
        ...,
        require("neotest-haskell"),
      }
    })
  end
})
```


## TODO

### Cabal support

- [x] Run cabal v2 tests with Hspec
- [x] Support both single + multi-package cabal v2 projects
- [x] Support cabal v2 projects with more than one test suite per package
- [x] Parse cabal v2 Hspec test results


### Stack support

- [ ] Run stack tests with Hspec
- [ ] Support both single + multi-package stack projects
- [ ] Support stack projects with more than one test suite per package
- [ ] Parse stack Hspec test results


### Further down the line

- [ ] Add support for [tasty](https://hackage.haskell.org/package/tasty)
- [ ] Provide `nvim-dap` configuration
