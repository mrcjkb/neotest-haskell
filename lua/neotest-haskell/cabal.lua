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

function M.build_command(package_root, hspec_match)
  logger.debug('Building spec for Cabal project...')
  local command = nil
  local package_file_path = get_package_file(package_root)
  local package_file_name = vim.fn.fnamemodify(package_file_path, ':t')
  local package_name = package_file_name:gsub('.cabal', '')
  if lib.files.exists(package_file_path) then
    command = vim.tbl_flatten({
      'cabal',
      'new-test',
      package_name,
      '--test-option',
      '-m',
      '--test-option',
      hspec_match,
    })
    vim.notify('neotest-haskell: cabal new-test ' .. package_name .. ' --test-option -m --test-option ' .. hspec_match, vim.log.levels.INFO)
  end
  return command
end

-- Get the error messages
local function get_hspec_errors(raw_lines, pos)
  local failures_found = false
  local pos_found = false
  local error_message = nil
  for _, line in ipairs(raw_lines) do
    local trimmed = line:match('^%s*(.*)')
    if pos_found and trimmed:match('To rerun use:') then
      return {{
        message = error_message,
      },}
    elseif pos_found then
      error_message = error_message and error_message .. '\n' .. line or line
    end
    if failures_found and trimmed:match('.*' .. pos) then
      pos_found = true
    elseif string.match(line, 'Failures:') then
      failures_found = true
    end
  end
  return {}
end

---@async
---@param context table: Spec context with the following fields:
--- - file: Absolute path to the test file
--- - pos_id: Postition ID of the test that was discovered - '<file>::"<test.name>"' [@see base.parse_positions]
--- - pos_path: Absolute path to the file containing the test (== file)
---@param out_path string: Path to cabal test results output file
---@return neotest.Result[]
function M.parse_results(context, out_path)
  local pos_id = context.pos_id
  local pos_path = context.pos_path
  local success, data = pcall(lib.files.read, out_path)
  if not success then
    vim.notify('Failed to read cabal output.', vim.log.levels.ERROR)
    return { [pos_id] = {
      status = 'failed',
    } }
  end
  local lines = vim.split(data, '\n')
  local failure_positions = {}
  local success_positions = {}
  for _, line in ipairs(lines) do
    -- XXX TODO: This seems to work, but seems like it might not be the most stable way to do this
    local failed = line:match('%s*(.*)%s.✘')
    local succeeded = line:match('%s*(.*)%s.✔')
    if failed then
      failure_positions[#failure_positions+1] = failed
    elseif succeeded then
      success_positions[#success_positions+1] = succeeded
    end
  end
  local result = { [pos_id] = {
    status = 'failed',
    errors = {
      {
        message = data,
      },
    },
  } }
  for _, pos in ipairs(failure_positions) do
    local failure = { [pos_path .. '::"' .. pos .. '"'] = {
        status = 'failed',
        errors = get_hspec_errors(lines, pos)
      },
    }
    result = vim.tbl_extend('keep', result, failure)
  end
  for _, pos in ipairs(success_positions) do
    local passed = { [pos_path .. '::"' .. pos .. '"'] = {
        status = 'passed',
      },
    }
    result = vim.tbl_extend('keep', result, passed)
  end
  return result
end

return M
