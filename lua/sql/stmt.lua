local ffi = require'ffi'
local sqlite = require'sql.defs'
local uv = vim.loop
local flags = sqlite.flags
local M = {}
M.__index = M

local tostr = function(ptr, len)
  if ptr == nil then return end
  return ffi.string(ptr, len)
end

local eval = function(conn, stmt, callback, arg1, errmsg)
  return sqlite.exec(conn, stmt, callback, arg1, errmsg)
end

--- M.parse
-- Compile sql statement into an internal rep
-- @returns collection of methods to be applicable to the parsed statement..
function M:parse(conn, stmt)
  local obj = {}
  obj.str = stmt
  obj.conn = conn
  obj.pstmt = (function()
    local pstmt = ffi.new('sqlite3_stmt*[1]')
    local code  = sqlite.prepare_v2(obj.conn, obj.str, #obj.str, pstmt, nil);
    if code ~= flags.ok then return code end
    return pstmt[0]
  end)()
  obj.finalized = false
  setmetatable(obj, self)
  return obj
end

---  M.reset
-- resets the parsed statement so that it is ready to be re-executed. Any
-- statement variables that had values bound to them using the stmt:bind
-- functions retain their values.
function M:reset()
  return sqlite.reset(self.pstmt)
end

--- M.finalize
-- Frees the prepared statement
-- @return sqlite code, ok if successful
-- @raise error if code ~= sqlite.ok
function M:finalize()
  self.errcode = sqlite.finalize(self.pstmt)
  self.finalized = self.errcode == flags.ok
  return self.errcode
end

--- M.step
-- A function that must be called to evaluate the (next iteration) of the
-- prepared statement
-- @return sqlite code:
-- flags.busy: unable to acquite the locks needs
-- flags.done: finished executing.
-- flags.row: row of data
-- flags.error: runtime error
-- flags.misuse: the statement may have been already finalized.
function M:step()
  return sqlite.step(self.pstmt)
end


--- M.next
-- If code == flags.row it returns
-- if code == flags.done it reset the parsed statement
-- else
function M:next(self)
  local code = self:step()
  if code == flags.row then
    return M
  elseif code == flags.done then
    self:reset()
  else
    return nil, code
  end
end

function M:iter(self)
  return self:next(), self.pstmt
end

--- M.loop
-- loops through the parsed statement until there is no row left from the
-- parsed statement.
function M:loop(func)
  while self:step() == flags.row do
    func(self.conn, self.pstmt)
  end
  return self:finalize()
end

local conn = (function(uri)
  local conn = ffi.new('sqlite3*[1]')
  local code = sqlite.open(uri, conn)
  if code == flags.ok then
    return conn[0]
  else
    error(string.format(
    "sql.nvim: couldn't connect to sql database, ERR:",
    code))
  end
end)(":memory:")




print(vim.inspect(eval(conn, "create table people(id integer primary key, name text, age  integer);")))
eval(conn, "insert into people (name, age) values ('normin', 'sam');")

local S = M:parse(conn, "select * from people;")

-- local tst = stmt.new(test.conn, "select * from people;")
-- print(vim.inspect(tst))
S:loop(function(_,s)
  print(tostr(sqlite.column_text(s, 1)))
  print(tostr(sqlite.column_text(s, 2)))
end)

print(vim.inspect(S))

-- print(vim.inspect(misc.stmt_iter(stmt.new(test.conn, ).pstmt)))
-- return M
