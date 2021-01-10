local u = require'sql.utils'
local M = {}

local keynames = function(params, kv)
  local keys = u.keys(params)
  local s = kv and ":" or ""
  local res = {}
  u.map(keys, function(k)
    res[#res+1] = s .. k
  end)
  return res
end

local booleansql = function(value)
  if type(value) == "boolean" then
    value = (value == true) and 1 or 0
  end
  return value
end


--- format values part of sql statement
---@params defs table: key/value paris defining sqlite table keys.
---@params defs kv: whether to bind by named keys.
M.keys = function(defs, kv)
  if not defs then return end
  kv = kv == nil and true or kv
  if kv then
    defs = u.is_nested(defs) and defs[1] or defs
    local keys = keynames(defs)
    local named = type(keys) == "string" and keys or table.concat(keys, ",")
    return string.format("(%s)", named)
  end
end

--- format values part of sql statement, usually used with select method.
---@params defs table: key/value paris defining sqlite table keys.
---@params defs kv: whether to bind by named keys.
M.values = function(defs, kv)
  if not defs then return end
  kv = kv == nil and true or kv
  if kv then
    defs = u.is_nested(defs) and defs[1] or defs
    local keys = keynames(defs, true)
    local named = type(keys) == "string" and keys or table.concat(keys, ",")
    return string.format("values(%s)", named)
  end
end

--- format set part of sql statement, usually used with update method.
---@params defs table: key/value paris defining sqlite table keys.
M.set = function(defs)
  if not defs then return end
  local set = {}
  for k, _ in pairs(defs) do
    table.insert(set, string.format("%s = :%s", k, k))
  end
  return string.format("set %s", table.concat(set, ","))
end

--- format where part of a sql statement.
---@params defs table: key/value paris defining sqlite table keys.
---@params name string: the name of the sqlite table
---@params join table: used as boolean, controling whether to use name.key or just key.
M.where = function(defs, name, join)
  if not defs then return end
  local where = {}
  for k, v in pairs(defs) do
    local key = join and name .. "." .. k or k
    if type(v) ~= "table" then
      v = type(v) == "boolean" and booleansql(v) or v
      local sy = type(v) == "number" and "%d" or "'%s'"
      table.insert(where, string.format("%s = " .. sy, key, v))
    else
      local l = {}
      for _, value in ipairs(v) do
        local sy = type(value) == "number" and "%d" or "'%s'"
        table.insert(l, string.format("%s = " .. sy, key, value))
      end
      table.insert(where, "(" .. table.concat(l, " or ") .. ")")
    end
  end
  local res = where[1] and table.concat(where, " and ")
  return string.format("where %s", res)
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
