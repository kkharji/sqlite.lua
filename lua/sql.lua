local clib = require'sql.defs'
local stmt = require'sql.stmt'
local u = require'sql.utils'
local P = require'sql.parser'
local flags = clib.flags
local sql = {}
sql.__index = sql

local booleansql = function(value) -- TODO: should be done a clib level
  if type(value) == "boolean" then
    value = (value == true) and 1 or 0
  end
  return value
end

local fail_on_wrong_input = function(ret_vals)
  assert(#ret_vals > 0, 'sql.nvim: can\'t parse your input. Make sure it use that function correct')
end

-- TODO: should move to utils?
local assert_tbl = function(self, tbl, method)
  assert(self:exists(tbl),
  string.format("sql.nvim: %s table doesn't exists. %s failed.",
  tbl, method
  ))
end

function sql:__wrap_stmts(fn)
  self:__exec("BEGIN")
  fn()
  self:__exec("COMMIT")
  return
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
    clib.exec(self.conn,"pragma synchronous = off", nil, nil, nil)
    clib.exec(self.conn,"pragma journal_mode = wal", nil, nil, nil)
  else
    error(string.format("sql.nvim: couldn't connect to sql database, ERR:", code))
  end
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

--- Main sqlite interface. This function evaluates {statement} and if there are
--- results from evaluating it then the function returns list of row(s). Else, it
--- returns a boolean indecating whether the evaluation was successful - or not-
--- Optionally, the function accept {params} which can be a dict of values corresponding
--- to the sql statement or a list of unamed values.
---@param statement string or table: string representing the {statement} or a list of {statements}
---@param params table: params to be bind to {statement}, it can be a list or dict
---@usage db:eval("drop table if exists todos")
---@usage db:eval("select * from todos where id = ?", 1)
---@usage db:eval("insert into t(a, b) values(:a, :b)", {a = "1", b = 2021})
---@return boolean or table
function sql:eval(statement, params)
  local res = {}
  local s = self:__parse(statement)

  -- when the user provide simple sql statements
  if not params then
    s:each(function()
      table.insert(res, s:kv())
    end)
    s:reset()

  -- when the user run eval("select * from ?", "tbl")
  elseif type(params) ~= "table" and statement:match('%?') then
    local value = booleansql(params)
    s:bind({value})
    s:each(function(stm)
      table.insert(res, stm:kv())
    end)
    s:reset()
    s:bind_clear()

  -- when the user provided named keys
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
  -- clear out the parsed statement.
  s:finalize()

  -- if no rows is returned, then check return the result of errcode == flags.ok
  res = rawequal(next(res), nil) and self:__last_errcode() == flags.ok or res

  -- fix res of its table, so that select all doesn't return { [1] = {[1] = { row }} }
  if type(res) == "table" and res[2] == nil and u.is_nested(res[1]) then
    res = res[1]
  end

  assert(self:__last_errcode() == flags.ok , string.format(
  "sql.nvim: :eval has failed to execute statement, ERRMSG: %s",
    self:__last_errmsg()
  ))

  return res
end

--- Wrapper around stmt module for convenience.
---@param statement string: statement to be parsed.
---@return table: stmt object
function sql:__parse(statement) return stmt:parse(self.conn, statement) end

--- wrapper around clib.exec for convenience.
---@param statement string: statement to be executed.
---@return table: stmt object
function sql:__exec(statement) return clib.exec(self.conn, statement, nil, nil, nil) end

--- Creates a new sql.nvim object, without creating a connection to uri
--- |sql.new| is identical to |sql.open| but it without opening sqlite db connection.
---@param uri string: if uri is nil, then create in memory database.
---@usage `sql.new()`
---@usage `sql.new("./path/to/sql.sqlite")`
---@usage `sql:new("$ENV_VARABLE")`
---@return table: sql.nvim object
---@see |sql.open|
function sql.new(uri) return sql:open(uri, true) end

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

--- Returns current connection status
--- Get last error code
---@todo: decide whether to keep this function
---@return table: msg,code,closed
function sql:status() return { msg = self:__last_errmsg(), code = self:__last_errcode() } end

--- Insert to lua table into sqlite database table.
---@params tbl string: the table name
---@params rows table: rows to insert to the table.
---@return boolean: true incase the table was inserted successfully.
---@usage db:insert("todos", { title = "new todo" })
---@todo support unnamed or anonymous args
---@todo handle inconflict case
function sql:insert(tbl, rows)
  assert_tbl(self, tbl, "insert")
  local tbl_sch = self:eval(string.format("pragma table_info(%s)",  tbl))
  local tbl_keys = {}
  local succ

  for _, v in ipairs(tbl_sch) do
    tbl_keys[v.name] = 'null'
  end

  self:__wrap_stmts(function()
    local s = self:__parse(P.insert(tbl, { values = tbl_keys }))
    rows = u.is_nested(rows) and rows or {rows}
    for _, v in ipairs(rows) do
      s:bind(v)
      s:step()
      s:reset()
      s:bind_clear()
    end
    succ = s:finalize()
  end)

  return succ
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
  local istbl = function(tbl)
    return assert_tbl(self, tbl, "update")
  end

  local inner_eval = function(tbl, p)
    local sqlstmt = P.update(tbl, {
      set = p.values,
      where = p.where,
      named = true,
    })
    return self:eval(sqlstmt, p and p.values)
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
    istbl(tbl)
    unwrap_params(tbl, params)
  elseif u.is_str(args[1][1]) then
    local tbls = args[1]
    for k, tbl in ipairs(tbls) do
      istbl(tbl)
      local params = args[k + 1]
      unwrap_params(tbl, params)
    end
  elseif args[1][2] == nil then
    local tbls = u.keys(args[1])
    for _, tbl in ipairs(tbls) do
      istbl(tbl)
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
  local args = {...}
  local ret_vals = {}
  local istbl = function(tbl)
    return assert_tbl(self, tbl, "delete")
  end
  local inner_eval = function(tbl, p)
    local sqlstmt = P.delete(tbl, {
      where = p and p.where or nil,
      named = true,
    })
    return self:eval(sqlstmt)
  end

  if u.is_str(args[1]) then
    local tbl = args[1]
    istbl(tbl)
    local params = args[2]
    table.insert(ret_vals, inner_eval(tbl, params))
  elseif u.is_str(args[1][1]) then
    local tbls = args[1]
    for k, tbl in ipairs(tbls) do
      istbl(tbl)
      local params = args[k + 1]
      table.insert(ret_vals, inner_eval(tbl, params))
    end
  elseif args[1][2] == nil then
    local tbls = u.keys(args[1])
    for _, tbl in ipairs(tbls) do
      istbl(tbl)
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
  local args = {...}
  local ret_vals = {}
  local istbl = function(tbl)
    return assert_tbl(self, tbl, "select")
  end

  local inner_eval = function(tbl, p)
    local sqlstmt = P.select(tbl, {
      select = p and p.select or nil,
      where = p and p.where or nil,
      join = p and p.join or nil,
      named = true,
    })
    return self:eval(sqlstmt)
  end

  if u.is_str(args[1]) then
    local tbl = args[1]
    istbl(tbl)
    local params = args[2]
    table.insert(ret_vals, inner_eval(tbl, params))
  elseif u.is_tbl(args[1]) then
    local tbl = u.keys(args[1])[1]
    istbl(tbl)
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

--- Check if a table with {name} exists in sqlite db
function sql:exists(name)
  local q = self:eval("select name from sqlite_master where name= ?", name)
  return type(q) == "table" and true or false
end

return sql
