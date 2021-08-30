---@brief [[
---SQLite/LuaJIT binding and highly opinionated wrapper for storing,
---retrieving, caching, persisting, querying, and connecting to SQLite databases.
--- <pre>
--- To find out more:
--- https://github.com/tami5/sql.nvim
---   :h sql
---   :h sql.table
--- </pre>
---@brief ]]
---@tag sql.lua

---@class sqltbl.key
---@field cid number: column index
---@field name string: column key
---@field type string: column type
---@field required boolean: whether the column key is required or not
---@field primary boolean: whether the column is a primary key
---@field default string: the default value of the column
---@field reference string: table_name.column

---@class sqlquery.update @Query spec that are passed to a number of db: methods.
---@field where table: filter down values using key values.
---@field set table: key and value to updated.

---@class sqlquery.select @Query spec that are passed to select method
---@field where table: filter down values using key values.
---@field keys table: keys to include. (default all)
---@field join table: table_name = foreign key, foreign_table_name = primary key

local clib = require "sql.defs"
local stmt = require "sql.stmt"
local u = require "sql.utils"
local a = require "sql.assert"
local t = require "sql.table"
local P = require "sql.parser"
local flags = clib.flags

---@class sqldb @Main sql.nvim object.
---@field uri string: database uri
---@field conn sqldb.types.blob: sqlite connection c object.
---@field db sqldb: fallback when the user overwrite @sqldb methods (extended only).
local DB = {}
DB.__index = DB

---Get a table schema, or execute a given function to get it
---@param schema table|nil
---@param self sqldb
local get_schema = function(tbl_name, self)
  local schema = self.tbl_schemas[tbl_name]
  if schema then
    return schema
  end
  self.tbl_schemas[tbl_name] = self:schema(tbl_name)
  return self.tbl_schemas[tbl_name]
end

---Creates a new sql.nvim object, without creating a connection to uri.
---|DB.new| is identical to |DB:open| but it without opening sqlite db connection.
---@param uri string: path to db.if nil, then create in memory database.
---@param opts table: sqlite db options see https://www.sqlite.org/pragma.html
---@usage `require'sql'.new()` in memory
---@usage `require'sql'.new("./path/to/sql.sqlite")` to given path
---@usage `require'sql'.new("$ENV_VARABLE")` reading from env variable
---@return sqldb
---@see DB:open
function DB.new(uri, opts)
  return DB:open(uri, opts, true)
end

---Connect, or create new sqlite db, either in memory or via a {uri}.
---|DB:open| is identical to |DB.new| but it additionally opens the db
---@param uri string: if uri is nil, then create in memory database.
---@param opts table
---@usage `require("sql"):open()` in memory.
---@usage `require("sql"):open("./path/to/sql.sqlite")` to given path.
---@usage `require("sql"):open("$ENV_VARABLE")` reading from env variable
---@usage `db:open()` reopen connection if closed.
---@return sqldb
function DB:open(uri, opts, noconn)
  if not self.uri then
    uri = type(uri) == "string" and u.expand(uri) or ":memory:"
    return setmetatable({
      uri = uri,
      conn = not noconn and clib.connect(uri, opts) or nil,
      closed = noconn and true or false,
      opts = opts or {},
      modified = false,
      created = not noconn and os.date "%Y-%m-%d %H:%M:%S" or nil,
      tbl_schemas = {},
    }, self)
  else
    if self.closed or self.closed == nil then
      self.conn = clib.connect(self.uri, self.opts)
      self.created = os.date "%Y-%m-%d %H:%M:%S"
      self.closed = false
    end
    return self
  end
end

