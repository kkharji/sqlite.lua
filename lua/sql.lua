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
local sql = {}
sql.__index = sql

---@TODO: decide whether using os.time and epoch time would be better.
---@return string|osdate
local created = function()
  return os.date "%Y-%m-%d %H:%M:%S"
end

---Creates a new sql.nvim object, without creating a connection to uri
---|sql.new| is identical to |sql.open| but it without opening sqlite db connection.
---@param uri string: if uri is nil, then create in memory database.
---@usage `sql.new()`
---@usage `sql.new("./path/to/sql.sqlite")`
---@usage `sql:new("$ENV_VARABLE")`
---@return table: sql.nvim object
---@see |sql.open|
function sql.new(uri, opts)
  return sql:open(uri, opts, true)
end

---Connect, or create new sqlite db, either in memory or via a {uri}.
---|sql.open| is identical to |sql.new| but it additionally opens the db
---@param uri string: if uri is nil, then create in memory database.
---@usage `sql.open()`
---@usage `sql.open("./path/to/sql.sqlite")`
---@usage `sql:open("$ENV_VARABLE")`
---@usage `db:open()` reopen connection if closed.
---@TODO: decide whether to add active_since.
---@return table: sql.nvim object
function sql:open(uri, opts, noconn)
  local o = {}

  if self.uri then
    if self.closed or self.closed == nil then
      self.conn = clib.connect(self.uri, self.sqlite_opts)
      self.created = created()
      self.closed = false
    end
    return self
  end

  o.sqlite_opts = opts
  o.uri = type(uri) == "string" and u.expand(uri) or ":memory:"

  if noconn then
    o.closed = true
  else
    o.closed = false
    o.modified = false
    o.conn = clib.connect(o.uri, opts)
    o.created = created()
  end

  setmetatable(o, self)
  return o
end

---closes sqlite db connection.
---@usage `db:close()`
---@return boolean: true if closed, error otherwise.
function sql:close()
  self.closed = self.closed or clib.close(self.conn) == 0
  a.should_close(self.conn, self.closed)
  return self.closed
end

---Same as |sql:open| but closes db connection after executing {args[1]} or
---{args[2]} depending of how its called. if the function is called as a
---method to db object e.g. *db:with_open*, then {args[1]} must be a function.
---Else {args[1]} need to be the uri and {args[2]} the function.
---The function should accept and use db object.
---@varargs If used as db method, then the {args[1]} should be a function, else {args[1]} and {args[2]}.
---@usage `sql.open_with("$ENV_VARABLE/path", function(db) db:eval("...") end)`
---@usage `db:with_open(function() db:insert{...} end)`
---@return table: sql.nvim object
---@see sql:open()
function sql:with_open(...)
  local args = { ... }
  if type(self) == "string" or not self then
    self = sql:open(self)
  end

  local func = type(args[1]) == "function" and args[1] or args[2]

  if self:isclose() then
    self:open()
  end

  local res = func(self)
  self:close()
  return res
end

---Main sqlite interface. This function evaluates {statement} and if there are
---results from evaluating it then the function returns list of row(s). Else, it
---returns a boolean indecating whether the evaluation was successful - or not-
---Optionally, the function accept {params} which can be a dict of values corresponding
---to the sql statement or a list of unamed values.
---@param statement string or table: string representing the {statement} or a list of {statements}
---@param params table: params to be bind to {statement}, it can be a list or dict
---@usage db:eval("drop table if exists todos")
---@usage db:eval("select * from todos where id = ?", 1)
---@usage db:eval("insert into t(a, b) values(:a, :b)", {a = "1", b = 2021})
---@return boolean or table
function sql:eval(statement, params)
  local res = {}
  local s = stmt:parse(self.conn, statement)

  -- when the user provide simple sql statements
  if not params then
    s:each(function()
      table.insert(res, s:kv())
    end)
    s:reset()

    -- when the user run eval("select * from ?", "tbl")
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

---Predict returning true if db connection is active.
---@return boolean: true if db is opened, otherwise false.
function sql:isopen()
  return not self.closed
end

---Predict returning true if db connection is deactivated.
---@return boolean: true if db is close, otherwise false.
function sql:isclose()
  return self.closed
end

---Returns current connection status
---Get last error code
---@TODO: decide whether to keep this function
---@return table: msg,code,closed
function sql:status()
  return {
    msg = clib.last_errmsg(self.conn),
    code = clib.last_errcode(self.conn),
  }
end

---Check if a table with {name} exists in sqlite db
---@param name string: the table name.
---@return boolean
function sql:exists(name)
  local q = self:eval("select name from sqlite_master where name= ?", name)
  return type(q) == "table" and true or false
end

---get sql table {name} schema, if table doesn't exist then return empty table.
---@param tbl string: the table name
---@param info boolean: whether to return table info. default false.
---@return table: list of keys or keys and their type.
function sql:schema(tbl, info)
  local sch = self:eval(string.format("pragma table_info(%s)", tbl))
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

