local modrev = 'scm'
local specrev = '1'

local repo_url = 'https://github.com/mrcjkb/neotest-haskell'

rockspec_format = '3.0'
package = 'neotest-haskell'
version = modrev ..'-'.. specrev

description = {
  summary = 'Neotest adapter for Haskell (cabal or stack) with support for Sydtest, Hspec and Tasty',
  detailed = [[
Supports Cabal projects.
Supports Stack projects.
Parses Sydtest, Hspec and Tasty filters for the cursor's position using TreeSitter.
Parses test results and displays error messages as virtual text.]],
  labels = { 'haskell', 'hspec', 'neovim', 'neovim-plugin', 'sydtest', 'tasty', 'testing', 'treesitter' } ,
  homepage = 'https://github.com/mrcjkb/neotest-haskell',
  license = 'GPL-2.0'
}

dependencies = {
  'lua >= 5.1',
  'neotest',
  'tree-sitter-haskell',
}

test_dependencies = { 'nvim-nio', 'neotest', }

source = {
  url = repo_url:gsub('https', 'git')
}

build = {
  type = 'builtin',
  copy_directories = { 'doc', 'queries' } ,
}
