local ffi = require'ffi'
local sqlite = require'sql.defs'
local flags = sqlite.flags

local M = {}
M.__index = M

local tostr = function(ptr, len)
  if ptr == nil then return end
  return ffi.string(ptr, len)
end

--- M:parse
-- Compile sql statement into an internal rep
-- @returns collection of methods, applicable to the parsed statement..
function M:parse(conn, stmt)
  local o = {
    str = stmt,
    conn = conn,
    finalized = false,
  }
  setmetatable(o, self)
  o:__parse()
  return o
end

--- M:__parse
-- Compile sql statement into an internal rep.
-- Required to reparse the sql statement after finalized.
-- @returns parsed sql statement
-- @raise error if the statement couldn't be parsed
-- TODO: make it set self.pstmt when called
function M:__parse()
  local pstmt = ffi.new('sqlite3_stmt*[1]')
  local code  = sqlite.prepare_v2(self.conn, self.str, #self.str, pstmt, nil);
  if code ~= flags.ok then
    return error(string.format(
      "sql.nvim: couldn't parse sql statement, ERRMSG: ",
    tostr(sqlite.errmsg(self.conn))))
  end
  self.pstmt = pstmt[0]
end

--- M:reset
-- resets the parsed statement.
-- This is required so that we can re-executed the parse statement.
-- NOTE: Any statement variables that had values bound to them using the
-- stmt:bind functions retain their values.
function M:reset()
  return sqlite.reset(self.pstmt)
end

--- M:finalize
-- Frees the prepared statement
-- @return sqlite code, ok if successful
function M:finalize()
  self.errcode = sqlite.finalize(self.pstmt)
  self.finalized = self.errcode == flags.ok
  return self.errcode
end

--- M:step
-- Called before evaluating the (next iteration) of the prepared statement.
-- @return sqlite code:
-- flags.busy: unable to acquite the locks needs
-- flags.done: finished executing.
-- flags.row: row of data
-- flags.error: runtime error
-- flags.misuse: the statement may have been already finalized.
function M:step()
  return sqlite.step(self.pstmt)
end

--- M:nkeys
-- @return number: column count in the results
function M:nkeys()
  return sqlite.column_count(self.pstmt)
end

--- M:nrows
-- @return number: rows count in the results.
-- TODO(tami)
function M:nrows()

end

--- M:keys
-- if idx then return the keyname of that idx, else return an array of keys
-- names i.e. column names.
-- @param @optional index (0-index)
-- @return if idx string, else array
function M:key(idx)
  if self.finalized then self:__parse() end
  return tostr(sqlite.column_name(self.pstmt, idx))
end

--- M:keys
-- if idx then return the keyname of that idx, else return an array of keys
-- names i.e. column names.
-- @param @optional index (0-index)
-- @return if idx string, else array
function M:keys()
  local keys = {}
  for i = 0, self:nkeys() - 1 do
    table.insert(keys, i + 1, self:key(i))
  end
  return keys
end

local sqlite_datatypes = {
  [1] = 'int', -- bind_double
  [2] = 'float',   -- bind_text
  [3] = 'text',      -- bind_null
  [4] = 'blob',      -- bind_null
  [5] = 'null',      -- bind_null
}

--- M:type
-- sqlite key/column datatype at`idx`
-- @param index: (0-index)
-- @return string
function M:type(idx)
  local convert_dt = {
    ['integer'] = "number",
    ['float'] = "number",
    ['double'] = "number",
    ['text'] = "string",
    ['blob'] = "binary",
    ['null'] = nil
  }
  if self.finalized then self:__parse() end
  return convert_dt[tostr(sqlite.column_decltype(self.pstmt, idx))]
end

--- M:types
-- Return all the keys/columns types visible in current result
-- @return  array of types in ordered by key location.
function M:types()
  local types = {}
  for i = 0, self:nkeys() - 1 do
    table.insert(types, i + 1, self:type(i))
  end
  return types
end

function M:val(idx)
-- TODO: transform booleans 0/1 to false/true, but how??
  if self.finalized then -- TODO: create M:__check_parsed()
    self:__parse()
  end
  local ktype = sqlite.column_type(self.pstmt, idx)
  if ktype == 5 then return end
  local val = sqlite["column_" .. sqlite_datatypes[ktype]](self.pstmt, idx)
  return ktype == 3 and tostr(val) or val
end

--- M:vals
-- ordered list of current query reslut values.
-- @return list of values
function M:vals()
  local vals = {}
  for i = 0, self:nkeys() - 1 do
    table.insert(vals, i + 1, self:val(i))
  end
  return vals
end

--- M:kv
-- return key value pairs of results
-- @return table of key value pair of a row.
-- TODO: is it important to get idx based key value pair?
-- TODO: It should get all the key value pairs of each return row
--      It currently works with loop/each function only.
function M:kv()
  local ret = {}
  -- if self.finalized then self.pstmt = self:__parse() end
  for i = 0, self:nkeys() - 1 do
    ret[self:key(i)] = self:val(i)
  end
  return ret
end

--- M:kt
-- @return key/value pairs of the keys and their type
-- TODO: is it important to get idx based key value pair?
function M:kt()
  if self.finalized then self:__parse() end
  local ret = {}
  for i = 0, self:nkeys() - 1 do
    ret[self:key(i)] = self:type(i)
  end
  return ret
end

--- M:next
-- If code == flags.row it returns
-- if code == flags.done it reset the parsed statement
-- TODO(conni): should this be removed?
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

--- M:each
-- loops through the parsed statement until there is no row left from the
-- parsed statement.
function M:each(callback)
  while self:step() == flags.row do
    callback(self)
  end
end

--- M:kvrows
-- loops through the parsed statement and return callback(row) or a nested
-- table of kv pairs.
-- @return if not callback table: key-value pairs of all the rows.
-- @return if callback, call with a key-value pair of a row
function M:kvrows(callback)
  local kv = {}
  self:each(function()
    local row = self:kv()
    if callback then
      return callback(row)
    else
      table.insert(kv, row)
    end
  end)
  if not callback then
    -- self:finalize()
    -- @conni does this make sense to have? or do we require
    -- it to be called explicitly?
    return kv
  end
end

--- M:kvrows
-- loops through the parsed statement and return callback(row) or a nested
-- table of row values
-- @return if not callback table: nested list of all rows values.
-- @return if callback, call with a row values
function M:vrows(callback)
  local vals = {}
  self:each(function(s)
    local row = s:vals()
    if callback then
      return callback(row)
    else
      table.insert(vals, row)
    end
  end)
  if not callback then
    -- self:finalize()
    -- @conni does this make sense to have? or do we require
    -- it to be called explicitly?
    return vals
  end
end

local bind_type_to_func = {
  ['number'] = 'double', -- bind_double
  ['string'] = 'text',   -- bind_text
  ['nil'] = 'null',      -- bind_null
}

--- M:bind
-- binds values to indices. Type will be determined. For number is will bind
-- with double, for string it will bind with text and for nil it will bind_null
-- @param idx: index starting at 1
-- @param value: value to bind
-- @return sqlite code
function M:bind(idx, value)
  local func = bind_type_to_func[type(value)]
  local len = func == 'text' and #value or nil
  if not func then return flags.error end

  if len then
    return sqlite['bind_' .. func](self.pstmt, idx, value, len, nil)
  else
    if value then
      return sqlite['bind_' .. func](self.pstmt, idx, value)
    else
      return sqlite['bind_' .. func](self.pstmt, idx)
    end
  end
end

--- M:bind_blob
-- Will bind a blob at index with size
-- @param idx: index starting at 1
-- @param pointer: blob to bind
-- @param size: pointer size
-- @return sqlite code
function M:bind_blob(idx, pointer, size)
  return sqlite.bind_blob64(self.pstmt, idx, pointer, size, nil) -- Always 64? or two functions
end

--- M:bind_value
-- Will bind a value with type `sqlite.flags.`
-- @param idx: index starting at 1
-- @param pointer: value to bind
-- @param type: type of value `sqlite.flags.` { integer, float, text, blob, null }
-- @return sqlite code
function M:bind_value(idx, value, type)
  return sqlite.bind_value(self.pstmt, idx, value, type)
end

--- M:bind_pointer
-- Will bind a pointer with type at the index
-- @param idx: index starting at 1
-- @param pointer: pointer of type
-- @param type: type of value `sqlite.flags.` { integer, float, text, blob, null }
-- @return sqlite code
function M:bind_pointer(idx, pointer, type)
  return sqlite.bind_pointer(self.pstmt, idx, pointer, type)
end

--- M:bind_zeroblob
-- Will bind zeroblob at index with size
-- @param idx: index starting at 1
-- @param size: zeroblob size
-- @return sqlite code
function M:bind_zeroblob(idx, size)
  return sqlite.bind_zeroblob64(self.pstmt, idx, size) -- Should we always use 64 here?
end

--- M:nparam
-- Will return the parameter count
-- @return count
function M:nparam()
  if not self.parm_count then
    self.parm_count = sqlite.bind_parameter_count(self.pstmt)
  end

  return self.parm_count
end

--- M:param_name
-- Will return the parameter name at index
-- @param idx: index starting at 1. If nil return all param_names
-- @return string or table
function M:param_name(idx)
  if self.finalized then self:__parse() end

  if idx then
    return tostr(sqlite.bind_parameter_name(self.pstmt, idx))
  end

  local res = {}
  for i = 1, self:nparam() do
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

return M