---Create a new sqlite db table with {name} based on {schema}. if {schema.ensure} then
---create only when it doesn't exists. similar to 'create if not exists'
---@param name string: table name
---@param schema table: the table keys/column and their types
---@usage `db:create("todos", {id = {"int", "primary", "key"}, title = "text"})`
---@return boolean
function sql:create(name, schema)
  return self:eval(P.create(name, schema))
end

---Create a new sqlite db table with {name} based on {schema}. if {schema.ensure} then
---create only when it doesn't exists. similar to 'create if not exists'
---@param name string: table name
---@usage `db:drop("todos")`
---@return boolean
function sql:drop(name)
  return self:eval(P.drop(name))
end

---Insert to lua table into sqlite database table.
---@params tbl string: the table name
---@params rows table: rows to insert to the table.
---@return boolean|integer: true incase the table was inserted successfully, and the last inserted row id.
---@usage db:insert("todos", { title = "new todo" })
---@TODO support unnamed or anonymous args
---@TODO handle inconflict case
function sql:insert(tbl, rows)
  a.is_sqltbl(self, tbl, "insert")
  local ret_vals = {}
  local info = self:schema(tbl, true)
  local items = P.pre_insert(rows, info)
  local last_rowid
  clib.wrap_stmts(self.conn, function()
    for _, v in ipairs(items) do
      local s = stmt:parse(self.conn, P.insert(tbl, { values = v }))
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
---@param tbl string: the name of the db table.
---@param specs table: a {spec} or a list of {specs} with where and values key.
---@return boolean: true incase the table was updated successfully.
---@usage `db:update("todos", { where = { id = "1" }, values = { action = "DONE" }})`
function sql:update(tbl, specs)
  a.is_sqltbl(self, tbl, "update")

  local ret_vals = {}
  if not specs then
    return false
  end
  local info = self:schema(tbl, true)
  specs = u.is_nested(specs) and specs or { specs }

  clib.wrap_stmts(self.conn, function()
    for _, v in ipairs(specs) do
      if self:select(tbl, { where = v.where })[1] then
        local s = stmt:parse(self.conn, P.update(tbl, { set = v.values, where = v.where }))
        s:bind(P.pre_insert(v.values, info)[1])
        s:step()
        s:reset()
        s:bind_clear()
        table.insert(ret_vals, s:finalize())
      else
        local res = self:insert(tbl, u.tbl_extend("keep", v.values, v.where))
        table.insert(ret_vals, res)
      end
    end
  end)

  a.should_update(ret_vals)

  local succ = u.all(ret_vals, function(_, v)
    return v
  end)

  if succ then
    self.modified = true
  end
  return succ
end

---Delete a {tbl} row/rows based on the {specs} given. if no spec was given,
---then all the {tbl} content will be deleted.
---@param tbl string: the name of the db table.
---@param specs table: a {spec} or a list of {specs} with where and values key.
---@return boolean: true if operation is successfully, false otherwise.
---@usage db:delete("todos")
---@usage db:delete("todos", { where = { id = 1 })
---@usage db:delete("todos", { where = { id = {1,2,3} })
function sql:delete(tbl, specs)
  a.is_sqltbl(self, tbl, "delete")
  local ret_vals = {}
  if not specs then
    return clib.exec_stmt(self.conn, P.delete(tbl)) == 0 and true or last_errmsg(self.conn)
  end

  specs = u.is_nested(specs) and specs or { specs }
  clib.wrap_stmts(self.conn, function()
    for _, spec in ipairs(specs) do
      local s = stmt:parse(self.conn, P.delete(tbl, { where = spec and spec.where or nil }))
      s:step()
      s:reset()
      table.insert(ret_vals, s:finalize())
    end
  end)

  local succ = u.all(ret_vals, function(_, v)
    return v
  end)
  if succ then
    self.modified = true
  end
  return succ
end

---Query from a table with where and join options
---@usage db:get("todos") -- everything
---@usage db:get("todos", { where = { id = 1 })
---@usage db:get("todos", { limit = 5 })
---@return lua list of matching rows
function sql:select(tbl, spec)
  a.is_sqltbl(self, tbl, "select")
  spec = spec or {}
  self.modified = false

  local ret = {}
  local types = self:schema(tbl)

  self.modified = false

  clib.wrap_stmts(self.conn, function()
    spec.select = spec.keys and spec.keys or spec.select

    local stmt = stmt:parse(self.conn, P.select(tbl, spec))
    stmt:each(function()
      table.insert(ret, stmt:kv())
    end)
    stmt:reset()
    stmt:finalize()
  end)

  return P.post_select(ret, types)
end

---Create new sql-table object.
---@param tbl_name string: the name of the table. can be new or existing one.
---@return table
function sql:table(tbl_name, opts)
  return t:new(self, tbl_name, opts)
end

return sql
