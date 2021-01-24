local clib = require'sql.defs'
local stmt = require'sql.stmt'
local u = require'sql.utils'
local t = require'sql.table'
local P = require'sql.parser'
local flags = clib.flags
local sql = {}
sql.__index = sql

function sql:__assert_tbl(tbl, method)
  assert(self:exists(tbl),
  string.format("sql.nvim: can not execute %s, %s doesn't exists.",
  method, tbl
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
    -- TODO should be optional or incase of bulk insert
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
  o.modified = false
  o:__connect()
  return o
end

--- closes sqlite db connection.
---@usage `db:close()`
---@return boolean: true if closed, error otherwise.
function sql:close()
  if self.closed then return true end
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

  local res = func(self)
  self:close()
  return res
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
    local value = P.sqlvalue(params)
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
  self.modified = true
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

--- Check if a table with {name} exists in sqlite db
---@param name string: the table name.
---@return boolean
function sql:exists(name)
  local q = self:eval("select name from sqlite_master where name= ?", name)
  return type(q) == "table" and true or false
end

--- get sql table {name} schema, if table doesn't exist then return empty table.
---@param tbl string: the table name
---@param info boolean: whether to return table info. default false.
---@return table: list of keys or keys and their type.
function sql:schema(tbl, info)
  local tbl_sch = self:eval(string.format("pragma table_info(%s)",  tbl))
  if type(tbl_sch) == "boolean" then return {} end
  if info then
    local tbl_info = {}
    local req = {}
    local def = {}
    local types = {}

    for _, v in ipairs(tbl_sch) do
      tbl_info[v.name] = {
        required = v.notnull == 1,
        primary = v.ok == 1,
        type = v.type,
        cid = v.cid,
        default = v.dflt_value
      }
    end

    for k, v in pairs(tbl_info) do
      if v.required then
        req[k] = v
      elseif v.default then
        def[k] = v.default
      end
      types[k] = v.type
    end

    return {
      info = tbl_info,
      req = req == {} and nil or req,
      def = def == {} and nil or def,
      types = types
    }
  else
    local key_types = {}
    for _, v in ipairs(tbl_sch) do
      key_types[v.name] = v.type
    end
    return key_types
  end
end

--- Create a new sqlite db table with {name} based on {schema}. if {schema.ensure} then
--- create only when it doesn't exists. similar to 'create if not exists'
---@param name string: table name
---@param schema table: the table keys/column and their types
---@usage `db:create("todos", {id = {"int", "primary", "key"}, title = "text"})`
---@return boolean
function sql:create(name, schema) return self:eval(P.create(name, schema)) end

--- Create a new sqlite db table with {name} based on {schema}. if {schema.ensure} then
--- create only when it doesn't exists. similar to 'create if not exists'
---@param name string: table name
---@usage `db:drop("todos")`
---@return boolean
function sql:drop(name) return self:eval(P.drop(name)) end


local fail_on_wrong_input = function(ret_vals)
  assert(#ret_vals > 0, 'sql.nvim: can\'t parse your input. Make sure it use that function correct')
end

function sql:pre_insert(rows, info)
  rows = u.is_nested(rows) and rows or { rows }
  for _, row in ipairs(rows) do
    for k, _ in pairs(info.req) do
      if not row[k] then
        error("sql.nvim: (insert) missing a required key: " .. k)
      end
    end

    -- for k, v in pairs(info.def) do
    --   if not row[k] then
    --     row[k] = v
    --   elseif row[k] == "null" then
    --     row[k] = nil
    --   end
    -- end
  end
  -- TODO: do value interop here.
  return rows
end

--- Insert to lua table into sqlite database table.
---@params tbl string: the table name
---@params rows table: rows to insert to the table.
---@return boolean: true incase the table was inserted successfully.
---@usage db:insert("todos", { title = "new todo" })
---@todo support unnamed or anonymous args
---@todo handle inconflict case
function sql:insert(tbl, rows)
  self:__assert_tbl(tbl, "insert")
  local ret_vals = {}
  local info = self:schema(tbl, true)
  local items = self:pre_insert(rows, info)
  self:__wrap_stmts(function()

    for _, v in ipairs(items) do
      local s = self:__parse(P.insert(tbl, { values = v }))
      s:bind(v)
      s:step()
      s:bind_clear()
      table.insert(ret_vals, s:finalize())
    end
    -- succ = s:finalize()
  end)

  local succ = u.all(ret_vals, function(_, v) return v end)
  if succ then self.modified = true end
  return succ
end

--- Update table row with where closure and list of values
---@param tbl string: the name of the db table.
---@param specs table: a {spec} or a list of {specs} with where and values key.
---@return boolean: true incase the table was updated successfully.
---@usage `db:update("todos", { where = { id = "1" }, values = { action = "DONE" }})`
function sql:update(tbl, specs)
  self:__assert_tbl(tbl, "update")
  local ret_vals = {}
  if not specs then return false end
  specs = u.is_nested(specs) and specs or {specs}

  self:__wrap_stmts(function()
    for _, v in ipairs(specs) do
      local s = self:__parse(P.update(tbl, { set = v.values, where = v.where }))
      s:bind(v.values)
      s:step()
      s:reset()
      s:bind_clear()
      table.insert(ret_vals, s:finalize())
    end
  end)

  fail_on_wrong_input(ret_vals)
  local succ = u.all(ret_vals, function(_, v) return v end)
  if succ then
    self.modified = true
  end
  return succ
end

--- Delete a {tbl} row/rows based on the {specs} given. if no spec was given,
--- then all the {tbl} content will be deleted.
---@param tbl string: the name of the db table.
---@param specs table: a {spec} or a list of {specs} with where and values key.
---@return boolean: true if operation is successfully, false otherwise.
---@usage db:delete("todos")
---@usage db:delete("todos", { where = { id = 1 })
---@usage db:delete("todos", { where = { id = {1,2,3} })
function sql:delete(tbl, specs)
  self:__assert_tbl(tbl, "delete")
  local ret_vals = {}
  if not specs then
    return self:__exec(P.delete(tbl)) == 0 and true or self:__last_errmsg()
  end

  specs = u.is_nested(specs) and specs or {specs}
  self:__wrap_stmts(function()
    for _, spec in ipairs(specs) do
      local s = self:__parse(P.delete(tbl, { where = spec and spec.where or nil}))
      s:step()
      s:reset()
      table.insert(ret_vals, s:finalize())
    end
  end)

  local succ = u.all(ret_vals, function(_, v) return v end)
  if succ then self.modified = true end
  return succ
end

--- Query from a table with where and join options
---@usage db:get("todos") -- everything
---@usage db:get("todos", { where = { id = 1 })
-- @return lua list of matching rows
function sql:select(tbl, spec)
  self:__assert_tbl(tbl, "select")
  local ret = {}
  if not spec then
    return self:eval(P.select(tbl))
  end

  self:__wrap_stmts(function()
    if spec.keys then spec.select = spec.keys end
    local s = self:__parse(P.select(tbl, {
      select = spec and spec.select or nil,
      where = spec and spec.where or nil,
      join = spec and spec.join or nil,
    }))
    ret = s:kvrows()
    s:reset()
    s:finalize()
  end)
  self.modified = false
  return ret
end

--- Create new sql-table object.
---@param tbl_name string: the name of the table. can be new or existing one.
---@return table
function sql:table(tbl_name, opts)
  return t:new(self, tbl_name, opts)
end

return sql
