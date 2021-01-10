local clib = require'sql.defs'
local stmt = require'sql.stmt'
local u = require'sql.utils'
local parse = require'sql.parser'
local flags = clib.flags
local sql = {}
sql.__index = sql

local booleansql = function(value) -- TODO: should be done a clib level
  if type(value) == "boolean" then
    value = (value == true) and 1 or 0
  end
  return value
end

--- Internal function for creating new connection.
---@todo: decide whether using os.time and epoch time would be better.
-- sets {created, conn, closed}
function sql:__connect()
  local conn = clib.get_new_db_ptr()
  local code = clib.open(self.uri, conn)
  -- TODO: support open_v2, to provide control over how
  -- the database file is opened.
  -- self.flags = args[2], -- file open operations.
  -- self.vfs = args[3], -- VFS (Virtual File System) module to use

  if code == flags.ok then
    self.created = os.date('%Y-%m-%d %H:%M:%S')
    self.conn = conn[0]
    self.closed = false
  else
    error(string.format("sql.nvim: couldn't connect to sql database, ERR:", code))
  end
end

--- Creates a new sql.nvim object, without creating a connection to uri
--- |sql.new| is identical to |sql.open| but it without opening sqlite db connection.
---@param uri string: if uri is nil, then create in memory database.
---@usage `sql.new()`
---@usage `sql.new("./path/to/sql.sqlite")`
---@usage `sql:new("$ENV_VARABLE")`
---@return table: sql.nvim object
---@see |sql.open|
function sql.new(uri)
  return sql:open(uri, true)
end

--- Connect, or create new sqlite db, either in memory or via a {uri}.
--- |sql.open| is identical to |sql.new| but it additionally opens the db
---@param uri string: if uri is nil, then create in memory database.
---@usage `sql.open()`
---@usage `sql.open("./path/to/sql.sqlite")`
---@usage `sql:open("$ENV_VARABLE")`
---@usage `db:open()` reopen connection if closed.
---@return table: sql.nvim object
---@todo: decide whether to add active_since.
function sql:open(uri, noconn)
  local o = {}
  if type(self) == 'string' or not self then
    uri, self = self, sql
  end

  if self.uri then
    if self.closed or self.closed == nil then self:__connect() end
    if not self.closed then
      return self
    else
      return false
    end
  end

  o.uri = type(uri) == "string" and u.expand(uri) or ":memory:"
  setmetatable(o, self)

  if noconn then
    o.closed = true
    return o
  end
  o:__connect()
  return o
end

--- Same as |sql:open| but closes db connection after executing {args[1]} or
--- {args[2]} depending of how its called. if the function is called as a
--- method to db object e.g. *db:with_open*, then {args[1]} must be a function.
--- Else {args[1]} need to be the uri and {args[2]} the function.
--- The function should accept and us db object.
---@varargs If used as db method, then the {args[1]} should be a function, else {args[1]} and {args[2]}.
---@usage `sql.open_with("$ENV_VARABLE/path", function(db) db:eval("...") end)`
---@usage `db:with_open(function() db:insert{...} end)`
---@return table: sql.nvim object
---@see sql:open()
function sql:with_open(...)
  local args = {...}
  if type(self) == 'string' or not self then
    self = sql.open(self)
  end

  local func = type(args[1]) == "function" and args[1] or args[2]

  if self:isclose() then
    self:open()
  end

  func(self)
  self:close()
  return self
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

--- Evaluate {statement} and returns true if successful else error-out.
--- Optionally it accept {params} which can be a dict of values corresponding
--- to the sql statement or a list of unamed values.
---@param statement string or table: string representing the {statement} or a list of {statements}
---@param params table: params to be bind to {statement}, it can be a list or dict
---@usage db:eval("drop table if exists todos")
---@usage db:eval("select * from todos where id = ?", 1)
---@usage db:eval("insert into todos(title, deadline) values(:title, :deadline)", {title = "1", deadline = 2021})
---@return boolean: if the evaluation is successful then return true.
---@todo: support bolb binding.
---@todo: support varags for unamed params
function sql:eval(statement, params)
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

  if type(ret) == "table" and ret[2] == nil and u.is_nested(ret[1]) then
    ret = ret[1]
  end

  assert(self:__last_errcode() == flags.ok , string.format(
    "sql.nvim: database connection didn't get closed, ERRMSG: %s",
    self:__last_errmsg()
  ))

  return ret
end

------------------------------------------------------------
-- Sugur over eval function.
------------------------------------------------------------

local assert_tbl = function(self, tbl, method)
  assert(self:exists(tbl),
    string.format("sql.nvim: %s table doesn't exists. %s failed.",
    tbl, method
  ))
end

