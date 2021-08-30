---@brief [[
---SQLite/LuaJIT binding and highly opinionated wrapper for storing,
---retrieving, caching, persisting, querying, and connecting to SQLite databases.
---
--- To find out more
--- visit https://github.com/tami5/sql.nvim
---<pre>
---
--- Help usage in neovim:
---   :h sqlinfo              | main sql.nvim classes
---   :h sqlschemafield       | open a class or type
---   :h sqltbl.overview      | show help for sqltbl.
---   :h sqldb:...            | show help for a sqldb method.
---   :h sqldb.overview       | show help for sqltbl.
---   :h sqltbl:...           | show help for a sqltbl method.
---
---</pre>
--- sql.nvim types:
---@brief ]]
---@tag sqlinfo

---@class sqldb @Main sql.nvim object.
---@field uri string: database uri
---@field conn sqlite_blob: sqlite connection c object.
---@field db sqldb: fallback when the user overwrite @sqldb methods (extended only).
---@field opts sqlopts: sqlite options see https://www.sqlite.org/pragma.html
---@class sqltbl @Main sql table class
---@field db sqldb: database in which the tbl is part of.
---@field name string: table name
---@field mtime number: db last modified time

---@class sqltblext @Extended version of sql table class. This class is generated through |sqltbl:extend| or sql.tbl()
---@field db sqldb
---@field name string: table name
---@field mtime number: db last modified time

---@class sqlschemafield @Sqlite schema key fileds. {name} is the only required field.
---@field cid number: column index
---@field name string: column key
---@field type string: column type
---@field required boolean: whether the column key is required or not
---@field primary boolean: whether the column is a primary key
---@field default string: the default value of the column
---@field reference string: "table_name.column"
---@field on_delete sqltrigger: what to do when the key gets deleted
---@field on_update sqltrigger: what to do when the key gets updated

---@alias sqlschema table<string, sqlschemafield>
---@alias sqlquery_delete table<string, string>

---@class sqlopts @Sqlite3 Options (TODO: add sqlite option fields and description)

---@class sqlquery_update @Query fileds used when calling |sql.update| or |tbl.update|
---@field where table: filter down values using key values.
---@field set table: key and value to updated.

---@class sqlquery_select @Query spec that are passed to select method
---@field where table: filter down values using key values.
---@field keys table: keys to include. (default all)
---@field join table: table_name = foreign key, foreign_table_name = primary key
---@field order_by table: { asc = "key", dsc = {"key", "another_key"} }

---@class sqlflag @Sqlite3 Error Flags (TODO: add sqlite error flags value and description)

---@class sqldb_status @Status returned from |sql.status|
---@field msg string
---@field code sqlflag

---@alias sqltrigger
---| '"no action"' : when a parent key is modified or deleted from the database, no special action is taken.
---| '"restrict"' : prohibites from deleting/modifying a parent key when a child key is mapped to it.
---| '"null"' : when a parent key is deleted/modified, the child key that mapped to the parent key gets set to null.
---| '"default"' : similar to "null", except that sets to the column's default value instead of NULL.
---| '"cascade"' : propagates the delete or update operation on the parent key to each dependent child key.

return require "sql.db"
