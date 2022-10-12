local hspec = require('neotest-haskell.hspec')
local util = require('neotest-haskell.util')
local async = require('neotest.async')
local lib = require('neotest.lib')
local logger = require("neotest.logging")
local Path = require('plenary.path')

local M = {}

local function get_package_file(package_root)
  for _, package_file_path in ipairs(async.fn.glob(Path:new(package_root, '*.cabal').filename, true, true)) do
    return package_file_path
  end
end

function M.build_command(package_root, pos)
  logger.debug('Building spec for Cabal project...')
  local command = {
    'cabal',
    'new-test',
  }
  local package_file_path = get_package_file(package_root)
  local package_file_name = vim.fn.fnamemodify(package_file_path, ':t')
  local package_name = package_file_name:gsub('.cabal', '')
  if lib.files.exists(package_file_path) then
    table.insert(command, package_name)
  else
    table.insert(command, 'all')
  end
  local test_opts = hspec.get_cabal_test_opts(pos)
  return test_opts
    and vim.list_extend(command, test_opts)
    or command
end

function M.parse_results(context, out_path)
  return hspec.parse_results(context, out_path)
end

return M
