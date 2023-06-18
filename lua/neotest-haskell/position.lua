local lib = require('neotest.lib')

local position = {}

---@param tree neotest.Tree
---@param pos_id string
---@return boolean
function position.has_position(tree, pos_id)
  for _, node in tree:iter_nodes() do
    local data = node:data()
    if data.id == pos_id then
      return true
    end
  end
  return false
end

---Convenience wrapper around neotest.lib.treesitter.parse_positions.
---@async
---@param path string Test file path
---@param query string tree-sitter query
---@param opts table? parse options
---@return neotest.Tree positions
position.parse_positions = function(path, query, opts)
  opts = vim.tbl_extend('keep', opts or {}, { nested_namespaces = true, nested_tests = false })
  return lib.treesitter.parse_positions(path, query, opts)
end

---Format a test or namespace name for use in a filter expression.
---@param name string The test or namespace name to format.
---@return string formatted_name
function position.format_name(name)
  -- TODO: Escape '/' characters?
  local formatted_name = name:gsub('"', '')
  return formatted_name
end

---@alias result any
---@alias concatenated_result any

---@param prepend_result fun(rs:result[], r:result):result[]
---@param concat_results fun(rs:result[]):concatenated_result
---@return fun(pos:neotest.Tree):concatenated_result
function position.mk_top_level_node_parser(prepend_result, concat_results)
  return function(pos)
    local results = {}
    local prepended = {}
    for _, node in pos:iter_nodes() do
      local data = node:data()
      local parent = node:parent()
      local parent_data = parent and parent:data()
      local is_top_level = not parent_data or parent_data.type == 'file'
      local is_new = not vim.tbl_contains(prepended, data.name)
      if is_top_level and is_new then
        table.insert(prepended, data.name)
        results = prepend_result(results, data.name)
      end
    end
    return concat_results(results)
  end
end

---@param format_position_name fun(name:string):string
---@param format_result fun(res:string):string
---@param prepend_position fun(result:string, position:string):string
---@return fun(post:neotest.Tree):string tree_parser Function for parsing the filter expression from a test or namespace position.
function position.mk_test_tree_parser(format_position_name, format_result, prepend_position)
  return function(pos)
    local data = pos:data()
    local result = format_position_name(data.name)
    for parent in pos:iter_parents() do
      if not parent then
        return result
      end
      local parent_data = parent:data()
      if parent_data.type ~= 'namespace' then
        return format_result(result)
      end
      result = prepend_position(result, format_position_name(parent_data.name))
    end
    return format_result(result)
  end
end

return position