---Use to Extend sqldb Object with extra sugar syntax and api.
---@param sql sqldb
---@param tbl sqltable
---@param opts table: uri, init, opts, tbl_name, tbl_name ....
---@usage `local tbl = require('sql.table'):extend("tasks", { ... })` -- pre-made table
---@usage `local tbl = { ... }` -- normal schema table schema
---@usage `local tbl = { _name = "tasks", ... }` -- normal table with schema and custom table name
---@usage `local db = DB:extend { uri = "", t = tbl }` -- db.t to access sql 'tbl' object.
---@usage `db.t.insert {...}; db.t.get(); db.t.remove(); db:isopen()`
---@return sqldb
function DB:extend(opts)
  local db = self.new(opts.uri, opts.opts)
  local cls = setmetatable({ db = db }, { __index = db })
  for tbl_name, schema in pairs(opts) do
    if tbl_name ~= "uri" and tbl_name ~= "opts" and u.is_tbl(schema) then
      local name = schema._name and schema._name or tbl_name
      cls[tbl_name] = schema.set_db and schema or t:extend(name, schema)
      if not cls[tbl_name].db then
        cls[tbl_name].set_db(cls.db)
      end
    end
  end
  return cls
end

---Close sqlite db connection. returns true if closed, error otherwise.
---@usage `db:close()`
---@return boolean
function DB:close()
  self.closed = self.closed or clib.close(self.conn) == 0
  a.should_close(self.conn, self.closed)
  return self.closed
end

---Same as |DB:open| but closes db connection after executing {args[1]} or
---{args[2]} depending of how its called. if the function is called as a
---method to db object e.g. *db:with_open*, then {args[1]} must be a function.
---Else {args[1]} need to be the uri and {args[2]} the function.
---The function should accept and use db object.
---@varargs If used as db method, then the {args[1]} should be a function, else {args[1]} and {args[2]}.
---@return any
---@usage `require"sql".open_with("path", function(db) db:eval("...") end)` use a the sqlite db at path.
---@usage `db:with_open(function() db:insert{...} end)` open db connection, execute insert and close.
---@see DB:open
function DB:with_open(...)
  local args = { ... }
  if type(self) == "string" or not self then
    self = DB:open(self)
  end

  local func = type(args[1]) == "function" and args[1] or args[2]

  if self:isclose() then
    self:open()
  end

  local res = func(self)
  self:close()
  return res
end

---Predict returning true if db connection is active.
---@return boolean
---@usage `if db:isopen() then db:close() end` use in if statement.
function DB:isopen()
  return not self.closed
end

---Predict returning true if db connection is indeed closed.
---@usage `if db:isclose() then db:open() end` use in if statement.
---@return boolean
function DB:isclose()
  return self.closed
end

---@class sqldb.status
---@field msg string
---@field code sqldb.flags

---Returns current connection status
---Get last error code
---@todo: decide whether to keep this function
---@return sqldb.status
function DB:status()
  return {
    msg = clib.last_errmsg(self.conn),
    code = clib.last_errcode(self.conn),
  }
end

---Evaluates a sql {statement} and if there are results from evaluating it then
---the function returns list of row(s). Else, it returns a boolean indecating
---whether the evaluation was successful. Optionally, the function accept
---{params} which can be a dict of values corresponding to the sql statement or
---a list of unamed values.
---@param statement any: string representing the {statement} or a list of {statements}
---@param params table: params to be bind to {statement}, it can be a list or dict or nil
---@usage `db:eval("drop table if exists todos")` evaluate without any extra arguments.
---@usage `db:eval("select * from todos where id = ?", 1)` evaluate with unamed value.
---@usage `db:eval("insert into t(a, b) values(:a, :b)", {a = "1", b = 3})` evaluate with named arguments.
---@return boolean | table
function DB:eval(statement, params)
  local res = {}
  local s = stmt:parse(self.conn, statement)

  -- when the user provide simple sql statements
  if not params then
    s:each(function()
      table.insert(res, s:kv())
    end)
    s:reset()

    -- when the user run eval("select * from ?", "tbl_name")
  elseif type(params) ~= "table" and statement:match "%?" then
    local value = P.sqlvalue(params)
    s:bind { value }
    s:each(function(stm)
      table.insert(res, stm:kv())
    end)
    s:reset()
    s:bind_clear()

    -- when the user provided named keys
  elseif params and type(params) == "table" then
    params = type(params[1]) == "table" and params or { params }
    for _, v in ipairs(params) do
      s:bind(v)
      s:each(function(stm)
        table.insert(res, stm:kv())
      end)
      s:reset()
      s:bind_clear()
    end
  end
  -- clear out the parsed statement.
  s:finalize()

  -- if no rows is returned, then check return the result of errcode == flags.ok
  res = rawequal(next(res), nil) and clib.last_errcode(self.conn) == flags.ok or res

  -- fix res of its table, so that select all doesn't return { [1] = {[1] = { row }} }
  if type(res) == "table" and res[2] == nil and u.is_nested(res[1]) then
    res = res[1]
  end

  a.should_eval(self.conn)

  self.modified = true

  return res
