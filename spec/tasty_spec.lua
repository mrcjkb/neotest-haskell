vim.env.PLENARY_TEST_TIMEOUT = 60000
vim.opt.runtimepath:append(vim.env.NEOTEST_HASKELL_DEV_DIR)
vim.opt.runtimepath:append(vim.env.TREE_SITTER_HASKELL_DIR)
vim.opt.runtimepath:append(vim.env.PLENARY_DIR)

local tasty = require('neotest-haskell.tasty')
local compat = require('neotest-haskell.compat')
local has_position = require('neotest-haskell.position').has_position
local async = require('nio').tests

local test_cwd = vim.fn.getcwd()

local function assert_has_position(tree, pos_id)
  assert(has_position(tree, pos_id), 'Position ' .. pos_id .. ' not found in tree ' .. vim.inspect(tree))
end

local parse_positions = tasty.parse_positions

local test_file = compat.joinpath(test_cwd, 'spec/fixtures/tasty/cabal/multi-package/tasty-pkg/test/Spec.hs')
local test_filename = test_file

describe('tasty', function()
  async.it('parse positions', function()
    local result = parse_positions(test_filename)
    local file_pos_id = test_filename
    assert_has_position(result, file_pos_id)
    local smallcheck_ns = test_filename .. '::"(checked by SmallCheck)"'
    assert_has_position(result, smallcheck_ns)
    assert_has_position(result, smallcheck_ns .. '::"sort == sort . reverse"')
    assert_has_position(result, smallcheck_ns .. '::"Fermat\'s little theorem"')
    assert_has_position(result, smallcheck_ns .. '::"Fermat\'s last theorem"')
    local quickcheck_ns = test_filename .. '::"(checked by QuickCheck)"'
    assert_has_position(result, quickcheck_ns)
    assert_has_position(result, quickcheck_ns .. '::"sort == sort . reverse"')
    assert_has_position(result, quickcheck_ns .. '::"Fermat\'s little theorem"')
    assert_has_position(result, quickcheck_ns .. '::"Fermat\'s last theorem"')
    local unit_ns = test_filename .. '::"Unit tests"'
    assert_has_position(result, unit_ns)
    assert_has_position(result, unit_ns .. '::"List comparison (different length)"')
    assert_has_position(result, unit_ns .. '::"List comparison (same length)"')
    local hspec_ns = test_filename .. '::"Hspec specs"'
    assert_has_position(result, hspec_ns)
    assert_has_position(result, hspec_ns .. '::"Prelude.head"')
    assert_has_position(result, hspec_ns .. '::"Prelude.head"::"returns the first element of a list"')
    local hedgehog_ns = test_filename .. '::"Hedgehog tests"'
    assert_has_position(result, hedgehog_ns)
    assert_has_position(result, hedgehog_ns .. '::"reverse involutive"')
    assert_has_position(result, hedgehog_ns .. '::"badReverse involutive fails"')
    local leancheck_ns = test_filename .. '::"LeanCheck tests"'
    assert_has_position(result, leancheck_ns)
    assert_has_position(result, leancheck_ns .. '::"sort == sort . reverse"')
    assert_has_position(result, leancheck_ns .. '::"Fermat\'s little theorem"')
    assert_has_position(result, leancheck_ns .. '::"Fermat\'s last theorem"')
    local program_ns = test_filename .. '::"Compilation with GHC"'
    assert_has_position(result, program_ns)
    assert_has_position(result, program_ns .. '::"Foo"')
    local wai_ns = test_filename .. '::"Tasty-Wai Tests"'
    assert_has_position(result, wai_ns)
    assert_has_position(result, wai_ns .. '::"Hello to World"')
    assert_has_position(result, wai_ns .. '::"Echo to thee"')
    assert_has_position(result, wai_ns .. '::"Echo to thee (json)"')
    assert_has_position(result, wai_ns .. '::"Will die!"')
    local golden_ns = test_filename .. '::"Golden tests"'
    assert_has_position(result, golden_ns)
    assert_has_position(result, golden_ns .. '::"goldenVsFile"')
    assert_has_position(result, golden_ns .. '::"goldenVsString"')
    assert_has_position(result, golden_ns .. '::"goldenVsFileDiff"')
    assert_has_position(result, golden_ns .. '::"goldenVsStringDiff"')
  end)

  describe('parse results', function()
    async.it('test failure', function()
      local tree = parse_positions(test_filename)
      local test_result_file = compat.joinpath(test_cwd, 'spec/fixtures/results/tasty_test_file_fail.txt')
      local result_filename = test_result_file
      local context = {
        file = test_filename,
        pos_id = test_filename,
        type = 'file',
      }
      local results = tasty.parse_results(context, result_filename, tree)
      assert.same('failed', results[test_filename].status)
      assert.same({
        status = 'passed',
      }, results[test_filename .. '::"(checked by SmallCheck)"::"sort == sort . reverse"'])
      assert.same({
        status = 'passed',
      }, results[test_filename .. '::"(checked by SmallCheck)"::"Fermat\'s little theorem"'])
      assert.same({
        status = 'failed',
        errors = {
          {
            message = 'there exist 0 0 0 3 such that\ncondition is false',
          },
        },
      }, results[test_filename .. '::"(checked by SmallCheck)"::"Fermat\'s last theorem"'])
      assert.same({
        status = 'passed',
      }, results[test_filename .. '::"(checked by QuickCheck)"::"Fermat\'s little theorem"'])
      assert.same('failed', results[test_filename .. '::"Hedgehog tests"::"badReverse involutive fails"'].status)
      assert.same({
        status = 'passed',
      }, results[test_filename .. '::"Hedgehog tests"::"reverse involutive"'])
      assert.same({
        status = 'skipped',
      }, results[test_filename .. '::"Hspec specs"::"Prelude.head"::"returns the first element of a list"'])
      assert.same({
        status = 'failed',
        errors = {
          {
            message = 'Program /run/current-system/sw/bin/ghc failed with code 1',
          },
        },
      }, results[test_filename .. '::"Compilation with GHC"::"Foo"'])
    end)
  end)
end)
