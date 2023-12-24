local results = {}

---Get the file root from a test tree.
---@param tree neotest.Tree The test tree.
---@return neotest.Tree file_root The file root position.
local function get_file_root(tree)
  for _, node in tree:iter_parents() do
    local data = node and node:data()
    if data and not vim.tbl_contains({ 'test', 'namespace' }, data.type) then
      return node
    end
  end
  return tree
end

---NOTE: The order of the `get_*_name` params is the order in which they are checked.
---
---@async
---@param parse_errors fun(raw_lines:string[], test_name:string):neotest.Error[]
---@param get_failed_name fun(line:string, lines:string[], idx:integer):string? Function to extract a failed test name
---@param get_succeeded_name fun(line:string, lines:string[], idx:integer):string? Function to extract a succeeded test name
---@param get_skipped_name fun(line:string, lines:string[], idx:integer):string? Function to extract a skipped test name
---@return fun(context:RunContext, out_path:string, tree:neotest.Tree):table<string,neotest.Result> result_parser
function results.mk_result_parser(parse_errors, get_failed_name, get_succeeded_name, get_skipped_name)
  local lib = require('neotest.lib')

  ---@param context RunContext The run context.
  ---@param out_path string Path to an hspec test results output file.
  ---@param tree neotest.Tree The test tree at the position that was run.
  ---@return table<string, neotest.Result> results
  return function(context, out_path, tree)
    ---@type table<string, neotest.Result>
    local result_tbl = {}

    ---Set the status of the test and maybe its parents.
    ---@param node neotest.Tree
    ---@param status string The neotest status
    ---@param errors neotest.Error[]? The errors in case of failure
    local function set_test_statuses(node, status, errors)
      local data = node:data()
      if data then
        result_tbl[data.id] = {
          status = status,
          errors = errors,
        }
        local parent = node:parent()
        if parent and context.type == 'file' then
          set_test_statuses(parent, status)
        end
      end
    end

    ---Set the status of the test and maybe its parents.
    ---@param test_name string The name of the test.
    ---@param status neotest.ResultStatus The neotest status.
    ---@param errors neotest.Error[]? The errors in case of failure.
    local function set_test_status(test_name, status, errors)
      test_name = '"' .. test_name .. '"'
      for _, node in get_file_root(tree):iter_nodes() do
        local data = node:data()
        if data and data.name == test_name and data.type == 'test' then
          set_test_statuses(node, status, errors)
        end
      end
    end

    local pos_id = context.pos_id
    local success, data = pcall(lib.files.read, out_path)
    if not success then
      return {}
    end
    local lines = vim.split(data, '\n') or {}
    local failure_positions = {}
    local success_positions = {}
    local skipped_positions = {}
    for idx, line in ipairs(lines) do
      local failed = get_failed_name(line, lines, idx)
      local succeeded = get_succeeded_name(line, lines, idx)
      local skipped = get_skipped_name(line, lines, idx)
      if failed then
        failure_positions[#failure_positions + 1] = failed
      elseif succeeded then
        success_positions[#success_positions + 1] = succeeded
      elseif skipped then
        skipped_positions[#skipped_positions + 1] = skipped
      end
    end

    ---@type neotest.Result
    local failed = { status = 'failed' }
    local skipped = { status = 'skipped' }
    local file_result = #failure_positions == 0 and #skipped_positions > 0 and skipped or failed
    file_result.errors = {}
    result_tbl[pos_id] = failed
    for _, test_name in ipairs(success_positions) do
      set_test_status(test_name, 'passed')
    end
    for _, test_name in ipairs(skipped_positions) do
      set_test_status(test_name, 'skipped')
    end
    for _, test_name in ipairs(failure_positions) do
      local errors = parse_errors(lines, test_name)
      set_test_status(test_name, 'failed', errors)
      vim.list_extend(file_result.errors, errors)
    end
    result_tbl[context.file] = file_result
    return result_tbl
  end
end

return results
