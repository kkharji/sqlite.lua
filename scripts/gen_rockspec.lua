local scandir = require("plenary.scandir").scan_dir
local job = require "plenary.job"
local uv = vim.loop or require "luv"
local cwd = uv.cwd()
local ins = vim.inspect
local c = function(l)
  return table.concat(l, ",\n")
end

local version = uv.os_getenv "GTAG" or "master"
local modules = {}
local description = {
  summary = "SQLite/LuaJIT binding and a highly opinionated wrapper for storing, retrieving, caching, and persisting [SQLite] databases",
  homepage = "https://github.com/kkharji/sqlite.lua",
  labels = { "sqlite3", "binding", "luajit", "database" },
  detailed = "",
  license = "MIT",
}

local dependencies = {
  "luv",
}

--- Format Dependencies -----------------------------------
for i, v in ipairs(dependencies) do
  dependencies[i] = vim.inspect(v)
end
dependencies = c(dependencies)

--- Format modules ----------------------------------------
for _, v in ipairs(scandir(cwd, { search_pattern = "/lua/sqlite/[^examples]" })) do
  local path = v:gsub(cwd .. "/", "")
  local module = path:gsub("/", "%."):gsub(".lua.(.-).lua", "%1")
  modules[module] = path
end

local output = ([[
rockspec_format = "3.0"
package = 'sqlite'
version = '%s-0'
description = %s
source = {
  url = 'git://github.com/kkharji/sqlite.lua.git',
  tag = "%s"
}
dependencies = {
  %s
}
build = {
  type = "builtin",
  modules = %s
}
test = {
	type = "command",
	command = "make test"
}
test_dependencies = {
	"plenary.nvim"
}
]]):format(version, ins(description), version, dependencies, ins(modules))

local file_handle = io.open(("%s/sqlite-%s-0.rockspec"):format(cwd, version), "w")

file_handle:write(output)
file_handle:close()

vim.cmd [[checktime]]
