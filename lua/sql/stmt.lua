local sqlite = require "sql.defs"
local flags = sqlite.flags

local Stmt = {}
Stmt.__index = Stmt

---@brief [[
--- Stmt.lua is a collection of methods to deal with sqlite statements.
---@brief ]]
---@tag Stmt.lua

---Create new object for {conn} to deal with sqlite {Stmt}
---@class Stmt @object to deal with sqlite statements
---@param conn sqlite3: the database connection.
---@param str string: the sqlite statement to be parsed.
---@return Stmt: collection of methods, applicable to the parsed statement.
---@see Stmt:__parse
---@usage local Stmt = Stmt:parse(db, "insert into todos (title,desc) values(:title, :desc)")
function Stmt:parse(conn, str)
  assert(sqlite.type_of(conn) == sqlite.type_of_db_ptr, "Invalid connection passed to Stmt:parse")
  assert(type(str) == "string", "Invalid second argument passed to Stmt:parse")
  local o = {
    str = str,
    conn = conn,
    finalized = false,
  }
  setmetatable(o, self)
  o:__parse()
  return o
end

---Parse self.str into an sqlite representation and set it to self.pstmt.
function Stmt:__parse()
  local pstmt = sqlite.get_new_stmt_ptr()
  local code = sqlite.prepare_v2(self.conn, self.str, #self.str, pstmt, nil)
  assert(
    code == flags.ok,
    string.format(
      "sql.nvim: sql statement parse, , stmt: `%s`, err: `(`%s`)`",
      self.str,
      sqlite.to_str(sqlite.errmsg(self.conn))
    )
  )
  self.pstmt = pstmt[0]
end

---Resets the parsed statement. required for parsed statements to be re-executed.
---NOTE: Any statement variables that had values bound to them using the
---Stmt:bind functions retain their values.
---@return number: falgs.ok or errcode
---@TODO should we error out when errcode?
function Stmt:reset()
  return sqlite.reset(self.pstmt)
end

---Frees the prepared statement
---@return boolean: if no error true.
function Stmt:finalize()
  self.errcode = sqlite.finalize(self.pstmt)
  self.finalized = self.errcode == flags.ok
  assert(
    self.finalized,
    string.format("sql.nvim: couldn't finalize statement, ERRMSG: %s", sqlite.to_str(sqlite.errmsg(self.conn)))
  )
  return self.finalized
end

---Called before evaluating the (next iteration) of the prepared statement.
---@return sqlite_flag: Possible Flags: { flags.busy, flags.done, flags.row, flags.error, flags.misuse }
function Stmt:step()
  local step_code = sqlite.step(self.pstmt)
  assert(
    step_code ~= flags.error or step_code ~= flags.misuse,
    string.format(
      "sql.nvim: error in step(), ERRMSG: %s. Please report issue.",
      sqlite.to_str(sqlite.errmsg(self.conn))
    )
  )
  return step_code
end

---Number of keys/columns in results
---@return number: column count in the results.
function Stmt:nkeys()
  return sqlite.column_count(self.pstmt)
end

---Number of rows/items in results.
---@return number: rows count in the results.
function Stmt:nrows()
  local count = 0
  self:each(function()
    count = count + 1
  end)
  return count
end

---key-name/column-name at {idx} in results.
---@param idx number: (0-index)
---@return string: keyname/column name at {idx}
---@TODO should accept 1-index
function Stmt:key(idx)
  return sqlite.to_str(sqlite.column_name(self.pstmt, idx))
end

---key-names/column-names in results.
---@return table: key-names/column-names.
---@see Stmt:nkeys
---@see Stmt:key
function Stmt:keys()
  local keys = {}
  for i = 0, self:nkeys() - 1 do
    table.insert(keys, i + 1, self:key(i))
  end
  return keys
end

local sqlite_datatypes = {
  [1] = "int", -- bind_double
  [2] = "double", -- bind_text
  [3] = "text", -- bind_null
  [4] = "blob", -- bind_null
  [5] = "null", -- bind_null
}

---Key/Column lua datatype at {idx}
---@param idx number: (0-index)
---@return string: key/column type at {idx}
---@TODO should accept 1-index
function Stmt:convert_type(idx)
  local convert_dt = {
    ["integer"] = "number",
    ["float"] = "number",
    ["double"] = "number",
    ["text"] = "string",
    ["blob"] = "binary",
    ["null"] = nil,
  }
  return convert_dt[sqlite.to_str(sqlite.column_decltype(self.pstmt, idx))]
end

---Keys/Columns types visible in current result.
---@return table: list of types, ordered by key location.
---@see Stmt:type
---@see Stmt:nkeys
function Stmt:types()
  local types = {}
  for i = 0, self:nkeys() - 1 do
    table.insert(types, i + 1, self:convert_type(i))
  end
  return types
end

---Value at {idx}
---@param idx number: (0-index)
---@return string: value at {idx}
---@TODO should accept 1-index
function Stmt:val(idx)
  local ktype = sqlite.column_type(self.pstmt, idx)
  if ktype == 5 then
    return
  end
  local val = sqlite["column_" .. sqlite_datatypes[ktype]](self.pstmt, idx)
  return ktype == 3 and sqlite.to_str(val) or val
end

---Ordered list of current result values.
---@return table: list of values, ordered by key location.
---@see Stmt:val
---@see Stmt:nkeys
function Stmt:vals()
  local vals = {}
  for i = 0, self:nkeys() - 1 do
    table.insert(vals, i + 1, self:val(i))
  end
  return vals
end

---Key/value pair in current result.
---@return table: key/value pair of a row.
---@see Stmt:key
---@see Stmt:val
---@see Stmt:nkeys
function Stmt:kv()
  local ret = {}
  for i = 0, self:nkeys() - 1 do
    ret[self:key(i)] = self:val(i)
  end
  return ret
end

---Key/type pair in current result.
---@return table: key/type pair of a row.
---@see Stmt:key
---@see Stmt:val
---@see Stmt:nkeys
function Stmt:kt()
  local ret = {}
  for i = 0, self:nkeys() - 1 do
    ret[self:key(i)] = self:convert_type(i)
  end
  return ret
end

---Stmt:next:
---If code == flags.row it returns
---If code == flags.done it reset the parsed statement
function Stmt:next()
  local code = self:step()
  if code == flags.row then
    return self
  elseif code == flags.done then
    self:reset()
  else
    return nil, code
  end
end

---Stmt:iter
---@see Stmt:next
function Stmt:iter()
  return self:next(), self.pstmt
end

---Loops through results with {callback} until there is no row left.
---@param callback function: a function to be called on each number of row.
---@usage Stmt:each(function(s)  print(s:val(1))  end)
---@see Stmt:step
function Stmt:each(callback)
  assert(type(callback) == "function", "Stmt:each expected a function, got something else.")
  while self:step() == flags.row do
    callback(self)
  end
end

---Loops through the results and if {callback} pass to it row, else return nested kv pairs.
---@param callback function: a function to be called with each row.
---@return table: if no callback then nested key-value pairs
---@see Stmt:kv
---@see Stmt:each
function Stmt:kvrows(callback)
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
    return kv
  end
end

---Like Stmt:kvrows but passed list of values instead of kv pairs.
---@param callback function: a function to be called with each row.
---@return table: if no callback then nested lists of values in each row.
---@see Stmt:vals
---@see Stmt:each
function Stmt:vrows(callback)
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
    return vals
  end
end

local bind_type_to_func = {
  ["number"] = "double", -- bind_double
  ["string"] = "text", -- bind_text
  ["nil"] = "null", -- bind_null
}

---Bind {args[2]} at {args[1]} or kv pairs {args[1]}.
---If {args[1]} is a number and {args[2]} is a value then it binds by index.
---Else first argument is a table, then it binds the table to indicies, and it
---works with named and unnamed.
---@param ...: Either a index value pair or a table
---@varargs if {args[1]} number and {args[2]} or {args[1]} table
---@see Stmt:nparam
---@see Stmt:param
---@see Stmt:bind
function Stmt:bind(...)
  local args = { ... }
  -- bind by table
  if type(args[1]) == "table" then
    local names = args[1]
    local parameter_index_cache = {}
    local anon_indices = {}
    for i = 1, self:nparam() do
      local name = self:param(i)
      if name == "?" then
        table.insert(anon_indices, i)
      else
        parameter_index_cache[name:sub(2, -1)] = i
      end
    end

    for k, v in pairs(names) do
      local index = parameter_index_cache[k] or table.remove(anon_indices, 1)
      if type(v) == "string" and v:match "%a+%(.+%)" then
      else
        local ret = self:bind(index, v)
        if ret ~= flags.ok then
          error([[
            sql.nvim error at stmt:bind(), failed to bind a given value '%s'.
            Please report issue.
          ]]):format(v)
          return ret
        end
      end
    end
    return flags.ok
  end

  -- bind by index
  if type(args[1]) == "number" and args[2] then
    local idx, value = args[1], args[2]
    local func = bind_type_to_func[type(value)]
    local len = func == "text" and #value or nil

    if not func then
      return error [[
        sql.nvim error at stmt:bind(): Unrecognized or unsupported type.
        Please report issue.
      ]]
    end

    if len then
      return sqlite["bind_" .. func](self.pstmt, idx, value, len, nil)
    else
      if value then
        return sqlite["bind_" .. func](self.pstmt, idx, value)
      else
        return sqlite["bind_" .. func](self.pstmt, idx)
      end
    end
  end
end

---Binds a blob at {idx} with {size}
---@param idx number: index starting at 1
---@param pointer sqlite3_blob: blob to bind
---@param size number: pointer size
---@return sqlite_flag
function Stmt:bind_blob(idx, pointer, size)
  return sqlite.bind_blob64(self.pstmt, idx, pointer, size, nil) -- Always 64? or two functions
end

---Binds zeroblob at {idx} with {size}
---@param idx number: index starting at 1
---@param size number: zeroblob size
---@return sqlite_flag
function Stmt:bind_zeroblob(idx, size)
  return sqlite.bind_zeroblob64(self.pstmt, idx, size)
end

---The number of parameter to bind.
---@return number: number of params in {Stmt.pstmt}
function Stmt:nparam()
  if not self.parm_count then
    self.parm_count = sqlite.bind_parameter_count(self.pstmt)
  end

  return self.parm_count
end

---The parameter key/name at {idx}
---@param idx number: index starting at 1
---@return string: param key ":key" at {idx}
function Stmt:param(idx)
  return sqlite.to_str(sqlite.bind_parameter_name(self.pstmt, idx)) or "?"
end

---Parameters keys/names
---@return table: paramters key/names in {Stmt.pstmt}
---@see Stmt:nparam
---@see Stmt:param
function Stmt:params()
  local res = {}
  for i = 1, self:nparam() do
    table.insert(res, self:param(i))
  end
  return res
end

---Clear the current bindings.
---@return sqlite_flag
function Stmt:bind_clear()
  self.current_bind_index = nil
  return sqlite.clear_bindings(self.pstmt)
end

---Bind the value at the next index until all values are bound
---@param value any: value to bind
---@return sqlite_flag
---@TODO does it return sqlite_flag in all cases? @conni
function Stmt:bind_next(value)
  if not self.current_bind_index then
    self.current_bind_index = 1
  end

  if self.current_bind_index <= self:nparam() then
    local ret = self:bind(self.current_bind_index, value)
    self.current_bind_index = self.current_bind_index + 1
    return ret
  end
  return flags.error -- TODO(conni): should error out?
end

---Expand the resulting statement after binding, used for debugging purpose.
---@return string: the resulting statement that can be finalized.
function Stmt:expand()
  return sqlite.to_str(sqlite.expanded_sql(self.pstmt))
end

return Stmt
