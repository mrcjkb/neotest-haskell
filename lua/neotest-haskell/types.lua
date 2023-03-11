---@alias build_tool 'cabal' | 'stack'

---@alias test_run_type 'file' | 'test' | 'namespece' | 'dir'

---@class RunContext
---@field file string
---@field pos_id string
---@field type test_run_type
