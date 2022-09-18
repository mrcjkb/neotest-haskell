local logger = require("neotest.logging")

local M = {}

function M.build_command(project_root, package_root, hspec_match)
  error("Stack not supported yet.") -- TODO
  logger.debug('Building spec for Stack project...')
  local is_subpackage = package_root ~= project_root
  local package_name = vim.fn.fnamemodify(package_root, ':t')
  local package_arg = is_subpackage and { package_name } or {}
  local command = vim.tbl_flatten({
    'stack',
    'test',
    package_arg,
    '--ta',
    '"--match \\"' .. hspec_match .. '\\"', -- FIXME
  })
  vim.notify('(async) Running: stack test ' .. package_arg .. ' --ta ' .. hspec_match)
  return command
end

---@async
---@param out_path string: Path to stack test results output file
---@return neotest.Result[]
function M.results(out_path)
  logger.debug("Stack not implemented yet.")
  return {}
end

return M
