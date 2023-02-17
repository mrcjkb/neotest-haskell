local lib = require('neotest.lib')

local base = {}

base.is_test_file = function(file_path)
  if not vim.endswith(file_path, '.hs') then
    return false
  end
  return vim.endswith(file_path, 'Spec.hs') or vim.endswith(file_path, 'Test.hs') or vim.endswith(file_path, 'Tests.hs')
end

base.filter_dir = function(name)
  return name ~= 'dist-newstile' and name ~= '.stack-work'
end

base.match_package_root_pattern = lib.files.match_root_pattern('*.cabal', 'package.yaml')

base.match_project_root_pattern = lib.files.match_root_pattern('cabal.project', 'stack.yaml')

return base
