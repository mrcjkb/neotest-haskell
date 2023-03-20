local runner = require('neotest-haskell.runner')

local validate = {}

---@param x any
---@return boolean
local function is_list_of_strings(x)
  return x ~= nil and type(x) == 'table' and #x > 0 and type(x[1]) == 'string'
end

---@param bts build_tool[] | nil
---@return boolean
local function validate_build_tools(bts)
  if not bts then
    return true
  end
  if #bts == 0 then
    return false
  end
  for _, build_tool in pairs(bts) do
    if not vim.tbl_contains(runner.supported_build_tools, build_tool) then
      return false
    end
  end
  return true
end

---@param fws framework_opt[]
---@return boolean
local function validate_frameworks(fws)
  if not fws then
    return true
  end
  if #fws == 0 then
    return false
  end
  for _, fw in pairs(fws) do
    if type(fw) == 'string' then
      ---@cast fw test_framework
      if not vim.tbl_contains(runner.supported_frameworks, fw) then
        return false
      end
    else
      ---@cast fw FrameworkSpec
      if not is_list_of_strings(fw.modules) then
        return false
      end
      if not fw.framework or not vim.tbl_contains(runner.supported_frameworks, fw.framework) then
        return false
      end
    end
  end
  return true
end

---@param opts table
function validate.validate(opts)
  vim.validate {
    build_tools = {
      opts.build_tools,
      validate_build_tools,
      'at least one of ' .. table.concat(runner.supported_build_tools, ', '),
    },
    frameworks = {
      opts.frameworks,
      validate_frameworks,
      'List of frameworks or framework specs (supported frameworks: '
        .. table.concat(runner.supported_frameworks, ', ')
        .. ')',
    },
  }
end

return validate
