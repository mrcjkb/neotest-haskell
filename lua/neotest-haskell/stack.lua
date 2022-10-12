local hspec = require('neotest-haskell.hspec')
-- local logger = require("neotest.logging")

local M = {}

function M.build_command(project_root, package_root, pos)
  error("neotest-haskell: Stack not supported yet.") -- TODO
  -- logger.debug('Building spec for Stack project...')
  -- local is_subpackage = package_root ~= project_root
  -- local package_name = vim.fn.fnamemodify(package_root, ':t')
  -- local package_arg = is_subpackage and { package_name } or {}
  -- local command = vim.tbl_flatten({
  --   'stack',
  --   'test',
  --   package_arg,
  --   '--ta',
  --   '"--match \\"' .. hspec_match .. '\\"', -- FIXME
  -- })
  -- vim.notify('(async) Running: stack test ' .. package_arg .. ' --ta ' .. hspec_match)
  -- return command
end

---@async
function M.parse_results(context, out_path)
  return hspec.parse_results(context, out_path)
end

return M
