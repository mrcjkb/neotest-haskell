---@alias build_tool 'cabal' | 'stack'

---@alias test_framework 'tasty' | 'hspec'

---@alias test_run_type "dir"|"file"|"namespace"|"test"
---@class RunContext
---@field file string
---@field pos_id string
---@field type test_run_type
---@field handler TestFrameworkHandler

---@class TestFrameworkHandler
---@field can_handle fun(file_path:string):boolean Function to check if the handler can handle the framework used in the test file.
---@field namespace_query string Tree-sitter query for namespace positions.
---@field test_query string Tree-sitter query for test positions.
---@field parse_positions fun(file_path:string):neotest.Tree Function that parses the positions in a test file.
---@field get_cabal_test_opts fun(pos:neotest.Position):string[] Function that constructs the options for a cabal test command.
---@field get_stack_test_opts fun(pos:neotest.Position):string[] Function that constructs the options for a stack test command.
---@field parse_results (fun(context:RunContext, out_path:string, tree:neotest.Tree): table<string, neotest.Result>)|nil Function for parsing the test results.
