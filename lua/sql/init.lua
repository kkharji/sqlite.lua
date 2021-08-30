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
---   :h |sqlite.schema.key|     | open a class or type
---   :h |sqlite.tbl.overview|    | show help for sqlite.tbl.
---   :h |sqlite.db.overview|     | show help for sqlite.tbl.
---   :h sqlite.db:...            | show help for a sqlite.db method.
---   :h sqlite.tbl:...           | show help for a sqlite.tbl method.
---
---</pre>
--- sql.nvim types:
---@brief ]]
---@tag sqlinfo

---@class sqlite.db @Main sql.nvim object.
---@field uri string: database uri. it can be an environment variable or an absolute path. default ":memory:"
---@field opts sqlite.db.opts: see https://www.sqlite.org/pragma.html |sqlite.db.opts|
---@field conn sqlite.blob: sqlite connection c object.
---@field db sqlite.db: reference to fallback to when overwriting |sqlite.db| methods (extended only).

---@class sqlite.tbl @Main sql table class
---@field db sqlite.db: database .
---@field name string: table name.
---@field mtime number: db last modified time.

---@class sqlite.tblext @Extended version of sql table class. This class is generated through |sqlite.tbl:extend|
---@field db sqlite.db
---@field name string: table name
---@field mtime number: db last modified time

---@class sqlite.schema.key @Sqlite schema key fileds. {name} is the only required field.
---@field cid number: column index.
---@field name string: column key.
---@field type string: column type.
---@field required boolean: whether it's required.
---@field primary boolean: whether it's a primary key.
---@field default string: default value when null.
---@field reference string: "table_name.column_key"
---@field on_delete sqlite.trigger: trigger on row delete.
---@field on_update sqlite.trigger: trigger on row updated.

---@alias sqlite.schema.dict table<string, sqlite.schema.key>
---@alias sqlite.delete_query table<string, string>

---@class sqlite.db.opts @Sqlite3 Options (TODO: add sqlite option fields and description)

---@class sqlite.update_query @Query fileds used when calling |sqlite.db:update| or |sqlite.tbl:update|
---@field where table: filter down values using key values.
---@field set table: key and value to updated.

---@class sqlite.select_query @Query fileds used when calling |sqlite.db:select| or |sqlite.tbl:get|
---@field where table: filter down values using key values.
---@field keys table: keys to include. (default all)
---@field join table: (TODO: support)
---@field order_by table: { asc = "key", dsc = {"key", "another_key"} }
---@field limit number: the number of result to limit by
---@field contains table: for sqlite glob ex. { title = "fix*" }

---@class sqlite.flags @Sqlite3 Error Flags (TODO: add sqlite error flags value and description)

---@class sqlite.db_status @Status returned from |sqlite.db:status()|
---@field msg string
---@field code sqlite.flags

---@alias sqlite.trigger
---| '"no action"' : when a parent key is modified or deleted from the database, no special action is taken.
---| '"restrict"' : prohibites from deleting/modifying a parent key when a child key is mapped to it.
---| '"null"' : when a parent key is deleted/modified, the child key that mapped to the parent key gets set to null.
---| '"default"' : similar to "null", except that sets to the column's default value instead of NULL.
---| '"cascade"' : propagates the delete or update operation on the parent key to each dependent child key.

return require "sql.db"