local fail_on_wrong_input = function(ret_vals)
  assert(#ret_vals > 0, 'sql.nvim: can\'t parse your input. Make sure it use that function correct')
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
  local method = "insert"
  local args = {...}
  local ret_vals = {}

  local inner_eval = function(tbl, p)
    local sqlstmt = parse(tbl, method, {
      values = p,
      named = true,
    })
    return self:eval(sqlstmt, p)
  end

  if u.is_str(args[1]) then
    local tbl = args[1]
    local params = args[2]
    assert_tbl(self, tbl, "insert")
    table.insert(ret_vals, inner_eval(tbl, params))
  elseif u.is_str(args[1][1]) then
    local tbls = args[1]
    for k, tbl in ipairs(tbls) do
      assert_tbl(self, tbl, "insert")
      local params = args[k + 1]
      table.insert(ret_vals, inner_eval(tbl, params))
    end
  elseif args[1][2] == nil then
    local tbls = u.keys(args[1])
    for _, tbl in ipairs(tbls) do
      assert_tbl(self, tbl, "insert")
      local params = args[1][tbl]
      table.insert(ret_vals, inner_eval(tbl, params))
    end
  end

  fail_on_wrong_input(ret_vals)
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
  local method = "update"
  local args = {...}
  local ret_vals = {}

  local inner_eval = function(tbl, p)
    local sqlstmt = parse(tbl, method, {
      set = p.values,
      where = p.where,
      named = true,
    })
    return self:eval(sqlstmt, u.tbl_extend('force', p.values, p.where))
  end

  local unwrap_params = function(tbl, params)
    if not params then return end
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
    assert_tbl(self, tbl, "update")
    unwrap_params(tbl, params)
  elseif u.is_str(args[1][1]) then
    local tbls = args[1]
    for k, tbl in ipairs(tbls) do
      assert_tbl(self, tbl, "update")
      local params = args[k + 1]
      unwrap_params(tbl, params)
    end
  elseif args[1][2] == nil then
    local tbls = u.keys(args[1])
    for _, tbl in ipairs(tbls) do
      assert_tbl(self, tbl, "update")
      local params = args[1][tbl]
      unwrap_params(tbl, params)
    end
  end

  -- fail_on_wrong_input(ret_vals)
  return u.all(ret_vals, function(_, v) return v end)
end

--- same as insert but, mutates the sql_table with the new changes
---@varargs if {[1]} == table/content else table_name as {args[1]} and table with where to delete as {args[2]}.
---@return boolean: true incase the table was inserted successfully.
---@usage db:delete("todos")
---@usage db:delete("todos", { where = { id = 1 })
---@usage db:delete{ todos = { where = { id = 1 } }}
function sql:delete(...)
  local method = "delete"
  local args = {...}
  local ret_vals = {}

  local inner_eval = function(tbl, p)
    local sqlstmt = parse(tbl, method, {
      where = p and p.where or nil,
      named = true,
    })
    return self:eval(sqlstmt, p and p.where or nil)
  end

  if u.is_str(args[1]) then
    local tbl = args[1]
    assert_tbl(self, tbl, "delete")
    local params = args[2]
    table.insert(ret_vals, inner_eval(tbl, params))
  elseif u.is_str(args[1][1]) then
    local tbls = args[1]
    for k, tbl in ipairs(tbls) do
      assert_tbl(self, tbl, "delete")
      local params = args[k + 1]
      table.insert(ret_vals, inner_eval(tbl, params))
    end
  elseif args[1][2] == nil then
    local tbls = u.keys(args[1])
    for _, tbl in ipairs(tbls) do
      assert_tbl(self, tbl, "delete")
      local params = args[1][tbl]
      table.insert(ret_vals, inner_eval(tbl, params))
    end
  end

  fail_on_wrong_input(ret_vals)
  return u.all(ret_vals, function(_, v) return v end)
end

--- Query from a table with where and join options
---@usage db:get("todos") -- everything
---@usage db:get("todos", { where = { id = 1 })
---@usage db:get{ todos = { where = { id = 1 } }}
-- @return lua list of matching rows
function sql:select(...)
  local method = "select"
  local args = {...}
  local ret_vals = {}

  local inner_eval = function(tbl, p)
    local sqlstmt = parse(tbl, method, {
      select = p and p.select or nil,
      where = p and p.where or nil,
      join = p and p.join or nil,
      named = true,
    })
    return self:eval(sqlstmt, p and p.where)
  end

  if u.is_str(args[1]) then
    local tbl = args[1]
    assert_tbl(self, tbl, "select/get/find")
    local params = args[2]
    table.insert(ret_vals, inner_eval(tbl, params))
  elseif u.is_tbl(args[1]) then
    local tbl = u.keys(args[1])[1]
    local params = args[1][tbl]
    table.insert(ret_vals, inner_eval(tbl, params))
  end

  fail_on_wrong_input(ret_vals)
  if ret_vals[2] == nil and u.is_nested(ret_vals[1]) then
    return ret_vals[1]
  else
    return ret_vals
  end
end

--- Equivalent to |sql:insert|
function sql:find(...) return self:select(...) end

--- Equivalent to |sql:insert|
function sql:get(...) return self:select(...) end

--- Check if a table with {name} exists in sqlite db
function sql:exists(name)
  local q = self:eval("select name from sqlite_master where name= ?", name)
  return type(q) == "table" and true or false
end

return sql
