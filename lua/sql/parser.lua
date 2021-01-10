local u = require'sql.utils'
local M = {}

M.keys = function(values)
  if not values then return end
  local t = u.is_nested(values) and values[1] or values
  local keys = u.keynames(t)
  return string.format("(%s)", type(keys) == "string" and keys or table.concat(keys, ","))
end

M.values = function(plh, values)
  if not plh or not values then return end
  local t = u.is_nested(values) and values[1] or values
  local keys = u.keynames(t, true)
  local keynames = type(keys) == "string" and keys or table.concat(keys, ",")
  return string.format("values(%s)", keynames)
end

M.set = function(t)
  if not t then return end
  t = u.keys(t)
  local set = {}
  for _, v in pairs(t) do
    table.insert(set, v .. " = :" .. v)
  end
  return "set " .. table.concat(set, ",")
end

M.where = function(t, name, join)
  if not t then return end
  t = u.keys(t)
  local where = {}
  for _, v in pairs(t) do
    if join then
      table.insert(where, name .. "." .. v .. " = :" .. v)
    else
      table.insert(where, v .. " = :" .. v)
    end
  end
  return "where " .. table.concat(where, ", ")
end

M.select = function(t, name)
  t = u.is_tbl(t) and table.concat(t, ", ") or "*"
  return "select " .. t .. " from " .. name
end

M.join = function(join, tbl)
  if not join or not tbl then return {} end
  local target
  local on = (function()
    for k, v in pairs(join) do
      if k ~= tbl then
        target = k
        return string.format("%s.%s =", k, v)
      end
    end
  end)()
  local select = (function()
    for k, v in pairs(join) do
      if k == tbl then
        return string.format("%s.%s", k, v)
      end
    end
  end)()
  return string.format("inner join %s on %s %s", target, on, select)
end

--- Internal function for parsing
---@params tbl string: the sqlite table name
---@params method string: the sqlite action [insert, delete, update, drop, create]
---@params o table: defining options.
---@return string: sql statement
M.parse = function(tbl, method, o)
  o = o or {}
  method = method == "insert" and "insert into" or method
  method = method == "delete" and "delete from" or method
  if method == "select" then
    method = M.select(o.select, tbl)
    t = tbl
    tbl = nil
  end
  return table.concat(u.flatten{
    method,
    tbl and tbl,
    M.join(o.join, t),
    M.keys(o.values),
    M.values(o.placeholders, o.values),
    M.set(o.set),
    M.where(o.where, t, o.join),
  }, " ")
end

return M.parse
