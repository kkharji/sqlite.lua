local scandir = require("plenary.scandir").scan_dir
local job = require "plenary.job"
local uv = vim.loop or require "luv"
local cwd = uv.cwd()
local ins = vim.inspect
local c = function(l)
  return table.concat(l, ",\n")
end

local version = ""
local modules = {}
local description = {
  summary = "SQLite/LuaJIT binding and a highly opinionated wrapper for storing, retrieving, caching, and persisting [SQLite] databases",
  homepage = "https://github.com/tami5/sqlite.lua",
  labels = { "sqlite3", "binding", "luajit" },
  detailed = "",
  license = "MIT",
}

local dependencies = {
  "lua >= 5.1",
}

--- Format Dependencies -----------------------------------
for i, v in ipairs(dependencies) do
  dependencies[i] = vim.inspect(v)
end
dependencies = c(dependencies)

--- Format modules ----------------------------------------
for _, v in ipairs(scandir(cwd, { search_pattern = "/lua/sqlite/[^examples]" })) do
  local path = v:gsub(cwd, "")
  local module = path:gsub("/", "%."):gsub(".lua.(.-).lua", "%1")
  modules[module] = path
  -- modules[#modules + 1] = ('  ["%s"] = "%s"'):format(module, path)
end
-- modules = c(modules)

--- Get last version tag ----------------------------------
job
  :new({ -- git name-rev --tags --name-only $(git rev-parse HEAD)
    "git",
    "describe",
    "--tags",
    "--abbrev=0",
    on_exit = function(j, c)
      if c ~= 0 then
        os.exit(1, true)
      end
      version = j:result()[1]
    end,
  })
  :sync()

local output = ([[
rockspec_format = "3.0"
package = 'sqlite.lua'
version = '%s-0'
source = {
  url = 'git://github.com/tami5/sqlite.lua.git',
  tag = "%s"
}

dependencies = {
  %s
}

description = %s

build = {
  type = "builtin",
  modules = %s
}

]]):format(version, version, dependencies, ins(description), ins(modules))

local file_handle = io.open(("%s/rockspecs/sqlite-lua-%s-0.rockspec"):format(cwd, version), "w")

file_handle:write(output)
file_handle:close()

vim.cmd [[checktime]]
