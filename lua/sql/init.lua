---@brief [[
---SQLite/LuaJIT binding and highly opinionated wrapper for storing,
---retrieving, caching, persisting, querying, and connecting to SQLite databases.
---
--- To find out more
--- visit https://github.com/tami5/sql.nvim
---<pre>
---
--- Help usage in neovim: ignore ||
---   :h |sqlinfo|            | main sql.nvim classes
---   :h |sqlschemafield|     | open a class or type
---   :h |sqltbl.overview|    | show help for sqltbl.
---   :h |sqldb.overview|     | show help for sqltbl.
---   :h sqldb:...            | show help for a sqldb method.
---   :h sqltbl:...           | show help for a sqltbl method.
---
---</pre>
--- sql.nvim types:
---@brief ]]
---@tag sqlinfo

---@class sqldb @Main sql.nvim object.
---@field uri string: database uri. it can be an environment variable or an absolute path. default ":memory:"
---@field opts sqlopts: see https://www.sqlite.org/pragma.html |sqlopts|
---@field conn sqlite_blob: sqlite connection c object.
---@field db sqldb: reference to fallback to when overwriting |sqldb| methods (extended only).

---@class sqltbl @Main sql table class
---@field db sqldb: database .
---@field name string: table name.
---@field mtime number: db last modified time.

---@class sqltblext @Extended version of sql table class. This class is generated through |sqltbl:extend|
---@field db sqldb
---@field name string: table name
---@field mtime number: db last modified time

---@class sqlschemafield @Sqlite schema key fileds. {name} is the only required field.
---@field cid number: column index.
---@field name string: column key.
---@field type string: column type.
---@field required boolean: whether it's required.
---@field primary boolean: whether it's a primary key.
---@field default string: default value when null.
---@field reference string: "table_name.column_key"
---@field on_delete sqltrigger: trigger on row delete.
---@field on_update sqltrigger: trigger on row updated.

---@alias sqlschema table<string, sqlschemafield>
---@alias sqlquery_delete table<string, string>

---@class sqlopts @Sqlite3 Options (TODO: add sqlite option fields and description)

---@class sqlquery_update @Query fileds used when calling |sqldb:update| or |sqltbl:update|
---@field where table: filter down values using key values.
---@field set table: key and value to updated.

---@class sqlquery_select @Query fileds used when calling |sqldb:select| or |sqltbl:get|
---@field where table: filter down values using key values.
---@field keys table: keys to include. (default all)
---@field join table: (TODO: support)
---@field order_by table: { asc = "key", dsc = {"key", "another_key"} }
---@field limit number: the number of result to limit by
---@field contains table: for sqlite glob ex. { title = "fix*" }

---@class sqlflag @Sqlite3 Error Flags (TODO: add sqlite error flags value and description)

---@class sqldb_status @Status returned from |sqldb:status()|
---@field msg string
---@field code sqlflag

---@alias sqltrigger
---| '"no action"' : when a parent key is modified or deleted from the database, no special action is taken.
---| '"restrict"' : prohibites from deleting/modifying a parent key when a child key is mapped to it.
---| '"null"' : when a parent key is deleted/modified, the child key that mapped to the parent key gets set to null.
---| '"default"' : similar to "null", except that sets to the column's default value instead of NULL.
---| '"cascade"' : propagates the delete or update operation on the parent key to each dependent child key.

return require "sql.db"
