---@alias build_tool 'cabal' | 'stack'

-- XXX: Below: Neotest types (copied from Neotest)
-- TODO: Use neotest as nix flake input and add it to .luarc.json

---@class neotest.Position
---@field id string
---@field type "dir"|"file"|"namespace"|"test"
---@field name string
---@field path string
---@field range integer[]

---@class neotest.Result
---@field status "passed"|"failed"|"skipped"
---@field output? string Path to file containing full output data
---@field short? string Shortened output string
---@field errors? neotest.Error[]

---@class neotest.Error
---@field message string
---@field line? integer

---@class neotest.Process
---@field output async fun(): string Path to file containing output data
---@field is_complete fun() boolean Is process complete
---@field result async fun() integer Get result code of process (async)
---@field attach async fun() Attach to the running process for user input
---@field stop async fun() Stop the running process
---@field output_stream async fun(): async fun(): string Async iterator of process output

---@alias neotest.Strategy async fun(spec: neotest.RunSpec): neotest.Process

---@class neotest.StrategyResult
---@field code integer
---@field output string

---@class neotest.RunArgs
---@field tree neotest.Tree
---@field extra_args? string[]
---@field strategy string

---@class neotest.RunSpec
---@field command string[]
---@field env? table<string, string>
---@field cwd? string
---@field context? table Arbitrary data to preserve state between running and result collection
---@field strategy? table Arguments for strategy
---@field stream fun(output_stream: fun(): string[]): fun(): table<string, neotest.Result>