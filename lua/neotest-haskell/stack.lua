local hspec = require('neotest-haskell.hspec')
local logger = require('neotest.logging')

local M = {}

---@async
function M.build_command(project_root, package_root, pos)
  logger.debug('Building spec for Stack project...')
  local command = {
    'stack',
    'test',
  }
  local is_subpackage = package_root ~= project_root
  local package_name = vim.fn.fnamemodify(package_root, ':t')
  if is_subpackage then
    table.insert(command, package_name)
  end
  local test_opts = hspec.get_stack_test_opts(pos)
  return test_opts and vim.list_extend(command, test_opts) or command
end

---@async
function M.parse_results(context, out_path)
  return hspec.parse_results(context, out_path)
end

return M
