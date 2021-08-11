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

local clib = require "sql.defs"
local stmt = require "sql.stmt"
local u = require "sql.utils"
local a = require "sql.assert"
local t = require "sql.table"
local P = require "sql.parser"
local flags = clib.flags

---@class SQLDatabase @Main sql.nvim object.
local DB = {}
DB.__index = DB

---@class SQLQuerySpec @Query spec that are passed to a number of db: methods.
---@field where table: key and value
---@field values table: key and value to updated.

---@class SQLDatabaseExt:SQLDatabase @Extend sql.nvim object
---@field db SQLDatabase: fallback when the user overwrite @SQLDatabaseExt methods .

---return now date
---@todo: decide whether using os.time and epoch time would be better.
---@return string osdate
local created = function()
  return os.date "%Y-%m-%d %H:%M:%S"
end

---Creates a new sql.nvim object, without creating a connection to uri.
---|DB.new| is identical to |DB:open| but it without opening sqlite db connection.
---@param uri string: path to db.if nil, then create in memory database.
---@param opts table: sqlite db options see https://www.sqlite.org/pragma.html
---@usage `require'sql'.new()` in memory
---@usage `require'sql'.new("./path/to/sql.sqlite")` to given path
---@usage `require'sql'.new("$ENV_VARABLE")` reading from env variable
---@return SQLDatabase
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
---@return SQLDatabase
function DB:open(uri, opts, noconn)
  if not self.uri then
    uri = type(uri) == "string" and u.expand(uri) or ":memory:"
    return setmetatable({
      uri = uri,
      conn = not noconn and clib.connect(uri, opts) or nil,
      closed = noconn and true or false,
      sqlite_opts = opts,
      modified = false,
      created = not noconn and created() or nil,
    }, self)
  else
    if self.closed or self.closed == nil then
      self.conn = clib.connect(self.uri, self.sqlite_opts)
      self.created = created()
      self.closed = false
    end
    return self
  end
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

---@class SQLDatabaseStatus
---@field msg string
---@field code sqlite3_flag

---Returns current connection status
---Get last error code
---@todo: decide whether to keep this function
---@return SQLDatabaseStatus
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
---@param schema table: the table keys/column and their types
---@usage `db:create("todos", {id = {"int", "primary", "key"}, title = "text"})` create table with the given schema.
---@return boolean
function DB:create(tbl_name, schema)
  local req = P.create(tbl_name, schema)
  if req:match "reference" then
    self:eval "pragma foreign_keys = ON"
  end
  return self:eval(req)
end

---Remove {tbl_name} from database
---@param tbl_name string: table name
---@usage `db:drop("todos")` drop table.
---@return boolean
function DB:drop(tbl_name)
  return self:eval(P.drop(tbl_name))
end

---Get {name} table schema, if table does not exist then return an empty table.
---@param tbl_name string: the table name.
---@param info boolean: whether to return table info. default false.
---@return table list of keys or keys and their type.
function DB:schema(tbl_name, info)
  local sch = self:eval(string.format("pragma table_info(%s)", tbl_name))
  if type(sch) == "boolean" then
    return {}
  end

  local tbl_info = {}
  local req = {}
  local def = {}
  local types = {}

  for _, v in ipairs(sch) do
    if v.notnull == 1 and v.pk == 0 then
      req[v.name] = v
    end
    if v.dflt_value then
      def[v.name] = v.dflt_value
    end

    tbl_info[v.name] = {
      required = v.notnull == 1,
      primary = v.pk == 1,
      type = v.type,
      cid = v.cid,
      default = v.dflt_value,
    }

    types[v.name] = v.type
  end

  local obj = {
    info = tbl_info,
    req = req == {} and nil or req,
    def = def == {} and nil or def,
    types = types,
  }

  return info and obj or obj.types
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
function DB:insert(tbl_name, rows)
  a.is_sqltbl(self, tbl_name, "insert")
  local ret_vals = {}
  local info = self:schema(tbl_name, true)
  local items = P.pre_insert(rows, info)
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
---@param specs SQLQuerySpec | SQLQuerySpec[]
---@return boolean
---@usage `db:update("todos", { where = { id = "1" }, values = { action = "DONE" }})` update id 1 with the given keys
---@usage `db:update("todos", {{ where = { id = "1" }, values = { action = "DONE" }}, {...}, {...}})` multi updates.
---@usage `db:update("todos", { where = { project = "sql.nvim" }, values = { status = "later" } )` update multiple rows
function DB:update(tbl_name, specs)
  a.is_sqltbl(self, tbl_name, "update")

  local ret_vals = {}
  if not specs then
    return false
  end
  local info = self:schema(tbl_name, true)
  specs = u.is_nested(specs) and specs or { specs }

  clib.wrap_stmts(self.conn, function()
    for _, v in ipairs(specs) do
      v.set = v.set and v.set or v.values
      if self:select(tbl_name, { where = v.where })[1] then
        local s = stmt:parse(self.conn, P.update(tbl_name, { set = v.set, where = v.where }))
        s:bind(P.pre_insert(v.set, info)[1])
        s:step()
        s:reset()
        s:bind_clear()
        s:finalize()
        a.should_modify(self:status())
      else
        local res = self:insert(tbl_name, u.tbl_extend("keep", v.set, v.where))
        table.insert(ret_vals, res)
      end
    end
  end)

  self.modified = true
  return true
