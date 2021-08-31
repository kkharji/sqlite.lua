---@brief [[
---SQLite/LuaJIT binding and highly opinionated wrapper for storing,
---retrieving, caching, persisting, querying, and connecting to SQLite databases.
---
--- To find out more
--- visit https://github.com/tami5/sqlite.lua
---<pre>
---
--- Help usage in neovim: ignore ||
---   :h |sqlite.readme|         | open help readme
---   :h |sqlite_schema_key|     | open a class or type
---   :h |sqlite.tbl|            | show help for sqlite_tbl.
---   :h |sqlite.db|             | show help for sqlite_tbl.
---   :h sqlite.db:...           | show help for a sqlite_db method.
---   :h sqlite.tbl:...          | show help for a sqlite_tbl method.
---
---</pre>
--- sqlite.lua types:
---@brief ]]
---@tag sqlite.readme

---@class sqlite_db @Main sqlite.lua object.
---@field uri string: database uri. it can be an environment variable or an absolute path. default ":memory:"
---@field opts sqlite_opts: see https://www.sqlite.org/pragma.html |sqlite_opts|
---@field conn sqlite_blob: sqlite connection c object.
---@field db sqlite_db: reference to fallback to when overwriting |sqlite_db| methods (extended only).

---@class sqlite_tbl @Main sql table class
---@field db sqlite_db: sqlite.lua database object.
---@field name string: table name.
---@field mtime number: db last modified time.

---@class sqlite_tblext @Extended version of sql table class. This class is generated through |sqlite_tbl:extend|
---@field db sqlite_db: sqlite.lua database object.
---@field name string: table name
---@field mtime number: db last modified time

---@class sqlite_schema_key @Sqlite schema key fileds. {name} is the only required field.
---@field cid number: column index.
---@field name string: column key.
---@field type string: column type.
---@field required boolean: whether it's required.
---@field primary boolean: whether it's a primary key.
---@field default string: default value when null.
---@field reference string: "table_name.column_key"
---@field on_delete sqlite_trigger: trigger on row delete.
---@field on_update sqlite_trigger: trigger on row updated.

---@alias sqlite_schema_dict table<string, sqlite_schema_key>
---@alias sqlite_query_delete table<string, string>

---@class sqlite_opts @Sqlite3 Options (TODO: add sqlite option fields and description)

---@class sqlite_query_update @Query fileds used when calling |sqlite:update| or |sqlite_tbl:update|
---@field where table: filter down values using key values.
---@field set table: key and value to updated.

---@class sqlite_query_select @Query fileds used when calling |sqlite:select| or |sqlite_tbl:get|
---@field where table: filter down values using key values.
---@field keys table: keys to include. (default all)
---@field join table: (TODO: support)
---@field order_by table: { asc = "key", dsc = {"key", "another_key"} }
---@field limit number: the number of result to limit by
---@field contains table: for sqlite glob ex. { title = "fix*" }

---@class sqlite_flags @Sqlite3 Error Flags (TODO: add sqlite error flags value and description)

---@class sqlite_db_status @Status returned from |sqlite:status()|
---@field msg string
---@field code sqlite_flags

---@alias sqlite_trigger
---| '"no action"' : when a parent key is modified or deleted from the database, no special action is taken.
---| '"restrict"' : prohibites from deleting/modifying a parent key when a child key is mapped to it.
---| '"null"' : when a parent key is deleted/modified, the child key that mapped to the parent key gets set to null.
---| '"default"' : similar to "null", except that sets to the column's default value instead of NULL.
---| '"cascade"' : propagates the delete or update operation on the parent key to each dependent child key.

local sqlite = {}

sqlite.version = 0.1
sqlite.db = require "sqlite.db"
sqlite.tbl = require "sqlite.tbl"
sqlite.lib = require "sqlite.strfun"

return sqlite
