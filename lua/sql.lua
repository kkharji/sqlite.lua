local ffi = require'ffi'
local sqlite = require'sql.defs'
local F = require'sql.func'
local uv = vim.loop
local flags = sqlite.flags
local sql, misc = {}, {}

------------------------------------------------------------
-- C interop -- properly to be moved to sql.defs
------------------------------------------------------------
-- returns lua string from the data pointed to by ptr.
misc.tostr = function(ptr, len)
  if ptr == nil then return end
  return ffi.string(ptr, len)
end

-- Returns errmsg associated with the most recent failed call.
misc.last_errmsg = function(conn) -- returns string
  return misc.tostr(sqlite.errmsg(conn))
end

-- Returns error code associated with the most recent failed call.
misc.last_errcode = function(conn) -- returns number
  return sqlite.errcode(conn)
end

------------------------------------------------------------
-- SQL Database interaction functions
------------------------------------------------------------
sql.__index = sql

-- Creates a new sql.nvim sql object.
--- sql.open
-- Establishes connection to `url` and return sql.nvim object.
--   If no url is given then it should default to ":memory:".
-- @param url string optional
-- @usage `sql.open()`
-- @usage `sql.open("./path/to/sql.sqlite")`
-- @usage `sql.open("$ENV_VARABLE")`
-- @return sql.nvim object
sql.open = function(...) -- returns obj
  local args = {...}
  local o = {
    -- TODO: what if the users passes an already created object?
    uri = args[1] == "string" and args[1] or ":memory:",
    -- checks if conn isopen
    created = os.date('%Y-%m-%d %H:%M:%S'),
    -- better if we use os.time instead?
    closed = false,
    -- check if conn isclosed
    isopen = function(self) return not self.closed end,
    isclose = function(self) return self.closed end,
  }

  -- in case we want support open_v2, to provide control over how
  -- the database file is opened.
  --[[
  obj.flags = args[2], -- file open operations.
  obj.vfs = args[3], -- VFS (Virtual File System) module to use
  -- ]]

  o.conn = (function(uri)
    -- TODO: support reconnecting
    -- If the sql is already opened then return it??
    -- if the sql is dead and uri not :memory:, then reopen it??
    local conn = ffi.new('sqlite3*[1]')
    local code = sqlite.open(uri, conn)
    if code == flags.ok then
      return conn[0]
    else
      -- throw err?, use nvim api?
      error(string.format(
        "sql.nvim: couldn't connect to sql database, ERR:",
      code))
      o.closed = true
      -- or charge obj.closed to true?
    end
  end)(o.uri)

  setmetatable(o, sql)
  return o
end

-- Returns current connection status
sql.status = function(self) -- returns string
  local conn = self.conn or self
  return {
    -- perhaps we should process those and return eg. error = false
    msg = misc.last_errmsg(conn),
    code = misc.last_errcode(conn),
    closed = self.closed,
  }
end

--- sql.close
-- closes sql db connection
-- @param conn the database connection
-- @usage `db:close()`
-- @return boolean
sql.close = function(self)
  -- TODO: check conn status before closing
  -- like is it busy? .. misc.check_conn
  self.closed = sqlite.close(self.conn) == 0
  return self.closed
end

--- sql.eval
-- evaluates sql statement and returns true if successful else error-out
--  It should append `;` to `statm`
-- @param conn the database connection
-- @param statm (string/array)
-- @usage `db:exec("drop table if exists todos")`
-- @usage `db:exec("create table todos")`
-- @return boolean
-- @raise error with sqlite3 msg
sql.eval = function(self, stmt, callback)
  local cstr,code,lstr,arg1
  -- cstr = ffi.new('char*[1]')
  code = sqlite.exec(self.conn, stmt, callback, arg1, cstr)
  -- lstr = misc.tostr(cstr[0])
  -- sqlite.free(cstr)
  if code == flags.ok then
    return true
  else
    return false
  end
end

------------------------------------------------------------
-- Sugur over exec function.
------------------------------------------------------------

--- sql.query
-- Execute a query against sqlite `conn`.
--  It should append `;` to `statm`
-- @param `conn` the database connection.
-- @param `statm` the sql query statement (string).
-- @param `params` lua table.
-- @usage `db:query("select * from post where body = :body", {body = "body 2"})`
-- @usage `db:query("select * from todos where id = :id" {id = 1})`
-- @return table
sql.query = function(self) end

--- sql.insert
-- Inserts data to a sql_table..
--- It should append `;` to `statm`
--- It should handle arrays as well as tables.
-- @param `conn` the database connection.
-- @param `tbl_name` the sqlite table name.
-- @param `params` lua table or array.
-- @usage
-- db:insert("todos", {
--     title = "create something",
--     desc = "something that users can be build upon.",
--     created = os.time()
-- })
-- @return the primary_key/true? or error.
sql.insert = function(self) end

--- sql.update
-- same as insert but, mutates the sql_table with the new changes
--- It should append `;` to `statm`
--- It should handle arrays as well as tables.
-- @param `conn` the database connection.
-- @param `tbl_name` the sqlite table name.
-- @param `id` sqlite row id
-- @param `params` lua table or array.
-- @usage
-- db:update("todos", 1, {
--   title = "create sqlite3 bindings",
--   desc = "neovim users can be build upon new interesting utils.",
-- }) --> true or error.
-- @return the primary_key/true? or error.
sql.update = function(self) end

--- sql.delete
-- same as insert but, mutates the sql_table with the new changes
--- It should append `;` to `statm`
--- It should handle arrays as well as tables.
-- @param `conn` the database connection.
-- @param `id` sqlite row id
-- @usage `db:delete("todos", 1)`
-- @return true or error.
sql.delete = function(self) end

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
sql.find = function(self, params, opts) end

return sql
