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
function M:next()
  local code = self:step()
  if code == flags.row then
    return M
  elseif code == flags.done then
    self:reset()
  else
    return nil, code
  end
end

function M:iter()
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

local bind_type_to_func = {
  ['number'] = 'double', -- bind_double
  ['string'] = 'text',   -- bind_text
  ['nil'] = 'null',      -- bind_null
}

--- M:bind
-- binds values to indices. Type will be determined. For number is will bind
-- with double, for string it will bind with text and for nil it will bind_null
-- @param index: index starting at 1
-- @param value: value to bind
-- @return sqlite code
function M:bind(index, value)
  local func = bind_type_to_func[type(value)]
  local len = func == 'text' and #value or nil
  if not func then return flags.error end

  if len then
    return sqlite['bind_' .. func](self.pstmt, index, value, len, nil)
  else
    if value then
      return sqlite['bind_' .. func](self.pstmt, index, value)
    else
      return sqlite['bind_' .. func](self.pstmt, index)
    end
  end
end

--- M:bind_blob
-- Will bind a blob at index with size
-- @param index: index starting at 1
-- @param pointer: blob to bind
-- @param size: pointer size
-- @return sqlite code
function M:bind_blob(index, pointer, size)
  return sqlite.bind_blob64(self.pstmt, index, pointer, size, nil) -- Always 64? or two functions
end

--- M:bind_value
-- Will bind a value with type `sqlite.flags.`
-- @param index: index starting at 1
-- @param pointer: value to bind
-- @param type: type of value `sqlite.flags.` { integer, float, text, blob, null }
-- @return sqlite code
function M:bind_value(index, value, type)
  return sqlite.bind_value(self.pstmt, index, value, type)
end

--- M:bind_pointer
-- Will bind a pointer with type at the index
-- @param index: index starting at 1
-- @param pointer: pointer of type
-- @param type: type of value `sqlite.flags.` { integer, float, text, blob, null }
-- @return sqlite code
function M:bind_pointer(index, pointer, type)
  return sqlite.bind_pointer(self.pstmt, index, pointer, type)
end

--- M:bind_zeroblob
-- Will bind zeroblob at index with size
-- @param index: index starting at 1
-- @param size: zeroblob size
-- @return sqlite code
function M:bind_zeroblob(index, size)
  return sqlite.bind_zeroblob64(self.pstmt, index, size) -- Should we always use 64 here?
end

--- M:param_size
-- Will return the parameter count
-- @return count
function M:param_size()
  if not self.parm_count then
    self.parm_count = sqlite.bind_parameter_count(self.pstmt)
  end

  return self.parm_count
end

--- M:param_name
-- Will return the parameter name at index
-- @param index: index starting at 1. If nil return all param_names
-- @return string or table
function M:param_name(index)
  if index then
    return tostr(sqlite.bind_parameter_name(self.pstmt, index))
  end

  local res = {}
  for i = 1, self:param_size() do
    table.insert(res, (self:param_name(i) or '?'))
  end
  return res
end

--- M:clear_bindings
-- Will clear the current bindings
-- @return sqlite code
function M:clear_bindings()
  self.current_bind_index = nil
  return sqlite.clear_bindings(self.pstmt)
end

--- M:bind_names
-- Bind a table to indicies, named and unnamed
-- @param names: table:
--  { ['named'] = val, ['named_2'] = val2, val3, val4 }
--  val3 will be unnamed and will be bind to the first ?
--  val4 will be unnamed and will be bind to the second ?
-- @return sqlite code
function M:bind_names(names)
  local parameter_index_cache = {}
  local anon_indices = {}
  for i = 1, self:param_size() do
    local name = self:param_name(i)
    if name == nil then
      table.insert(anon_indices, i)
    else
      parameter_index_cache[name:sub(2, -1)] = i
    end
  end

  for k, v in pairs(names) do
    local index = parameter_index_cache[k] or table.remove(anon_indices, 1)
    local ret = self:bind(index, v)
    if ret ~= flags.ok then return ret end
  end
  return flags.ok
end

--- M:bind_next_value
-- Bind the value at the next index until all values are bound
-- clear_bindings() will reset the next index
-- @param value: value to bind
-- @return sqlite code
function M:bind_next_value(value)
  if not self.current_bind_index then
    self.current_bind_index = 1
  end

  if self.current_bind_index <= self:param_size() then
    local ret = self:bind(self.current_bind_index, value)
    self.current_bind_index = self.current_bind_index + 1
    return ret
  end
  return flags.error
end

print(vim.inspect(eval(conn, "create table people(id integer primary key, name text, age integer);")))
local S = M:parse(conn, "insert into people (name, age) values (?, :age)")
-- local S = M:parse(conn, "insert into people (name, age) values (:name, ?)")
-- local person = { ['age'] = 100, 'tami' }
-- local person = { ['name'] = 'conni', 22 }
-- S:bind_names(person)
print(S:bind_next_value('tami'))
print(S:bind_next_value(100))
print(S:bind_next_value('conni'))
S:clear_bindings()
print(S:bind_next_value('conni'))
print(S:bind_next_value(22))

-- local tst = stmt.new(test.conn, "select * from people;")
-- print(vim.inspect(tst))
S:loop(function(_,s)
  print(tostr(sqlite.column_text(s, 1)))
  print(tostr(sqlite.column_text(s, 2)))
end)

print(vim.inspect(S))

-- print(vim.inspect(misc.stmt_iter(stmt.new(test.conn, ).pstmt)))
-- return M
