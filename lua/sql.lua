local clib = require'sql.defs'
local stmt = require'sql.stmt'
local u = require'sql.utils'
local flags = clib.flags
local sql = {}
sql.__index = sql

local booleansql = function(value) -- TODO: should be done a clib level
  if type(value) == "boolean" then
    value = (value == true) and 1 or 0
  end
  return value
end

-- Creates a new sql.nvim object. if {uri} then connect to {uri}, else :memory:.
---@param uri string optional
---@usage `sql.open()`
---@usage `sql.open("./path/to/sql.sqlite")`
---@usage `sql.open("$ENV_VARABLE")`
---@return table: sql.nvim object
---@todo: It should accept self when trying to reopen
---@todo: decide whether to add active_since.
---@todo: decide whether using os.time and epoch time would be better.
function sql:open(uri)
  local o = {
    uri = uri == "string" and u.expand(uri) or ":memory:",
    -- checks if conn isopen
    created = os.date('%Y-%m-%d %H:%M:%S'),
    closed = false,
  }
  -- in case we want support open_v2, to provide control over how
  -- the database file is opened.
  --[[
  obj.flags = args[2], -- file open operations.
  obj.vfs = args[3], -- VFS (Virtual File System) module to use
  -- ]]

  o.conn = (function()
    local conn = clib.get_new_db_ptr()
    local code = clib.open(o.uri, conn)
    if code == flags.ok then
      return conn[0]
    else
      error(string.format(
        "sql.nvim: couldn't connect to sql database, ERR:",
      code))
      o.closed = true
    end
  end)()

  setmetatable(o, sql)
  return o
end

--- Get last error msg
---@return string: sqlite error msg
function sql:__last_errmsg() return clib.to_str(clib.errmsg(self.conn)) end

--- Get last error code
---@return number: sqlite error number
function sql:__last_errcode() return clib.errcode(self.conn) end

--- predict returning true if db connection is active.
---@return boolean: true if db is opened, otherwise false.
function sql:isopen() return not self.closed end

--- predict returning true if db connection is deactivated.
---@return boolean: true if db is close, otherwise false.
function sql:isclose() return self.closed end

--- wrapper around stmt module for convenience.
---@param statement string: statement to be parsed.
---@return table: stmt object
function sql:__parse(statement) return stmt:parse(self.conn, statement) end

--- Returns current connection status
--- Get last error code
---@todo: decide whether to keep this function
---@return table: msg,code,closed
function sql:status()
  return {
    -- perhaps we should process those and return eg. error = false
    msg = self:__last_errmsg(),
    code = self:__last_errcode(),
    closed = self.closed,
    create = self.created
  }
end

--- closes sqlite db connection.
---@usage `db:close()`
---@return boolean: true if closed, error otherwise.
---@todo: add checks for db connection status and statement status before closing.
function sql:close()
  self.closed = clib.close(self.conn) == 0
  assert(self.closed, string.format(
    "sql.nvim: database connection didn't get closed, ERRMSG: %s",
    self:__last_errmsg()
  ))
  return self.closed
end

--- Evaluate {statement} and returns true if successful else error-out
---@param statement string or table: statements to be executed.
---@param params table: params to be bind to {statement}
---@param callback function: function to be callback with output.
---@usage db:eval("drop table if exists todos")
---@usage db:eval("select * from todos where id = ?", 1)
---@usage db:eval("create table todos")
---@return boolean
---@todo: support bolb binding.
---@todo: support varags for unamed params
function sql:eval(statement, params, callback)
  if type(statement) == "table" then
    return u.all(statement, function(_, v)
      return self:eval(v)
    end)
  end

  local s, res = self:__parse(statement), {}

  if params == nil then
    s:each(function(stm)
      table.insert(res, stm:kv())
    end)
    s:reset()

  elseif params and type(params) ~= "table" and statement:match('%?') then
    local value = booleansql(params)
    s:bind({value})
    s:each(function(stm)
      table.insert(res, stm:kv())
    end)
    s:reset()
    s:bind_clear()

  elseif params and type(params) == "table" then
    params = type(params[1]) == "table" and params or {params}
    for _, v in ipairs(params) do
      s:bind(v)
      s:each(function(stm)
        table.insert(res, stm:kv())
      end)
      s:reset()
      s:bind_clear()
    end
  end

  s:finalize()

  local ret = rawequal(next(res), nil) and self:__last_errcode() == flags.ok or res
  if type(ret) == "table" and ret[2] == nil then ret = ret[1] end -- FIXME: may not be desirable

  assert(self:__last_errcode() == flags.ok , string.format(
  "sql.nvim: database connection didn't get closed, ERRMSG: %s",
  self:__last_errmsg()))

  if callback then
    return callback(ret)
  else
    return ret
  end
