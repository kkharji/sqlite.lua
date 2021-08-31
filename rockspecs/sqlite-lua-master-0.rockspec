rockspec_format = "3.0"
package = "sqlite-lua"
version = "master-0"
source = {
  url = "git://github.com/tami5/sql.nvim",
  branch = "master",
}

dependencies = {
  "lua >= 5.1",
}

description = {
  detailed = "",
  homepage = "https://github.com/tami5/sqlite.lua",
  labels = { "sqlite3", "binding", "luajit" },
  license = "MIT",
  summary = "SQLite/LuaJIT binding and a highly opinionated wrapper for storing, retrieving, caching, and persisting [SQLite] databases",
}

build = {
  type = "builtin",
  modules = {
    ["sqlite.db"] = "/lua/sqlite/db.lua",
    ["sqlite.defs"] = "/lua/sqlite/defs.lua",
    ["sqlite.init"] = "/lua/sqlite/init.lua",
    ["sqlite.json"] = "/lua/sqlite/json.lua",
    ["sqlite.tbl"] = "/lua/sqlite/tbl.lua",
    ["sqlite.tbl.cache"] = "/lua/sqlite/tbl/cache.lua",
    ["sqlite.tbl.extend"] = "/lua/sqlite/tbl/extend.lua",
    ["sqlite.utils"] = "/lua/sqlite/utils.lua",
  },
}
