rockspec_format = "3.0"
package = 'sqlite.lua'
version = 'scm-1'
description = {
  detailed = "",
  homepage = "https://github.com/tami5/sqlite.lua",
  labels = { "sqlite3", "binding", "luajit", "database" },
  license = "MIT",
  summary = "SQLite/LuaJIT binding and a highly opinionated wrapper for storing, retrieving, caching, and persisting [SQLite] databases"
}
source = {
  url = 'git://github.com/tami5/sqlite.lua.git',
  tag = "master"
}
dependencies = {
  "plenary.nvim"
}
build = {
  type = "builtin",
  modules = {
  ["lua.sqlite.db.lua"] = "lua/sqlite/db.lua",
  ["lua.sqlite.defs.lua"] = "lua/sqlite/defs.lua",
  ["lua.sqlite.helpers.lua"] = "lua/sqlite/helpers.lua",
  ["lua.sqlite.init.lua"] = "lua/sqlite/init.lua",
  ["lua.sqlite.json.lua"] = "lua/sqlite/json.lua",
  ["lua.sqlite.tbl.cache.lua"] = "lua/sqlite/tbl/cache.lua",
  ["lua.sqlite.tbl.extend.lua"] = "lua/sqlite/tbl/extend.lua",
  ["lua.sqlite.tbl.lua"] = "lua/sqlite/tbl.lua",
  ["lua.sqlite.utils.lua"] = "lua/sqlite/utils.lua"
}
}
test = {
	type = "command",
	command = "make test"
}


