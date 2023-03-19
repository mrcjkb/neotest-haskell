local lib = require('neotest.lib')
local async = require('neotest.async')

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
  async.util.scheduler()
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

return treesitter