end

---Execute statement without any return
---@param statement string: statement to be executed
---@return boolean: true if successful, error out if not.
function DB:execute(statement)
  local succ = clib.exec_stmt(self.conn, statement) == 0
  return succ and succ or error(clib.last_errmsg(self.conn))
end

---Check if a table with {tbl_name} exists in sqlite db
---@param tbl_name string: the table name.
---@usage `if not db:exists("todo_tbl") then error("...") end`
---@return boolean
function DB:exists(tbl_name)
  local q = self:eval("select name from sqlite_master where name= ?", tbl_name)
  return type(q) == "table" and true or false
end

---Create a new sqlite db table with {name} based on {schema}. if {schema.ensure} then
---create only when it does not exists. similar to 'create if not exists'.
---@param tbl_name string: table name
---@param schema table<string, sqltbl_key>
---@usage `db:create("todos", {id = {"int", "primary", "key"}, title = "text"})` create table with the given schema.
---@return boolean
function DB:create(tbl_name, schema)
  local req = P.create(tbl_name, schema)
  if req:match "reference" then
    self:execute "pragma foreign_keys = ON"
    self.opts.foreign_keys = true
  end
  return self:eval(req)
end

---Remove {tbl_name} from database
---@param tbl_name string: table name
---@usage `db:drop("todos")` drop table.
---@return boolean
function DB:drop(tbl_name)
  self.tbl_schemas[tbl_name] = nil
  return self:eval(P.drop(tbl_name))
end

---Get {name} table schema, if table does not exist then return an empty table.
---@param tbl_name string: the table name.
---@return table<string, sqltbl_key>
function DB:schema(tbl_name)
  local sch = self:eval(("pragma table_info(%s)"):format(tbl_name))
  local schema = {}
  for _, v in ipairs(type(sch) == "boolean" and {} or sch) do
    schema[v.name] = {
      cid = v.cid,
      required = v.notnull == 1,
      primary = v.pk == 1,
      type = v.type,
      default = v.dflt_value,
    }
  end
  return schema
end

---Insert to lua table into sqlite database table.
---returns true incase the table was inserted successfully, and the last
---inserted row id.
---@param tbl_name string: the table name
---@param rows table: rows to insert to the table.
---@return boolean|integer
---@usage `db:insert("todos", { title = "new todo" })` single item.
---@usage `db:insert("items", {  { name = "a"}, { name = "b" }, { name = "c" } })` insert multiple items.
---@todo handle inconflict case
function DB:insert(tbl_name, rows, schema)
  a.is_sqltbl(self, tbl_name, "insert")
  local ret_vals = {}
  schema = schema and schema or get_schema(tbl_name, self)
  local items = P.pre_insert(rows, schema)
  local last_rowid
  clib.wrap_stmts(self.conn, function()
    for _, v in ipairs(items) do
      local s = stmt:parse(self.conn, P.insert(tbl_name, { values = v }))
      s:bind(v)
      s:step()
      s:bind_clear()
      table.insert(ret_vals, s:finalize())
    end
    last_rowid = tonumber(clib.last_insert_rowid(self.conn))
  end)

  local succ = u.all(ret_vals, function(_, v)
    return v
  end)
  if succ then
    self.modified = true
  end
  return succ, last_rowid
end

