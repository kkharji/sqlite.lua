local u = require'sql.utils'
local M = {}

---@brief [[
--- Internal functions for parsing sql statement from lua table.
--- methods = { select, update, delete, insert, create, alter, drop }
--- accepts tbl name and options.
--- options = {join, keys, values, set, where, select}
--- hopfully returning valid sql statement :D
---@brief ]]
---@tag parser.lua

-- handle sqlite datatype interop
M.sqlvalue = function(v)
  if type(v) == "boolean" then
    return v == true and 1 or 0
  else
    return v == nil and "null" or v
  end
end

M.specifier = function(v, nonbind)
  local type = type(v)
  if type == "number"then
    local _, b  = math.modf(v)
    return b == 0 and "%d" or "%f"
  elseif type == "string" and not nonbind then
    return v:find("'") and [["%s"]] or "'%s'"
  elseif nonbind then
    return v
  else
    return ""
  end
end

--- return key = value seprated via comma
local bind = function(o)
  o = o or {}
  o.s = o.s or ", "
  if not o.kv then
    o.v = o.v ~= nil and M.sqlvalue(o.v) or "?"
    return string.format("%s = " .. M.specifier(o.v), o.k, o.v)
  else
    local res = {}
    for k, v in u.opairs(o.kv) do
      k = o.k ~= nil and o.k or k
      v = M.sqlvalue(v)
      v = o.nonbind and ":" .. k or v
      table.insert(res, string.format(
        "%s" .. (o.nonbind and nil or " = ") .. M.specifier(v, o.nonbind), k, v
      ))
    end
    return table.concat(res, o.s)
  end
end

--- format glob pattern as part of where clause
M.contains = function(defs)
  if not defs then return {} end
  local items = {}
  for k,v in u.opairs(defs) do
    if type(v) == "table" then
      table.insert(items, table.concat(u.map(v, function(_v)
        return string.format("%s glob " .. M.specifier(k), k, M.sqlvalue(_v))
      end), " or "))
    else
      table.insert(items, string.format("%s glob " .. M.specifier(k), k, v))
    end
  end
  return table.concat(items, " ")
end

--- format values part of sql statement
---@params defs table: key/value pairs defining sqlite table keys.
---@params defs kv: whether to bind by named keys.
M.keys = function(defs, kv)
  if not defs then return {} end
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
---@params defs table: key/value pairs defining sqlite table keys.
---@params defs kv: whether to bind by named keys.
M.values = function(defs, kv)
  if not defs then return {} end
  kv = kv == nil and true or kv -- TODO: check if defs is key value pairs instead
  if kv then
    local keys = {}
    defs = u.is_nested(defs) and defs[1] or defs
    for k, _ in pairs(defs) do
      table.insert(keys, ":" .. k)
    end
    return string.format("values(%s)", table.concat(keys, ", "))
  end
end

--- format where part of a sql statement.
---@params defs table: key/value pairs defining sqlite table keys.
---@params name string: the name of the sqlite table
---@params join table: used as boolean, controling whether to use name.key or just key.
M.where = function(defs, name, join, contains)
  if not defs and not contains then return {} end
  local where = {}

  if defs then
    for k, v in u.opairs(defs) do
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
          s = " or ",
        } .. ")")
      end
    end
  end

  if contains then
    table.insert(where, M.contains(contains))
  end

  return "where " .. table.concat(where, " and ")
end

M.limit = function(defs)
  if not defs then return {} end
  local type = type(defs)
  local limit

  if type == "number" then
    limit = "limit " .. defs
  elseif type == "table" and defs[2] then
    limit = string.format("limit %s offset %s", defs[1], defs[2])
  else
    limit = "limit " .. defs[1]
  end

  return limit
end

--- format set part of sql statement, usually used with update method.
---@params defs table: key/value pairs defining sqlite table keys.
M.set = function(defs)
  if not defs then return {} end
  return "set " .. bind{ kv = defs, nonbind = true }
end

--- select method specfic format
---@params defs table: key/value pairs defining sqlite table keys.
---@params name string: the name of the sqlite table
---@params unique string: the name of the sqlite column to uniquify (not practical)
M.select = function(name, defs, unique)
  -- TODO: works for a single key
  local cmd = unique and "select distinct %s" or "select %s"
  defs = u.is_tbl(defs) and table.concat(defs, ", ") or "*"
  return string.format(cmd .. " from %s", defs, name)
end

--- format join part of a sql statement.
---@params defs table: key/value pairs defining sqlite table keys.
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

M.create = function(name, defs)
  if not defs then return {} end
  -- TODO: make the order of keys matach the keys as they order in the table
  -- maybe not important
  name = defs.ensure and "if not exists " .. name or name
  defs.ensure = nil

  local items = {}
  for k, v in u.opairs(defs) do
    if type(v) ~= "table" then
      table.insert(items, string.format("%s %s", k, v))
    else
      table.insert(items, string.format("%s %s", k, table.concat(v, " ")))
    end
  end

  return string.format("create table %s(%s)", name, table.concat(items, ", "))
end

M.order_by = function(defs) -- TODO: what if nulls? should append "nulls last"
  if not defs then return {} end
  local items = {}
  for v, k in u.opairs(defs) do
    if type(k) == "table" then
      for _, _k in u.opairs(k) do
        table.insert(items, string.format("%s %s", _k, v))
       end
    else
      table.insert(items, string.format("%s %s", k, v))
    end
  end

  return string.format("order by %s", table.concat(items, ", "))
end


return (function()
  local partial = function(method)
    return function(tbl, o)
      o = o or {}
      local switch = {
        ["insert"] = function() return string.format("insert into %s", tbl) end,
        ["delete"] = function() return string.format("delete from %s", tbl) end,
        ["update"] = function() return string.format("update %s", tbl) end,
        ["select"] = function() return M.select(tbl, o.select, o.unique) end,
        ["create"] = function() return M.create(tbl, o) end
      }

      return table.concat(u.flatten{
        switch[method](),
        M.join(o.join, tbl),
        M.keys(o.values),
        M.values(o.values, o.named),
        M.set(o.set),
        M.where(o.where, tbl, o.join, o.contains),
        M.order_by(o.order_by),
        M.limit(o.limit),
      }, " ")
    end
  end
  return {
    select = partial("select"), -- extracts data from a database
    update = partial("update"), -- updates data in a database
    delete = partial("delete"), -- deletes data from a database
    insert = partial("insert"), -- inserts new data into a database
    create = partial("create"), -- creates a new table
    alter  = partial("alter"),  -- modifies a table
    drop   = partial("drop"),   -- deletes a table
  }
end)()
