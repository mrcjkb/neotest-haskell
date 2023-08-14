local lib = require('neotest.lib')

local ok, nio = pcall(require, 'nio')
if not ok then
  ---@diagnostic disable-next-line: undefined-field
  nio = require('neotest.async').util
end

local treesitter = {}

---@class FileRef
---@field file string

---@class FileContentRef
---@field content string

---@alias HaskellQuery FileRef | FileContentRef

---Parse a tree-sitter query from a Haskell file.
---@async
---@param query string|table
---@param source HaskellQuery The source
---@return (fun(): integer, table<integer,TSNode>, table): pattern id, match, metadata
function treesitter.iter_ts_matches(query, source)
  if source.file then
    source.content = lib.files.read(source.file)
  end
  local lang = require('nvim-treesitter.parsers').ft_to_lang('haskell')
  nio.scheduler()
  local lang_tree = vim.treesitter.get_string_parser(
    source.content,
    lang,
    -- Prevent neovim from trying to read the query from injection files
    { injections = { [lang] = '' } }
  )
  ---@type userdata
  local root = lib.treesitter.fast_parse(lang_tree):root()
  local normalised_query = lib.treesitter.normalise_query(lang, query)
  return normalised_query:iter_matches(root, source.content)
end

---Check if a source has any maches for a query.
---@async
---@param query string|table
---@param source HaskellQuery
---@return boolean has_matches
function treesitter.has_matches(query, source)
  for _, match in treesitter.iter_ts_matches(query, source) do
    if match then
      return true
    end
  end
  return false
end

---@param filename string
---@param read_quantifier string
local function safe_read(filename, read_quantifier)
  local file, err = io.open(filename, 'r')
  if not file then
    error(err)
  end
  local content = file:read(read_quantifier)
  file:close()
  return content
end

---@param filenames string[]
---@return string
local function read_query_files(filenames)
  local contents = {}
  for _, filename in ipairs(filenames) do
    table.insert(contents, safe_read(filename, '*a'))
  end
  return table.concat(contents, '')
end

---Get a tree-sitter query from the queries runtime path
---@param query_name string
---@return string query
local function get_query_string(query_name)
  local get_query_files = vim.treesitter.query.get_files
    ---@diagnostic disable-next-line: deprecated
    or vim.treesitter.query.get_query_files
  local query_files = get_query_files('haskell', query_name)
  return read_query_files(query_files)
end

---@param framework test_framework
---@return string query
function treesitter.get_position_query(framework)
  return get_query_string(framework .. '-positions')
end

return treesitter
