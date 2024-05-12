local git_ref = 'e29c59236283198d93740a796c50d1394bccbef5'
local modrev = 'scm'
local specrev = '1'

local repo_url = 'https://github.com/tree-sitter/tree-sitter-haskell'

rockspec_format = '3.0'
package = 'tree-sitter-haskell'
version = modrev ..'-'.. specrev

description = {
  summary = 'tree-sitter parser and Neovim queries for haskell',
  labels = { 'neovim', 'tree-sitter' } ,
  homepage = 'https://github.com/tree-sitter/tree-sitter-haskell',
  license = 'MIT'
}

build_dependencies = {
  'luarocks-build-treesitter-parser >= 1.3.0',
}

source = {
  url = repo_url .. '/archive/' .. git_ref .. '.zip',
  dir = 'tree-sitter-haskell-' .. 'e29c59236283198d93740a796c50d1394bccbef5',
}

build = {
  type = "treesitter-parser",
  lang = "haskell",
  sources = { "src/parser.c", "src/scanner.c" },
}