end

local parse_keys = function(values)
  if not values then return end
  local t = u.is_nested(values) and values[1] or values
  local keys = u.keynames(t)
  return string.format("(%s)", type(keys) == "string" and keys or table.concat(keys, ","))
end

local parse_values = function(plh, values)
  if not plh or not values then return end
  local t = u.is_nested(values) and values[1] or values
  local keys = u.keynames(t, true)
  local keynames = type(keys) == "string" and keys or table.concat(keys, ",")
  return string.format("values(%s)", keynames)
end

local parse_set = function(t)
  if not t then return end
  t = u.keys(t)
  local set = {}
  for _, v in pairs(t) do
    table.insert(set, v .. " = :" .. v)
  end
  return "set " .. table.concat(set, ",")
end

local parse_where = function(t)
  if not t then return end
  t = u.keys(t)
  local where = {}
  for _, v in pairs(t) do
    table.insert(where, v .. " = :" .. v)
  end
  return "where " .. table.concat(where, ", ")
end

--- Internal function for parsing
---@params act string: the sqlite action [insert, delete, update, drop, create]
function sql:parse(act, o)
  act = act == "insert" and "insert into" or act
  act = act == "delete" and "delete from" or act
  local t = u.flatten{
    act,
    o.tbl and o.tbl or "",
    parse_keys(o.values),
    parse_values(o.placeholders, o.values),
    parse_set(o.set),
    parse_where(o.where),
  }
  local ret = table.concat(t, " ")
  return ret
end

------------------------------------------------------------
-- Sugur over eval function.
------------------------------------------------------------

local assert_tbl = function(self, tbl)
  assert(self:exists(tbl),
    string.format("sql.nvim: can't insert to non-existence table: '%s'.",
    tbl
  ))
end




--- WIP: Execute a complex queries against a table. e.g. contains, is,
---@usage `db:query("todos", {:contains "conni"})`
---@usage `db:query("todos", {:is {deadline = 2021})`
---@usage `db:query("todos", {:not {title = "X"})` < function(t) return t ~= end
---@usage `db:query("any", {:deadline function(d) return d < 2021 end})`
---@todo write function specification.
---@return table
function sql:query(...)
  -- {tbl = "todos", deadline = "today"}
end

--- Insert to lua table into sqlite database table.
--- +supports inserting multiple rows.
---@varargs if {[1]} == table/content else table_name as {args[1]} and table to insert as {args[2]}.
---@return boolean: true incase the table was inserted successfully.
---@usage db:insert("todos", { title = "new todo" })
---@usage db:insert{ todos = { title = "new todo"} }
---@todo insert into multiple tables at the same time.
---@todo support unnamed or anonymous args
---@todo handle inconflict case
function sql:insert(...)
  local args = {...}
  local ret_vals = {}

  local inner_eval = function(tbl, p)
    return self:eval(self:parse("insert", {
      tbl = tbl,
      values = p,
      placeholders = true,
    }), p)
  end

  if u.is_str(args[1]) then
    local tbl = args[1]
    local params = args[2]
    assert_tbl(self, tbl)
    table.insert(ret_vals, inner_eval(tbl, params))
  elseif u.is_str(args[1][1]) then
    local tbls = args[1]
    for k, tbl in ipairs(tbls) do
      local params = args[k + 1]
      table.insert(ret_vals, inner_eval(tbl, params))
    end
  elseif args[1][2] == nil then
    local tbls = u.keys(args[1])
    for _, tbl in ipairs(tbls) do
      local params = args[1][tbl]
      table.insert(ret_vals, inner_eval(tbl, params))
    end
  end

  return u.all(ret_vals, function(_, v) return v end)
