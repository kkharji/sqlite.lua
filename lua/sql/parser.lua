local u = require'sql.utils'
local M = {}

-- handle sqlite datatype interop
local sqlvalue = function(v)
  if type(v) == "boolean" then
    return v == true and 1 or 0
  else
    return v == nil and "null" or v
  end
end

local specifier = function(v)
  local type = type(v)
  if type == "number" then
    local _, b  = math.modf(v)
    return b == 0 and "%d" or "%f"
  else
    return type == "string" and "'%s'" or ""
  end
end

--- return key = value seprated via comma
local bind = function(o)
  o = o or {}
  o.s = o.s or ", "
  if not o.kv then
    o.v = o.v ~= nil and sqlvalue(o.v) or "?"
    return string.format("%s = " .. specifier(o.v), o.k, o.v)
  else
    local res = {}
    for k, v in pairs(o.kv) do
      k = o.k ~= nil and o.k or k
      v = sqlvalue(v)
      table.insert(res, string.format(
        "%s = " .. specifier(v), k, v
      ))
    end
    return table.concat(res, o.s)
  end
end

--- format values part of sql statement
---@params defs table: key/value paris defining sqlite table keys.
---@params defs kv: whether to bind by named keys.
M.keys = function(defs, kv)
  if not defs then return end
  kv = kv == nil and true or kv
  if kv then
    local keys = {}
    defs = u.is_nested(defs) and defs[1] or defs
    for k, _ in pairs(defs) do
      table.insert(keys, k)
    end
    return string.format("(%s)", table.concat(keys, ", "))
  end
end

--- format values part of sql statement, usually used with select method.
---@params defs table: key/value paris defining sqlite table keys.
---@params defs kv: whether to bind by named keys.
M.values = function(defs, kv)
  if not defs then return end
  kv = kv == nil and true or kv
  if kv then
    keys = {}
    defs = u.is_nested(defs) and defs[1] or defs
    for k, _ in pairs(defs) do
      table.insert(keys, ":" .. k)
    end
    return string.format("values(%s)", table.concat(keys, ", "))
  end
end

--- format set part of sql statement, usually used with update method.
---@params defs table: key/value paris defining sqlite table keys.
M.set = function(defs)
  if not defs then return end
  return "set " .. bind{ kv = defs }
end

--- format where part of a sql statement.
---@params defs table: key/value paris defining sqlite table keys.
---@params name string: the name of the sqlite table
---@params join table: used as boolean, controling whether to use name.key or just key.
M.where = function(defs, name, join)
  if not defs then return end
  local where = {}
  for k, v in pairs(defs) do
    k = join and name .. "." .. k or k
    if type(v) ~= "table" then
      table.insert(where, bind{
        v = v,
        k = k,
        s = " and "
      })
    else
      table.insert(where, "(" .. bind{
        kv = v,
        k = k,
        s = " or "
      } .. ")")
    end
  end
  return "where " .. table.concat(where, " and ")
end

--- select method specfic format
---@params defs table: key/value paris defining sqlite table keys.
---@params name string: the name of the sqlite table
M.select = function(defs, name)
  defs = u.is_tbl(defs) and table.concat(defs, ", ") or "*"
  return string.format("select %s from %s", defs, name)
end

--- format join part of a sql statement.
---@params defs table: key/value paris defining sqlite table keys.
---@params name string: the name of the sqlite table
M.join = function(defs, name)
  if not defs or not name then return {} end
  local target

  local on = (function()
    for k, v in pairs(defs) do
      if k ~= name then
        target = k
        return string.format("%s.%s =", k, v)
      end
    end
  end)()

  local select = (function()
    for k, v in pairs(defs) do
      if k == name then
        return string.format("%s.%s", k, v)
      end
    end
  end)()

  return string.format("inner join %s on %s %s", target, on, select)
end

--- Internal function for parsing
---@params tbl string: the sqlite table name
---@params method string: the sqlite action [insert, delete, update, drop, create]
---@params o table: {join, keys, values, set, where, select}
---@return string: sql statement
M.parse = function(tbl, method, o)
  o = o or {}
  method = method == "insert" and "insert into" or method
  method = method == "delete" and "delete from" or method
  if method == "select" then
    name, tbl = tbl, nil
    method = M.select(o.select, name)
  end

  return table.concat(u.flatten{
    method,
    tbl and tbl,
    M.join(o.join, name),
    M.keys(o.values, o.named),
    M.values(o.values, o.named),
    M.set(o.set),
    M.where(o.where, name, o.join),
  }, " ")
end

return M.parse
