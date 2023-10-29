local runner = require('neotest-haskell.runner')
local compat = require('neotest-haskell.compat')

local simple_cabal_hspec_test_file = 'tests/fixtures/hspec/cabal/simple/test/FirstSpec.hs'
local multi_package_cabal_hspec_test_file =
  'tests/fixtures/hspec/cabal/multi-package/subpackage1/test/Fix1/FixtureSpec.hs'
local simple_stack_hspec_test_file = 'tests/fixtures/hspec/stack/simple/test/FirstSpec.hs'
local simple_stack_hspec_test_file_only_package_yaml =
  'tests/fixtures/hspec/stack/simple-package-yaml/test/FirstSpec.hs'
local multi_package_stack_hspec_test_file =
  'tests/fixtures/hspec/stack/multi-package/subpackage1/test/Fix1/FixtureSpec.hs'
local multi_package_cabal_tasty_test_file = 'tests/fixtures/tasty/cabal/multi-package/tasty-pkg/test/Spec.hs'
local simple_cabal_sydtest_test_file = 'tests/fixtures/sydtest/cabal/simple/test/SydtestFixtureSpec.hs'

local hspec = require('neotest-haskell.hspec')
local tasty = require('neotest-haskell.tasty')
local sydtest = require('neotest-haskell.sydtest')

describe('runner', function()
  describe('select_framework', function()
    it(
      'selects hspec for hspec file',
      compat.with_timeout(function()
        assert.equals(
          hspec,
          runner.select_framework(multi_package_cabal_hspec_test_file, { 'sydtest', 'tasty', 'hspec' })
        )
      end)
    )
    it(
      'selects tasty for tasty file if tasty is specified before hspec',
      compat.with_timeout(function()
        assert.equals(
          tasty,
          runner.select_framework(multi_package_cabal_tasty_test_file, { 'sydtest', 'tasty', 'hspec' })
        )
      end)
    )
    it(
      'selects sydtest for sydtest file if sydtest is specified before hspec',
      compat.with_timeout(function()
        assert.equals(sydtest, runner.select_framework(simple_cabal_sydtest_test_file, { 'sydtest', 'tasty', 'hspec' }))
      end)
    )
    it(
      'errors for hspec file if hspec is not specified',
      compat.with_timeout(function()
        assert.errors(function()
          runner.select_framework(multi_package_cabal_hspec_test_file, { 'tasty' })
        end)
      end)
    )
    it(
      'can detect framework by qualified module name',
      compat.with_timeout(function()
        assert.equals(
          hspec,
          runner.select_framework(
            multi_package_cabal_hspec_test_file,
            { { framework = 'hspec', modules = { 'Fix1.FixtureSpec' } } }
          )
        )
      end)
    )
  end)

  describe('select_build_tool', function()
    describe('simple project without stack.yaml', function()
      it('uses cabal if it is in the list of build tools', function()
        local mk_command = runner.select_build_tool(hspec, simple_cabal_hspec_test_file, { 'stack', 'cabal' })
        local command = mk_command()
        assert.equals(command[1], 'cabal')
      end)
      it('throws if only stack is specified', function()
        assert.errors(function()
          runner.select_build_tool(hspec, simple_cabal_hspec_test_file, { 'stack' })
        end)
      end)
      it('throws if no build tool is specified', function()
        assert.errors(function()
          runner.select_build_tool(hspec, simple_cabal_hspec_test_file, {})
        end)
      end)
    end)

    describe('multi-package project without stack.yaml', function()
      it('uses cabal if it is in the list of build tools', function()
        local mk_command = runner.select_build_tool(hspec, multi_package_cabal_hspec_test_file, { 'stack', 'cabal' })
        local command = mk_command()
        assert.equals(command[1], 'cabal')
        assert.equals(command[3], 'subpackage1')
      end)
      it('throws if only stack is specified', function()
        assert.errors(function()
          runner.select_build_tool(hspec, multi_package_cabal_hspec_test_file, { 'stack' })
        end)
      end)
      it('throws if no build tool is specified', function()
        assert.errors(function()
          runner.select_build_tool(hspec, multi_package_cabal_hspec_test_file, {})
        end)
      end)
    end)

    describe('simple project with stack.yaml', function()
      it('uses stack if it is in the list of build tools before cabal', function()
        local mk_command = runner.select_build_tool(hspec, simple_stack_hspec_test_file, { 'stack', 'cabal' })
        local command = mk_command()
        assert.equals(command[1], 'stack')
      end)
      it('uses stack if it is the only build tool', function()
        local mk_command = runner.select_build_tool(hspec, simple_stack_hspec_test_file, { 'stack' })
        local command = mk_command()
        assert.equals(command[1], 'stack')
      end)
    end)
    it('throws if no build tool is specified', function()
      assert.errors(function()
        runner.select_build_tool(hspec, '.', {})
      end)
    end)

    describe('simple project with stack.yaml, package.yaml and no *.cabal', function()
      it('uses stack if it is in the list of build tools before cabal', function()
        local mk_command =
          runner.select_build_tool(hspec, simple_stack_hspec_test_file_only_package_yaml, { 'stack', 'cabal' })
        local command = mk_command()
        assert.equals(command[1], 'stack')
      end)
      it('uses stack if it is the only build tool', function()
        local mk_command = runner.select_build_tool(hspec, simple_stack_hspec_test_file_only_package_yaml, { 'stack' })
        local command = mk_command()
        assert.equals(command[1], 'stack')
      end)
    end)
    it('throws if no build tool is specified', function()
      assert.errors(function()
        runner.select_build_tool(hspec, '.', {})
      end)
    end)

    describe('multi-package project with stack.yaml', function()
      it('uses stack if it is in the list of build tools before cabal', function()
        local mk_command = runner.select_build_tool(hspec, multi_package_stack_hspec_test_file, { 'stack', 'cabal' })
        local command = mk_command()
        assert.equals(command[1], 'stack')
        assert.equals(command[3], 'subpackage1')
      end)
      it('uses stack if it is the only build tool', function()
        local mk_command = runner.select_build_tool(hspec, multi_package_stack_hspec_test_file, { 'stack' })
        local command = mk_command()
        assert.equals(command[1], 'stack')
      end)
    end)
    it('throws if no build tool is specified', function()
      assert.errors(function()
        runner.select_build_tool(hspec, '.', {})
      end)
    end)
  end)
end)
