local util = {}

---Table mapping special characters in `string.match` to their escaped characters.
---@type table<string,string>
local lua_match_matches = {
  ['^'] = '%^',
  ['$'] = '%$',
  ['('] = '%(',
  [')'] = '%)',
  ['%'] = '%%',
  ['.'] = '%.',
  ['['] = '%[',
  [']'] = '%]',
  ['*'] = '%*',
  ['+'] = '%+',
  ['-'] = '%-',
  ['?'] = '%?',
  ['\0'] = '%z',
}

---Escape special string.match characters.
---@param str string
---@return string escaped_string
function util.escape(str)
  local escaped_string = str:gsub('.', lua_match_matches)
  return escaped_string
end

---Trim leading and trailing whitespace.
---@param str string
---@return string trimmed
function util.trim(str)
  return (str:match('^%s*(.*)') or str):gsub('%s*$', '')
end

return util
