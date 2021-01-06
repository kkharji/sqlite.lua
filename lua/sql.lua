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
sql.open = function(uri)
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

print(vim.inspect(parse_where({k = 1, e = 2})))
--- Internal function for parsing
---@params act string: the sqlite action [insert, delete, update, drop, create]
-- TODO: refactor this mess!!!!
function sql:parse(act, o)
  act = act == "insert" and "insert into" or act
  tbl_name = o.tbl and o.tbl or ""
  local t = {
    act,
    tbl_name,
    parse_keys(o.values),
    parse_values(o.placeholders, o.values),
    parse_set(o.set),
    parse_where(o.where),
  }
  -- ret = table.concat(t, " ")
  -- assert(not o.debug, "parse result: " .. '"' .. ret .. '"')
  return t
end

print(vim.inspect(sql.parse("update", {
  tbl = "todos",
  where = {
    deadline = 2051,
    id = 11,
  },
  set = {
    title = "Fuck you",
  }
})))

------------------------------------------------------------
-- Sugur over eval function.
------------------------------------------------------------

--- WIP: Execute a complex queries against a table. e.g. contains, is,
---@usage `db:query("todos", {:contains "conni"})`
---@usage `db:query("todos", {:is {deadline = 2021})`
---@usage `db:query("todos", {:not {title = "X"})` < function(t) return t ~= end
---@usage `db:query("any", {:deadline function(d) return d < 2021 end})`
---@todo write function specification.
---@return table
function sql:query() end

--- Insert to lua table into sqlite database table.
--- +supports inserting multiple rows.
---@varargs if {[1]} == table/content else table_name as {args[1]} and table to insert as {args[2]}.
---@return boolean: true incase the table was inserted successfully.
---@usage db:insert("todos", { title = "new todo" })
---@usage db:insert{ todos = {title = "new todo"} }
---@todo insert into multiple tables at the same time.
---@todo support unnamed or anonymous args
---@todo handle inconflict case
function sql:insert(...)
  local args = {...}
  local tbl = u.is_str(args[1]) and args[1] or u.keys(args[1])[1]
  local params = u.is_tbl(args[2]) and args[2] or args[1][tbl]

  -- assert(self:exists(tbl),
  --   string.format("sql.nvim: can't insert to non-existence table: '%s'.",
  --   tbl
  -- ))

  return self:eval(self:parse("insert", {
    tbl = tbl,
    values = params,
    placeholders = true,
  }), params)
end

--- Equivalent to |sql:insert|
function sql:add(...) return sql:insert(...) end

--- Update table row under certine
---@varargs if {[1]} == table/content else table_name as {args[1]} and table to insert as {args[2]}.
---@return boolean: true incase the table was inserted successfully.
---@usage db:update{ tbl = "todos", where = { id = "1" }, content = { action = "FIXME" }}
---@todo support unnamed or anonymous args
function sql:update(opts)
  -- assert(self:exists(tbl), -- FIXME
  --   string.format("sql.nvim: can't insert to non-existence table: '%s'.",
  --   opts.tbl
  -- ))
  -- TODO check for content
  -- return self:eval(self:parse("update", {
  --   tbl = opts.tbl,
  --   where = opts.where,
  --   set = opts.values,
  -- }), vim.tbl_extend("keep", opts.values, opts.where))
  -- return table.concat(where, ",")
  return opts
end

-- local db = sql.open()
-- db:eval("create table todos(id int, title text, deadline int)")
-- db:insert("todos", {
--   id = 11,
--   deadline = 2051,
--   title = "whats wrong with you"
-- })
-- db:insert("todos", {
--   id = 1,
--   deadline = 20,
--   title = "fd"
-- })
-- db:insert("todos", {
--   id = 11,
--   deadline = 2051,
--   title = "whats wrong with you"

-- })
-- print(vim.inspect(sql:update({
--   tbl = "todos",
--   where = {
--     deadline = 2051,
--     id = 11,
--   },
--   values = {
--     title = "Fuck you",
--   }
-- })))
-- print(vim.inspect(db:eval("select * from todos")))
--- sql.delete
-- same as insert but, mutates the sql_table with the new changes
--- It should append `;` to `statm`
--- It should handle arrays as well as tables.
-- @param `conn` the database connection.
-- @param `id` sqlite row id
-- @usage `db:delete("todos", 1)`
-- @return true or error.
function sql:delete()

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