---Update table row with where closure and list of values
---returns true incase the table was updated successfully.
---@param tbl_name string: the name of the db table.
---@param specs sqlquery.update | sqlquery.update[]
---@return boolean
---@usage `db:update("todos", { where = { id = "1" }, values = { action = "DONE" }})` update id 1 with the given keys
---@usage `db:update("todos", {{ where = { id = "1" }, values = { action = "DONE" }}, {...}, {...}})` multi updates.
---@usage `db:update("todos", { where = { project = "sql.nvim" }, values = { status = "later" } )` update multiple rows
function DB:update(tbl_name, specs, schema)
  a.is_sqltbl(self, tbl_name, "update")
  if not specs then
    return false
  end

  return clib.wrap_stmts(self.conn, function()
    specs = u.is_nested(specs) and specs or { specs }
    schema = schema and schema or get_schema(tbl_name, self)

    local ret_val = nil
    for _, v in ipairs(specs) do
      v.set = v.set and v.set or v.values
      if self:select(tbl_name, { where = v.where })[1] then
        local s = stmt:parse(self.conn, P.update(tbl_name, { set = v.set, where = v.where }))
        s:bind(P.pre_insert(v.set, schema)[1])
        s:step()
        s:reset()
        s:bind_clear()
        s:finalize()
        a.should_modify(self:status())
        ret_val = true
      else
        ret_val = self:insert(tbl_name, u.tbl_extend("keep", v.set, v.where))
        a.should_modify(self:status())
      end
    end
    self.modified = true
    return ret_val
  end)
end

---Delete a {tbl_name} row/rows based on the {specs} given. if no spec was given,
---then all the {tbl_name} content will be deleted.
---@param tbl_name string: the name of the db table.
---@param where sqlquery.delete: key value pair to delete matching rows,
---@return boolean: true if operation is successfully, false otherwise.
---@usage `db:delete("todos")` delete todos table content
---@usage `db:delete("todos", { id = 1 })` delete row that has id as 1
---@usage `db:delete("todos", { id = {1,2,3} })` delete all rows that has value of id 1 or 2 or 3
---@usage `db:delete("todos", { id = {1,2,3} }, { id = {"<", 5} } )` matching ids or greater than 5
---@todo support querys with `and`
function DB:delete(tbl_name, where)
  a.is_sqltbl(self, tbl_name, "delete")

  if not where then
    return self:execute(P.delete(tbl_name))
  end

  where = u.is_nested(where) and where or { where }
  clib.wrap_stmts(self.conn, function()
    for _, spec in ipairs(where) do
      local _where = spec.where and spec.where or spec
      local s = stmt:parse(self.conn, P.delete(tbl_name, { where = _where }))
      s:step()
      s:reset()
      s:finalize()
      a.should_modify(self:status())
    end
  end)

  self.modified = true

  return true
end

---Query from a table with where and join options
---@param tbl_name string: the name of the db table to select on
---@param spec sqlquery.select
---@usage `db:select("todos")` get everything
---@usage `db:select("todos", { where = { id = 1 })` get row with id of 1
---@usage `db:select("todos", { where = { status = {"later", "paused"} })` get row with status value of later or paused
---@usage `db:select("todos", { limit = 5 })` get 5 items from todos table
---@return table[]
function DB:select(tbl_name, spec, schema)
  a.is_sqltbl(self, tbl_name, "select")
  return clib.wrap_stmts(self.conn, function()
    local ret = {}
    schema = schema and schema or get_schema(tbl_name, self)

    spec = spec or {}
    spec.select = spec.keys and spec.keys or spec.select

    local s = stmt:parse(self.conn, P.select(tbl_name, spec))
    stmt.each(s, function()
      table.insert(ret, stmt.kv(s))
    end)
    stmt.reset(s)
    if stmt.finalize(s) then
      self.modified = false
    end
    return P.post_select(ret, schema)
  end)
end

---Create new sql-table object.
---If {opts}.ensure = false, on each run it will drop the table and recreate it.
---@param tbl_name string: the name of the table. can be new or existing one.
---@param opts table: {schema, ensure (defalut true)}
---@return sqltale
function DB:table(tbl_name, opts)
  return t:new(self, tbl_name, opts)
end

---Sqlite functions sugar wrappers. See `sql/strfun`
DB.lib = require "sql.strfun"

DB = setmetatable(DB, { __call = DB.extend })

return DB