end

--- Equivalent to |sql:insert|
function sql:add(...) return sql:insert(...) end

--- Update table row under certine
---@varargs if {[1]} == table/content else table_name as {args[1]} and table to insert as {args[2]}.
---@return boolean: true incase the table was inserted successfully.
---@usage db:update("todos", { where = { id = "1" }, values = { action = "DONE" }})
---@usage db:update{ "todos" = { where = { deadline = "2021" }, values = { status = "overdue" }}}
---@todo support unnamed or anonymous args
function sql:update(...)
  local args = {...}
  local ret_vals = {}

  local inner_eval = function(tbl, p)
    return self:eval(self:parse("update", {
      tbl = tbl,
      set = p.values,
      where = p.where,
      placeholders = true,
    }), u.tbl_extend('force', p.values, p.where))
  end

  local unwrap_params = function(tbl, params)
    if params[1] then
      for _, p in ipairs(params) do
        table.insert(ret_vals, inner_eval(tbl, p))
      end
    else
      table.insert(ret_vals, inner_eval(tbl, params))
    end
  end

  if u.is_str(args[1]) then
    local tbl = args[1]
    local params = args[2]
    assert_tbl(self, tbl)
    unwrap_params(tbl, params)
  elseif u.is_str(args[1][1]) then
    local tbls = args[1]
    for k, tbl in ipairs(tbls) do
      assert_tbl(self, tbl)
      local params = args[k + 1]
      unwrap_params(tbl, params)
    end
  elseif args[1][2] == nil then
    local tbls = u.keys(args[1])
    for _, tbl in ipairs(tbls) do
      assert_tbl(self, tbl)
      local params = args[1][tbl]
      unwrap_params(tbl, params)
    end
  end

  return u.all(ret_vals, function(_, v) return v end)
end

--- same as insert but, mutates the sql_table with the new changes
---@varargs if {[1]} == table/content else table_name as {args[1]} and table with where to delete as {args[2]}.
---@return boolean: true incase the table was inserted successfully.
---@usage db:delete("todos")
---@usage db:delete("todos", { where = { id = 1 })
---@usage db:delete{ todos = { where = { id = 1 } }}
function sql:delete(...)
  local args = {...}
  local ret_vals = {}

  local inner_eval = function(tbl, p)
    return self:eval(self:parse("delete", {
      tbl = tbl,
      where = p and p.where or nil,
      placeholders = true,
    }), p and p.where or nil)
  end

  if u.is_str(args[1]) then
    local tbl = args[1]
    assert_tbl(self, tbl)
    local params = args[2]
    table.insert(ret_vals, inner_eval(tbl, params))
  elseif u.is_str(args[1][1]) then
    local tbls = args[1]
    for k, tbl in ipairs(tbls) do
      local params = args[k + 1]
      table.insert(ret_vals, inner_eval(tbl, params))
    end
  elseif args[1][2] == nil then
    local tbls = u.keys(args[1])
    for _, tbl in ipairs(tbls) do
      local params = args[1][tbl]
      table.insert(ret_vals, inner_eval(tbl, params))
    end
  end

  return u.all(ret_vals, function(_, v) return v end)
end

--- sql.find
-- If a number (primary_key) is passed then returns the row that match that
-- primary key,
-- else if a table is passed,
--   - {project = 4, todo = 1} then return only the todo row for project with id 4,
--   - {project = 4, "todo"} then return all the todo row for project with id 4
--     `opts` is for the last use case, eg. {limit = 10, order = "todo.id desc"}
-- @param `params` string or table or array.
-- @param `opts` table of basic sqlite opts
-- @usage `db:find("todos", 1)`
-- @usage `db:find({project = 1, todo = 1})`
-- @usage `db:find({project = 1, "todo" })`
-- @usage `db:find("project", {order "id"})`
-- @return lua array
-- @see sql.query
function sql:find(params, opts) end

--- Check if a table with {name} exists in sqlite db
function sql:exists(name)
  local q = self:eval("select name from sqlite_master where name= ?", name)
  return type(q) == "table" and true or false
end

return sql
