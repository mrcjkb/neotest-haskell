-- NOTE: This rockspec is used for running busted tests only,
-- not for publishing to LuaRocks.org

local _MODREV, _SPECREV = 'scm', '-1'
rockspec_format = '3.0'
package = 'neotest-haskell'
version = _MODREV .. _SPECREV

dependencies = {
  'lua >= 5.1',
  -- 'neotest', TODO: neotest hasn't been packaged yet
}

test_dependencies = {
  'lua >= 5.1',
  -- 'neotest',
  'busted',
}

source = {
  url = 'git://github.com/mrcjkb/' .. package,
}

build = {
  type = 'builtin',
  copy_directories = { 
    'doc',
    'queries',
  },
}