end

---Delete a {tbl_name} row/rows based on the {specs} given. if no spec was given,
---then all the {tbl_name} content will be deleted.
---@param tbl_name string: the name of the db table.
---@param specs SQLQuerySpec
---@return boolean: true if operation is successfully, false otherwise.
---@usage `db:delete("todos")` delete todos table content
---@usage `db:delete("todos", { where = { id = 1 })` delete row that has id as 1
---@usage `db:delete("todos", { where = { id = {1,2,3} })` delete all rows that has value of id 1 or 2 or 3
function DB:delete(tbl_name, specs)
  a.is_sqltbl(self, tbl_name, "delete")

  if not specs then
    return clib.exec_stmt(self.conn, P.delete(tbl_name)) == 0 and true or clib.last_errmsg(self.conn)
  end

  specs = u.is_nested(specs) and specs or { specs }
  clib.wrap_stmts(self.conn, function()
    for _, spec in ipairs(specs) do
      local s = stmt:parse(self.conn, P.delete(tbl_name, { where = spec and spec.where or nil }))
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
---@param spec SQLQuerySpec
---@usage `db:select("todos")` get everything
---@usage `db:select("todos", { where = { id = 1 })` get row with id of 1
---@usage `db:select("todos", { where = { status = {"later", "paused"} })` get row with status value of later or paused
---@usage `db:select("todos", { limit = 5 })` get 5 items from todos table
---@return table[]
function DB:select(tbl_name, spec)
  a.is_sqltbl(self, tbl_name, "select")
  spec = spec or {}
  self.modified = false

  local ret = {}
  local types = self:schema(tbl_name)

  self.modified = false

  clib.wrap_stmts(self.conn, function()
    spec.select = spec.keys and spec.keys or spec.select

    local s = stmt:parse(self.conn, P.select(tbl_name, spec))
    stmt.each(s, function()
      table.insert(ret, stmt.kv(s))
    end)
    stmt.reset(s)
    stmt.finalize(s)
  end)

  return P.post_select(ret, types)
end

---Create new sql-table object.
---If {opts}.ensure = false, on each run it will drop the table and recreate it.
---@param tbl_name string: the name of the table. can be new or existing one.
---@param opts table: {schema, ensure (defalut true)}
---@return SQLTable
function DB:table(tbl_name, opts)
  return t:new(self, tbl_name, opts)
end

---Use to Extend SQLDatabase Object with extra sugar syntax and api.
---@param sql SQLDatabase
---@param tbl SQLTable
---@param opts table: uri, opts, tbl_name, tbl_name ....
---@return SQLDatabase
function DB:extend(opts)
  local db = self.new(opts.uri, opts.opts)
  --@type SQLDatabase
  local cls = setmetatable({ db = db }, { __index = db })

  for tbl_name, schema in pairs(opts) do
    if tbl_name ~= "uri" and tbl_name ~= "opts" then
      cls[tbl_name] = t:extend(db, tbl_name, schema)
    end
  end

  return cls
end

DB = setmetatable(DB, { __call = DB.extend })

return DB
